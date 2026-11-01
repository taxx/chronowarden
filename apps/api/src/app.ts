import { Hono } from 'hono';
import { bodyLimit } from 'hono/body-limit';
import { cors } from 'hono/cors';
import { secureHeaders } from 'hono/secure-headers';
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

/** Extract a hostname from an Origin or Host value (tolerates a bare host). */
function hostnameOf(value: string | undefined): string | null {
  if (!value) return null;
  try {
    return new URL(value.includes('://') ? value : `http://${value}`).hostname;
  } catch {
    return null;
  }
}

// Baseline security headers on every API response (CSP-free JSON stays inert).
app.use('/api/*', secureHeaders({ xFrameOptions: 'DENY' }));

// Reject oversized bodies before they are buffered/parsed.
app.use(
  '/api/*',
  bodyLimit({
    maxSize: config.maxBodyBytes,
    onError: (c) =>
      c.json({ error: { code: 'PAYLOAD_TOO_LARGE', message: 'Request body is too large' } }, 413),
  }),
);

// Production is same-origin behind the proxy, so CORS is only enabled when an
// explicit origin is configured (local Flutter web development).
if (config.corsOrigin) {
  app.use(
    '/api/*',
    cors({
      origin: config.corsOrigin,
      allowHeaders: ['authorization', 'content-type'],
      allowMethods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
      // Required so the browser sends/stores the session cookie in local dev.
      credentials: true,
    }),
  );
}

/**
 * Origin guard for cookie-authenticated mutations.
 *
 * SameSite=Lax already blocks cross-site cookie sends on POST/PATCH/DELETE,
 * but this rejects requests whose `Origin` doesn't match the host as
 * defence-in-depth (and covers any future cookie there). Requests without an
 * Origin header (CLI/curl/tests) are allowed.
 */
app.use('/api/*', async (c, next) => {
  const method = c.req.method;
  if (method !== 'GET' && method !== 'HEAD' && method !== 'OPTIONS') {
    const origin = c.req.header('origin');
    if (origin) {
      // `Host` may be absent when the app is driven in-process (tests); fall
      // back to the request URL.
      const requestHost = hostnameOf(c.req.header('host')) ?? hostnameOf(new URL(c.req.url).host);
      const originHost = hostnameOf(origin);
      const allowed =
        origin === config.corsOrigin ||
        (originHost !== null && requestHost !== null && originHost === requestHost);
      if (!allowed) throw new ApiError(403, 'BAD_ORIGIN', 'Cross-origin request rejected');
    }
  }
  await next();
});

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
