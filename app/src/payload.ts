import { createHash } from "node:crypto";

export type LoanInput = {
  idempotencyKey: string;
  amountCents: number;
  termMonths: number;
};

export function payloadHash(input: Pick<LoanInput, "amountCents" | "termMonths">): string {
  const canonical = JSON.stringify({
    amountCents: input.amountCents,
    termMonths: input.termMonths,
  });
  return createHash("sha256").update(canonical).digest("hex");
}

export function parseLoanInput(body: unknown): LoanInput | { error: string } {
  if (body === null || typeof body !== "object") {
    return { error: "body must be an object" };
  }
  const record = body as Record<string, unknown>;
  const idempotencyKey = record.idempotency_key;
  const amountCents = record.amount_cents;
  const termMonths = record.term_months;
  if (typeof idempotencyKey !== "string" || idempotencyKey.length < 1 || idempotencyKey.length > 128) {
    return { error: "idempotency_key must be 1 to 128 characters" };
  }
  if (!Number.isInteger(amountCents) || typeof amountCents !== "number" || amountCents < 1 || amountCents > 100_000_000) {
    return { error: "amount_cents must be an integer from 1 to 100000000" };
  }
  if (!Number.isInteger(termMonths) || typeof termMonths !== "number" || termMonths < 1 || termMonths > 480) {
    return { error: "term_months must be an integer from 1 to 480" };
  }
  return { idempotencyKey, amountCents, termMonths };
}

export type ExistingRequest = {
  id: string;
  payloadHash: string;
};

export type IdempotencyDecision =
  | { kind: "insert" }
  | { kind: "replay"; id: string }
  | { kind: "conflict" };

export function decideIdempotency(existing: ExistingRequest | undefined, hash: string): IdempotencyDecision {
  if (!existing) {
    return { kind: "insert" };
  }
  if (existing.payloadHash === hash) {
    return { kind: "replay", id: existing.id };
  }
  return { kind: "conflict" };
}
