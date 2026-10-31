import { app } from './app.ts';
import { config } from './config.ts';
import { sql } from './db.ts';
import { migrate } from './migrate.ts';

// Apply any pending migrations before accepting traffic.
await migrate(sql);

const server = Bun.serve({
  port: config.port,
  fetch: app.fetch,
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
