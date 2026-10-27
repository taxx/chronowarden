import { Hono } from 'hono';
import { cors } from 'hono/cors';
import type { AppEnv } from './auth.ts';
import { config } from './config.ts';
import { ApiError } from './errors.ts';
import { adminRoutes } from './routes/admin.ts';
import { authRoutes } from './routes/auth.ts';
import { backupRoutes } from './routes/backup.ts';
import { dataRoutes } from './routes/data.ts';
import { eventRoutes } from './routes/events.ts';
import { slRoutes } from './routes/sl.ts';

export const app = new Hono();

// Production is same-origin behind the proxy, so CORS is only enabled when an
// explicit origin is configured (local Flutter web development).
if (config.corsOrigin) {
  app.use(
    '/api/*',
    cors({
      origin: config.corsOrigin,
      allowHeaders: ['authorization', 'content-type'],
      allowMethods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    }),
  );
}

app.get('/api/health', (c) => c.json({ ok: true }));

const api = new Hono<AppEnv>();
api.route('/', authRoutes);
api.route('/', adminRoutes);
api.route('/', dataRoutes);
api.route('/', backupRoutes);
api.route('/', slRoutes);
api.route('/', eventRoutes);
app.route('/api/v1', api);

app.notFound((c) => c.json({ error: { code: 'NOT_FOUND', message: 'Not found' } }, 404));

app.onError((error, c) => {
  if (error instanceof ApiError) {
    return c.json({ error: { code: error.code, message: error.message } }, error.status as any);
  }
  // Unique-violation from Postgres surfaces as a conflict rather than a 500.
  const code = (error as { code?: string }).code;
  if (code === '23505') {
    return c.json({ error: { code: 'CONFLICT', message: 'That record already exists' } }, 409);
  }
  console.error('[api] unhandled error:', error);
  return c.json({ error: { code: 'INTERNAL', message: 'Internal server error' } }, 500);
});
