import { Hono } from 'hono';
import { streamSSE } from 'hono/streaming';
import type { AppEnv } from '../auth.ts';
import { authenticateToken } from '../auth.ts';
import { addSubscriber, removeSubscriber } from '../events.ts';
import { ApiError } from '../errors.ts';

export const eventRoutes = new Hono<AppEnv>();

const KEEP_ALIVE_MS = 25_000;

/**
 * Server-Sent Events stream of data changes for the authenticated user.
 *
 * `EventSource` cannot set headers, so the session token is passed as a query
 * parameter (same-origin over HTTPS).
 */
eventRoutes.get('/events', async (c) => {
  const user = await authenticateToken(c.req.query('token') ?? null);
  if (!user) throw ApiError.unauthorized();

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
