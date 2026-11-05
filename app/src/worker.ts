import { DeleteMessageCommand, ReceiveMessageCommand, SendMessageCommand, SQSClient } from "@aws-sdk/client-sqs";
import { log } from "./log.ts";
import { required } from "./config.ts";
import type { Queryable } from "./db.ts";

type Claimed = { id: string; request_id: string };

export async function runWorker(pool: Queryable, health: () => void): Promise<void> {
  const queueUrl = required("SQS_QUEUE_URL");
  const sqs = new SQSClient({ region: required("AWS_REGION") });
  let stopped = false;
  process.once("SIGTERM", () => {
    stopped = true;
  });
  health();
  while (!stopped) {
    await relayOne(pool, sqs, queueUrl);
    await consumeOne(pool, sqs, queueUrl);
  }
  log("info", "worker stopped", {});
}

async function relayOne(pool: Queryable, sqs: SQSClient, queueUrl: string): Promise<void> {
  const client = await (pool as import("pg").Pool).connect();
  let claimed: Claimed | undefined;
  try {
    await client.query("BEGIN");
    const result = await client.query<Claimed>(
      `UPDATE outbox
       SET lease_until = now() + interval '30 seconds'
       WHERE id = (
         SELECT id FROM outbox
         WHERE published_at IS NULL AND (lease_until IS NULL OR lease_until < now())
         ORDER BY id
         FOR UPDATE SKIP LOCKED
         LIMIT 1
       )
       RETURNING id, request_id`,
    );
    claimed = result.rows[0];
    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
  if (!claimed) {
    return;
  }
  await sqs.send(new SendMessageCommand({
    QueueUrl: queueUrl,
    MessageBody: JSON.stringify({ request_id: claimed.request_id }),
  }));
  await pool.query(`UPDATE outbox SET published_at = now(), lease_until = NULL WHERE id = $1`, [claimed.id]);
  log("info", "outbox published", { requestId: claimed.request_id });
}

async function consumeOne(pool: Queryable, sqs: SQSClient, queueUrl: string): Promise<void> {
  const received = await sqs.send(new ReceiveMessageCommand({
    QueueUrl: queueUrl,
    MaxNumberOfMessages: 1,
    WaitTimeSeconds: 5,
    VisibilityTimeout: 30,
  }));
  const message = received.Messages?.[0];
  if (!message?.Body || !message.ReceiptHandle) {
    return;
  }
  const body = JSON.parse(message.Body) as { request_id?: string };
  if (!body.request_id) {
    log("error", "queue message missing request id", {});
    return;
  }
  await pool.query(
    `INSERT INTO processed_effects (request_id) VALUES ($1) ON CONFLICT (request_id) DO NOTHING`,
    [body.request_id],
  );
  await pool.query(`UPDATE loan_requests SET status = 'processed' WHERE id = $1`, [body.request_id]);
  await sqs.send(new DeleteMessageCommand({ QueueUrl: queueUrl, ReceiptHandle: message.ReceiptHandle }));
  log("info", "request processed", { requestId: body.request_id });
}
