import http from "k6/http";
import { check, sleep } from "k6";
import exec from "k6/execution";

const rate = Number(__ENV.RATE || 5);
const duration = __ENV.DURATION || "15m";
const baseUrl = __ENV.BASE_URL;
const journalUrl = __ENV.JOURNAL_URL;
const runId = __ENV.RUN_ID || "local";

export const options = {
  scenarios: {
    loan_requests: {
      executor: "constant-arrival-rate",
      rate: rate,
      timeUnit: "1s",
      duration: duration,
      preAllocatedVUs: 10,
      maxVUs: 40,
    },
  },
};

export default function () {
  const idempotencyKey = `${runId}-${exec.vu.idInTest}-${exec.scenario.iterationInInstance}`;
  const payload = JSON.stringify({
    idempotency_key: idempotencyKey,
    amount_cents: 10000,
    term_months: 12,
  });
  const params = {
    headers: { "Content-Type": "application/json" },
    timeout: "2s",
  };
  const started = Date.now();
  let response = http.post(`${baseUrl}/v1/loan-requests`, payload, params);
  let retries = 0;
  const retryable = response.status === 0 || response.status === 429 || response.status >= 502;
  if (retryable) {
    retries = 1;
    sleep((50 + Math.floor(Math.random() * 100)) / 1000);
    response = http.post(`${baseUrl}/v1/loan-requests`, payload, params);
  }
  const latencyMs = Date.now() - started;
  check(response, { "accepted or replayed": (result) => result.status === 202 });
  let requestId = "";
  try {
    requestId = response.json("id") || "";
  } catch (_error) {
    requestId = "";
  }
  http.post(
    journalUrl,
    JSON.stringify({
      run_id: runId,
      idempotency_key: idempotencyKey,
      request_id: requestId,
      status: response.status,
      latency_ms: latencyMs,
      retry_count: retries,
      phase: "business",
      started_at: new Date(started).toISOString(),
    }),
    { headers: { "Content-Type": "application/json" }, timeout: "2s" },
  );
}
