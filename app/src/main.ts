import { createServer } from "node:http";
import { createApiServer, markShuttingDown } from "./api.ts";
import { createCollector, listen } from "./collector.ts";
import { commandName, optional } from "./config.ts";
import { createIamPool } from "./db.ts";
import { log } from "./log.ts";
import { migrate } from "./migrate.ts";
import { verify } from "./verify.ts";
import { runWorker } from "./worker.ts";

const command = commandName(process.argv);
const port = Number(optional("PORT", "8080"));

if (command === "migrate") {
  await migrate();
} else if (command === "verify") {
  const pool = createIamPool();
  try {
    await verify(pool);
  } finally {
    await pool.end();
  }
} else if (command === "collector") {
  const collector = createCollector();
  await listen(collector.server, port);
  log("info", "collector listening", { port });
  process.once("SIGTERM", () => {
    void collector.stop().then(() => process.exit(0));
  });
} else if (command === "api") {
  const pool = createIamPool();
  const server = createApiServer(pool);
  await new Promise<void>((resolve) => server.listen(port, resolve));
  log("info", "api listening", { port });
  process.once("SIGTERM", () => {
    markShuttingDown();
    server.close(() => {
      void pool.end().then(() => process.exit(0));
    });
  });
} else {
  const pool = createIamPool();
  const health = createServer((req, res) => {
    if (req.url === "/healthz" || req.url === "/readyz") {
      res.writeHead(200, { "content-type": "application/json" });
      res.end(JSON.stringify({ status: "ok" }));
      return;
    }
    res.writeHead(404);
    res.end();
  });
  await new Promise<void>((resolve) => health.listen(port, resolve));
  try {
    await runWorker(pool, () => undefined);
  } finally {
    health.close();
    await pool.end();
  }
}
