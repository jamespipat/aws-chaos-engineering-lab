import { Signer } from "@aws-sdk/rds-signer";
import pg from "pg";
import { databaseConfig, readCa } from "./config.ts";

const { Pool } = pg;

export type Queryable = {
  query: <T extends pg.QueryResultRow = pg.QueryResultRow>(
    text: string,
    values?: unknown[],
  ) => Promise<pg.QueryResult<T>>;
};

export function createIamPool(): pg.Pool {
  const config = databaseConfig();
  const signer = new Signer({
    hostname: config.host,
    port: config.port,
    username: config.user,
    region: config.region,
  });
  const ca = readCa(config.caPath);
  return new Pool({
    host: config.host,
    port: config.port,
    database: config.database,
    user: config.user,
    max: 5,
    connectionTimeoutMillis: 2000,
    statement_timeout: 1000,
    application_name: process.env.APP_COMMAND || "aws-chaos-lab",
    password: () => signer.getAuthToken(),
    ssl: {
      ca,
      rejectUnauthorized: true,
      servername: config.host,
    },
  });
}

export async function withTransaction<T>(pool: Queryable, work: (client: Queryable) => Promise<T>): Promise<T> {
  const client = await (pool as pg.Pool).connect();
  try {
    await client.query("BEGIN");
    const result = await work(client);
    await client.query("COMMIT");
    return result;
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}
