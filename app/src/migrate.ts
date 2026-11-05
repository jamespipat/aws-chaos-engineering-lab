import { GetSecretValueCommand, SecretsManagerClient } from "@aws-sdk/client-secrets-manager";
import pg from "pg";
import { readCa, required } from "./config.ts";
import { log } from "./log.ts";

const schema = `
CREATE TABLE IF NOT EXISTS loan_requests (
  id uuid PRIMARY KEY,
  idempotency_key text NOT NULL UNIQUE,
  payload_hash text NOT NULL,
  amount_cents integer NOT NULL CHECK (amount_cents > 0),
  term_months integer NOT NULL CHECK (term_months > 0),
  status text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS outbox (
  id uuid PRIMARY KEY,
  request_id uuid NOT NULL UNIQUE REFERENCES loan_requests (id),
  published_at timestamptz,
  lease_until timestamptz
);
CREATE TABLE IF NOT EXISTS processed_effects (
  request_id uuid PRIMARY KEY REFERENCES loan_requests (id),
  processed_at timestamptz NOT NULL DEFAULT now()
);
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
`;

const users = ["api", "worker", "verifier"] as const;

export async function migrate(): Promise<void> {
  const secretArn = required("DATABASE_MASTER_SECRET_ARN");
  const region = required("AWS_REGION");
  const client = new SecretsManagerClient({ region });
  const response = await client.send(new GetSecretValueCommand({ SecretId: secretArn }));
  if (!response.SecretString) {
    throw new Error("master secret has no string value");
  }
  const secret = JSON.parse(response.SecretString) as {
    username: string;
    password: string;
    host?: string;
    port?: number;
    dbname?: string;
  };
  const host = secret.host || required("DATABASE_HOST");
  const port = secret.port || Number(required("DATABASE_PORT"));
  const database = secret.dbname || required("DATABASE_NAME");
  const connection = new pg.Client({
    host,
    port,
    database,
    user: secret.username,
    password: secret.password,
    connectionTimeoutMillis: 5000,
    statement_timeout: 10000,
    ssl: {
      ca: readCa(process.env.RDS_CA_PATH || "certs/global-bundle.pem"),
      rejectUnauthorized: true,
      servername: host,
    },
  });
  await connection.connect();
  try {
    await connection.query(schema);
    for (const user of users) {
      await connection.query(
        `DO $$ BEGIN
           IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${user}') THEN
             CREATE ROLE ${user} LOGIN;
           END IF;
         END $$;`,
      );
      await connection.query(`GRANT rds_iam TO ${user}`);
      await connection.query(`GRANT CONNECT ON DATABASE ${quoteIdent(database)} TO ${user}`);
      await connection.query(`GRANT USAGE ON SCHEMA public TO ${user}`);
    }
    await connection.query(`GRANT SELECT, INSERT ON loan_requests, outbox TO api`);
    await connection.query(`GRANT SELECT, UPDATE ON loan_requests, outbox TO worker`);
    await connection.query(`GRANT INSERT, SELECT ON processed_effects TO worker`);
    await connection.query(`GRANT SELECT ON loan_requests, outbox, processed_effects TO verifier`);
    log("info", "migration finished", { users: users.join(",") });
  } finally {
    await connection.end();
  }
}

function quoteIdent(value: string): string {
  if (!/^[a-z_][a-z0-9_]*$/.test(value)) {
    throw new Error("database name is not a simple identifier");
  }
  return value;
}
