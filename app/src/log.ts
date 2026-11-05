export type LogFields = Record<string, string | number | boolean | null>;

export function log(level: string, message: string, fields: LogFields = {}): void {
  const entry = {
    time: new Date().toISOString(),
    level,
    message,
    ...fields,
  };
  process.stdout.write(`${JSON.stringify(entry)}\n`);
}
