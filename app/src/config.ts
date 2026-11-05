import { readFileSync } from "node:fs";

export type CommandName = "api" | "worker" | "migrate" | "verify" | "collector";

export function required(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`missing environment variable ${name}`);
  }
  return value;
}

export function optional(name: string, fallback: string): string {
  return process.env[name] || fallback;
}

export function databaseConfig() {
  return {
    host: required("DATABASE_HOST"),
    port: Number(required("DATABASE_PORT")),
    database: required("DATABASE_NAME"),
    user: required("DATABASE_USER"),
    region: required("AWS_REGION"),
    caPath: optional("RDS_CA_PATH", "certs/global-bundle.pem"),
  };
}

export function readCa(path: string): string {
  return readFileSync(path, "utf8");
}

export function commandName(argv: string[]): CommandName {
  const name = argv[2] || process.env.APP_COMMAND;
  if (name === "api" || name === "worker" || name === "migrate" || name === "verify" || name === "collector") {
    return name;
  }
  throw new Error("command must be api, worker, migrate, verify, or collector");
}
