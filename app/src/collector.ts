import { CloudWatchClient, PutMetricDataCommand } from "@aws-sdk/client-cloudwatch";
import { PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { log } from "./log.ts";
import { required } from "./config.ts";

type Sample = {
  idempotency_key: string;
  request_id: string | null;
  status: number;
  latency_ms: number;
  retry_count: number;
  phase: string;
  started_at: string;
};

export function createCollector() {
  const bucket = required("EVIDENCE_BUCKET");
  const region = required("AWS_REGION");
  const runId = required("RUN_ID");
  const s3 = new S3Client({ region });
  const cloudwatch = new CloudWatchClient({ region });
  let buffer: Sample[] = [];
  let sequence = 0;
  let stopped = false;

  async function flush(): Promise<void> {
    const samples = buffer;
    buffer = [];
    const minute = new Date().toISOString().slice(0, 16).replace(/[:]/g, "");
    sequence += 1;
    try {
      if (samples.length > 0) {
        const body = samples.map((sample) => JSON.stringify(sample)).join("\n") + "\n";
        await s3.send(new PutObjectCommand({
          Bucket: bucket,
          Key: `journal/${runId}/${minute}-${sequence}.jsonl`,
          Body: body,
          ContentType: "application/x-ndjson",
        }));
      }
    } catch (error) {
      buffer = samples.concat(buffer);
      throw error;
    }
    const successes = samples.filter((sample) => sample.status === 202).length;
    const firstSuccesses = samples.filter((sample) => sample.status === 202 && sample.retry_count === 0).length;
    const latencies = samples.map((sample) => sample.latency_ms).sort((a, b) => a - b);
    const p95 = latencies.length === 0 ? 0 : latencies[Math.max(0, Math.ceil(latencies.length * 0.95) - 1)];
    const errorRate = samples.length === 0 ? 0 : ((samples.length - successes) / samples.length) * 100;
    await cloudwatch.send(new PutMetricDataCommand({
      Namespace: "ChaosLab",
      MetricData: [
        { MetricName: "LogicalRequests", Value: samples.length, Unit: "Count" },
        { MetricName: "LogicalSuccesses", Value: successes, Unit: "Count" },
        { MetricName: "FirstAttemptSuccesses", Value: firstSuccesses, Unit: "Count" },
        { MetricName: "LogicalErrorRate", Value: errorRate, Unit: "Percent" },
        { MetricName: "LogicalP95Milliseconds", Value: p95, Unit: "Milliseconds" },
        { MetricName: "Heartbeat", Value: stopped ? 0 : 1, Unit: "Count" },
      ],
    }));
    log("info", "journal flushed", { samples: samples.length, p95, errorRate });
  }

  const timer = setInterval(() => {
    void flush().catch((error: unknown) => {
      log("error", "journal flush failed", { code: error instanceof Error ? error.name : "error" });
    });
  }, 60_000);
  timer.unref();

  const server = createServer(async (req, res) => {
    if (req.method === "GET" && (req.url === "/healthz" || req.url === "/readyz")) {
      res.writeHead(200, { "content-type": "application/json" });
      res.end(JSON.stringify({ status: "ok" }));
      return;
    }
    if (req.method === "POST" && req.url === "/v1/journal") {
      const chunks: Buffer[] = [];
      for await (const chunk of req) {
        chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
      }
      const sample = JSON.parse(Buffer.concat(chunks).toString("utf8")) as Sample;
      buffer.push(sample);
      res.writeHead(202, { "content-type": "application/json" });
      res.end(JSON.stringify({ accepted: true }));
      return;
    }
    res.writeHead(404);
    res.end();
  });

  return {
    server,
    stop: async () => {
      stopped = true;
      clearInterval(timer);
      await flush();
      await new Promise<void>((resolve) => server.close(() => resolve()));
    },
  };
}

export function listen(server: ReturnType<typeof createCollector>["server"], port: number): Promise<void> {
  return new Promise((resolve) => server.listen(port, resolve));
}
