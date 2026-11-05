import assert from "node:assert/strict";
import test from "node:test";
import { decideIdempotency, parseLoanInput, payloadHash } from "./payload.ts";

test("payload hash changes when the business fields change", () => {
  const first = payloadHash({ amountCents: 100, termMonths: 12 });
  const second = payloadHash({ amountCents: 101, termMonths: 12 });
  assert.notEqual(first, second);
  assert.equal(first, payloadHash({ amountCents: 100, termMonths: 12 }));
});

test("parseLoanInput accepts a synthetic request and rejects a bad amount", () => {
  const parsed = parseLoanInput({
    idempotency_key: "abc",
    amount_cents: 2500,
    term_months: 6,
  });
  assert.deepEqual(parsed, { idempotencyKey: "abc", amountCents: 2500, termMonths: 6 });
  const rejected = parseLoanInput({
    idempotency_key: "abc",
    amount_cents: 0,
    term_months: 6,
  });
  assert.equal("error" in rejected, true);
});

test("idempotency decision separates insert, replay, and conflict", () => {
  assert.deepEqual(decideIdempotency(undefined, "h1"), { kind: "insert" });
  assert.deepEqual(decideIdempotency({ id: "1", payloadHash: "h1" }, "h1"), { kind: "replay", id: "1" });
  assert.deepEqual(decideIdempotency({ id: "1", payloadHash: "h1" }, "h2"), { kind: "conflict" });
});
