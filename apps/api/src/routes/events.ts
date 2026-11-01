import { Hono } from 'hono';
import { streamSSE } from 'hono/streaming';
import type { AppEnv } from '../auth.ts';
import { authenticateToken, tokenFromRequest } from '../auth.ts';
import { addSubscriber, canSubscribe, removeSubscriber } from '../events.ts';
import { ApiError } from '../errors.ts';

export const eventRoutes = new Hono<AppEnv>();

const KEEP_ALIVE_MS = 25_000;

/**
 * Server-Sent Events stream of data changes for the authenticated user.
 *
 * The React client authenticates with the httpOnly cookie, so the browser never
 * puts the token in a URL. The `?token=` fallback exists for clients that
 * cannot send headers (`EventSource` + bearer); note that such URLs can land in
 * proxy access logs, so it should be avoided when a cookie is available.
 */
eventRoutes.get('/events', async (c) => {
  const user = await authenticateToken(c.req.query('token') ?? tokenFromRequest(c));
  if (!user) throw ApiError.unauthorized();
  if (!canSubscribe(user.id)) {
    throw new ApiError(429, 'TOO_MANY_STREAMS', 'Too many open event streams — close one and try again');
  }

  return streamSSE(c, async (stream) => {
    const subscriber = (payload: string) => {
      void stream.write(payload);
    };
    addSubscriber(user.id, subscriber);

    // Confirm the stream is live, then keep it open (and the connection warm).
    await stream.writeSSE({ event: 'ready', data: user.id });
    try {
      while (!stream.aborted) {
        await stream.sleep(KEEP_ALIVE_MS);
        await stream.write(': keep-alive\n\n');
      }
    } finally {
      removeSubscriber(user.id, subscriber);
    }
  });
});
