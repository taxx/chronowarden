/**
 * E2E server for the React client: throwaway Postgres + the real API + the
 * built `apps/web/dist` on one origin (mirroring the production proxy).
 */
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { startTestPostgres } from '../apps/api/test/helpers/postgres.ts';

const db = await startTestPostgres();
process.env['DATABASE_URL'] = db.url;
process.env['SESSION_TTL_DAYS'] = '30';

const { sql } = await import('../apps/api/src/db.ts');
const { migrate } = await import('../apps/api/src/migrate.ts');
const { app } = await import('../apps/api/src/app.ts');
await migrate(sql);

const webRoot = join(import.meta.dirname, '..', 'apps', 'web', 'dist');
const port = Number(process.env['E2E_PORT'] ?? '8098');

/** Same security headers the production proxy sets, so the CSP is exercised. */
const SECURITY_HEADERS: Record<string, string> = {
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
  'X-Content-Type-Options': 'nosniff',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'X-Frame-Options': 'DENY',
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
  'Content-Security-Policy':
    "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; " +
    "img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self'; " +
    "object-src 'none'; base-uri 'self'; frame-ancestors 'none'; form-action 'self'; " +
    "worker-src 'self' blob:; manifest-src 'self'",
};

const server = Bun.serve({
  port,
  hostname: '127.0.0.1',
  async fetch(request) {
    const url = new URL(request.url);
    if (url.pathname.startsWith('/api')) return app.fetch(request);

    const path = url.pathname === '/' ? '/index.html' : url.pathname;
    let file = Bun.file(join(webRoot, path));
    if (!(await file.exists())) file = Bun.file(join(webRoot, 'index.html')); // SPA fallback
    return new Response(file, { headers: SECURITY_HEADERS });
  },
});

console.log(`[e2e] server ready at http://127.0.0.1:${server.port}`);

async function shutdown() {
  server.stop();
  await sql.end({ timeout: 5 });
  await db.stop();
  process.exit(0);
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
