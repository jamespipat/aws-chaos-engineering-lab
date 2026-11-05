import { GetObjectCommand, ListObjectsV2Command, S3Client } from "@aws-sdk/client-s3";
import { log } from "./log.ts";
import { required } from "./config.ts";
import type { Queryable } from "./db.ts";

type JournalRecord = {
  idempotency_key?: string;
  request_id?: string;
  status?: number;
  phase?: string;
};

export async function verify(pool: Queryable): Promise<void> {
  const bucket = required("EVIDENCE_BUCKET");
  const prefix = required("EVIDENCE_PREFIX");
  const region = required("AWS_REGION");
  const s3 = new S3Client({ region });
  const listed = await s3.send(new ListObjectsV2Command({ Bucket: bucket, Prefix: prefix }));
  const acknowledged = new Map<string, string>();
  for (const object of listed.Contents || []) {
    if (!object.Key) {
      continue;
    }
    const body = await s3.send(new GetObjectCommand({ Bucket: bucket, Key: object.Key }));
    const text = await body.Body?.transformToString();
    if (!text) {
      continue;
    }
    for (const line of text.split("\n")) {
      if (!line.trim()) {
        continue;
      }
      const record = JSON.parse(line) as JournalRecord;
      if (record.status === 202 && record.request_id && record.idempotency_key) {
        acknowledged.set(record.request_id, record.idempotency_key);
      }
    }
  }
  const rows = await pool.query<{ id: string; effects: number }>(
    `SELECT r.id, count(p.request_id)::int AS effects
     FROM loan_requests r
     LEFT JOIN processed_effects p ON p.request_id = r.id
     WHERE r.id = ANY($1::uuid[])
     GROUP BY r.id`,
    [Array.from(acknowledged.keys())],
  );
  const found = new Map(rows.rows.map((row) => [row.id, row.effects]));
  const missing: string[] = [];
  const duplicates: string[] = [];
  for (const id of acknowledged.keys()) {
    const effects = found.get(id);
    if (effects === undefined) {
      missing.push(id);
    } else if (effects !== 1) {
      duplicates.push(id);
    }
  }
  log("info", "verification finished", {
    acknowledged: acknowledged.size,
    missing: missing.length,
    duplicates: duplicates.length,
  });
  if (missing.length > 0 || duplicates.length > 0) {
    throw new Error(`verification failed missing=${missing.length} duplicates=${duplicates.length}`);
  }
}
