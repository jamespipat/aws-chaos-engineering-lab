import { randomUUID } from "node:crypto";
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { log } from "./log.ts";
import { decideIdempotency, parseLoanInput, payloadHash } from "./payload.ts";
import { withTransaction, type Queryable } from "./db.ts";

type StoredRequest = {
  id: string;
  payload_hash: string;
  status: string;
  amount_cents: number;
  term_months: number;
};

let shuttingDown = false;

export function markShuttingDown(): void {
  shuttingDown = true;
}

async function readBody(req: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  let size = 0;
  for await (const chunk of req) {
    const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
    size += buffer.length;
    if (size > 16_384) {
      throw new Error("body too large");
    }
    chunks.push(buffer);
  }
  if (chunks.length === 0) {
    return {};
  }
  return JSON.parse(Buffer.concat(chunks).toString("utf8")) as unknown;
}

function send(res: ServerResponse, status: number, body: unknown, requestId: string): void {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    "content-type": "application/json",
    "x-request-id": requestId,
  });
  res.end(payload);
}

export function createApiServer(pool: Queryable) {
  return createServer(async (req, res) => {
    const requestId = header(req, "x-request-id") || randomUUID();
    const started = Date.now();
    try {
      if (req.method === "GET" && req.url === "/healthz") {
        send(res, 200, { status: "ok" }, requestId);
        return;
      }
      if (req.method === "GET" && req.url === "/readyz") {
        send(res, shuttingDown ? 503 : 200, { status: shuttingDown ? "draining" : "ready" }, requestId);
        return;
      }
      if (req.method === "POST" && req.url === "/v1/loan-requests") {
        await postLoanRequest(pool, req, res, requestId);
        return;
      }
      if (req.method === "GET" && req.url?.startsWith("/v1/loan-requests/")) {
        await getLoanRequest(pool, req, res, requestId);
        return;
      }
      send(res, 404, { error: "not_found" }, requestId);
    } catch (error) {
      const code = error instanceof Error ? error.name : "error";
      log("error", "request failed", { requestId, code, path: req.url || "" });
      if (!res.headersSent) {
        send(res, 500, { error: "internal_error", request_id: requestId }, requestId);
      }
    } finally {
      log("info", "request", {
        requestId,
        method: req.method || "",
        path: req.url || "",
        status: res.statusCode,
        durationMs: Date.now() - started,
      });
    }
  });
}

async function postLoanRequest(pool: Queryable, req: IncomingMessage, res: ServerResponse, requestId: string) {
  let body: unknown;
  try {
    body = await readBody(req);
  } catch {
    send(res, 400, { error: "invalid_json" }, requestId);
    return;
  }
  const parsed = parseLoanInput(body);
  if ("error" in parsed) {
    send(res, 400, { error: parsed.error }, requestId);
    return;
  }
  const hash = payloadHash(parsed);
  const result = await withTransaction(pool, async (client) => {
    const inserted = await client.query<StoredRequest>(
      `INSERT INTO loan_requests (id, idempotency_key, payload_hash, amount_cents, term_months, status)
       VALUES ($1, $2, $3, $4, $5, 'accepted')
       ON CONFLICT (idempotency_key) DO NOTHING
       RETURNING id, payload_hash, status, amount_cents, term_months`,
      [randomUUID(), parsed.idempotencyKey, hash, parsed.amountCents, parsed.termMonths],
    );
    if (inserted.rowCount === 1) {
      const row = inserted.rows[0];
      await client.query(
        `INSERT INTO outbox (id, request_id) VALUES ($1, $2)`,
        [randomUUID(), row.id],
      );
      return { kind: "created" as const, row };
    }
    const existing = await client.query<StoredRequest>(
      `SELECT id, payload_hash, status, amount_cents, term_months
       FROM loan_requests WHERE idempotency_key = $1`,
      [parsed.idempotencyKey],
    );
    const row = existing.rows[0];
    const decision = decideIdempotency(
      row ? { id: row.id, payloadHash: row.payload_hash } : undefined,
      hash,
    );
    if (decision.kind === "conflict" || !row) {
      return { kind: "conflict" as const };
    }
    return { kind: "replay" as const, row };
  });
  if (result.kind === "conflict") {
    send(res, 409, { error: "idempotency_conflict", request_id: requestId }, requestId);
    return;
  }
  log("info", "loan request accepted", {
    requestId,
    loanRequestId: result.row.id,
    idempotencyKey: parsed.idempotencyKey,
    replay: result.kind === "replay",
  });
  send(res, 202, { id: result.row.id, status: result.row.status }, requestId);
}

async function getLoanRequest(pool: Queryable, req: IncomingMessage, res: ServerResponse, requestId: string) {
  const id = decodeURIComponent((req.url || "").replace("/v1/loan-requests/", ""));
  const found = await pool.query<StoredRequest>(
    `SELECT id, payload_hash, status, amount_cents, term_months FROM loan_requests WHERE id = $1`,
    [id],
  );
  const row = found.rows[0];
  if (!row) {
    send(res, 404, { error: "not_found", request_id: requestId }, requestId);
    return;
  }
  send(res, 200, {
    id: row.id,
    status: row.status,
    amount_cents: row.amount_cents,
    term_months: row.term_months,
  }, requestId);
}

function header(req: IncomingMessage, name: string): string | undefined {
  const value = req.headers[name];
  if (Array.isArray(value)) {
    return value[0];
  }
  return value;
}
