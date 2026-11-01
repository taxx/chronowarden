import { app } from './app.ts';
import { config } from './config.ts';
import { sql } from './db.ts';
import { cleanupExpired } from './maintenance.ts';
import { migrate } from './migrate.ts';

// Apply any pending migrations before accepting traffic.
await migrate(sql);
await cleanupExpired(sql);

// Periodic housekeeping (unref'd so it never keeps the process alive).
const cleanupTimer = setInterval(() => {
  void cleanupExpired(sql).catch((error) => console.error('[api] cleanup failed:', error));
}, 60 * 60 * 1000);
cleanupTimer.unref?.();

const server = Bun.serve({
  port: config.port,
  fetch: app.fetch,
  maxRequestBodySize: config.maxBodyBytes,
});

console.log(`[api] ChronoWarden API listening on http://0.0.0.0:${server.port}`);

for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.on(signal, async () => {
    console.log(`[api] ${signal} received, shutting down`);
    server.stop();
    await sql.end({ timeout: 5 });
    process.exit(0);
  });
}
