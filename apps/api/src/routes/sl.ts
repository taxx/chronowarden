import { Hono } from 'hono';
import type { AppEnv } from '../auth.ts';
import { requireAuth } from '../auth.ts';
import { config } from '../config.ts';
import { ApiError } from '../errors.ts';
import { fetchSl } from '../sl.ts';

export const slRoutes = new Hono<AppEnv>();


/**
 * Proxies a Journey Planner path and returns (slimmed) JSON.
 *
 * Body: `{ "path": "/v2/trips?...&calc_number_of_trips=3" }`
 */
slRoutes.post('/sl/proxy', requireAuth, async (c) => {
  const input = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
  const path = typeof input.path === 'string' ? input.path : '';

  // Only allow Journey Planner v2 paths — never an arbitrary URL.
  if (!path.startsWith('/v2/') || path.includes('://')) {
    throw ApiError.badRequest('INVALID_PATH', 'path must be a Journey Planner /v2/ path');
  }

  try {
    const text = await fetchSl(path, config.slApiKey);
    return c.body(text, 200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-cache' });
  } catch (error) {
    const status = (error as { status?: number }).status ?? 502;
    throw new ApiError(status, 'SL_PROXY_ERROR', (error as Error).message);
  }
});
