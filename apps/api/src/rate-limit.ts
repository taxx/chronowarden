import type { Context, MiddlewareHandler } from 'hono';

/**
 * Small in-process fixed-window rate limiter.
 *
 * ChronoWarden runs as a single API container, so an in-memory limiter is
 * enough to keep auth endpoints from becoming an Argon2 amplification vector
 * and to blunt repeated-invite/registration attempts. It is deliberately
 * best-effort: a restart clears it, and the nginx front door has its own
 * (coarser) limits as a backstop.
 */

interface Bucket {
  count: number;
  resetAt: number;
}

const buckets = new Map<string, Bucket>();
let lastSweep = 0;
const SWEEP_INTERVAL_MS = 60_000;

/** Drop expired buckets so attacker-controlled keys cannot grow unbounded. */
function sweep(now: number): void {
  if (now - lastSweep < SWEEP_INTERVAL_MS) return;
  lastSweep = now;
  for (const [key, bucket] of buckets) {
    if (bucket.resetAt <= now) buckets.delete(key);
  }
}

/**
 * Best-effort client identifier.
 *
 * The front door sets `X-Forwarded-For` (client, hop) and `X-Real-IP`. We use
 * the left-most forwarded entry — the real client when the host reverse proxy
 * forwards it. This is spoofable if the proxy only appends, which is why the
 * authenticated/account-scoped limits do the heavy lifting.
 */
export function clientKey(c: Context): string {
  const forwarded = c.req.header('x-forwarded-for');
  if (forwarded) {
    const first = forwarded.split(',')[0]?.trim();
    if (first) return first;
  }
  return c.req.header('x-real-ip')?.trim() || 'local';
}

export interface RateLimitRule {
  windowMs: number;
  max: number;
}

export interface RateLimitResult {
  allowed: boolean;
  retryAfterSeconds: number;
  remaining: number;
}

/** Increment and test a bucket. */
export function consume(
  name: string,
  key: string,
  rule: RateLimitRule,
  now = Date.now(),
): RateLimitResult {
  sweep(now);
  const bucketKey = `${name}:${key}`;
  let bucket = buckets.get(bucketKey);
  if (!bucket || bucket.resetAt <= now) {
    bucket = { count: 0, resetAt: now + rule.windowMs };
    buckets.set(bucketKey, bucket);
  }
  bucket.count += 1;
  return {
    allowed: bucket.count <= rule.max,
    retryAfterSeconds: Math.max(1, Math.ceil((bucket.resetAt - now) / 1000)),
    remaining: Math.max(0, rule.max - bucket.count),
  };
}

/** Inspect a bucket without incrementing it. */
export function peek(name: string, key: string, rule: RateLimitRule, now = Date.now()): RateLimitResult {
  sweep(now);
  const bucket = buckets.get(`${name}:${key}`);
  if (!bucket || bucket.resetAt <= now) {
    return { allowed: true, retryAfterSeconds: 0, remaining: rule.max };
  }
  return {
    allowed: bucket.count < rule.max,
    retryAfterSeconds: Math.max(1, Math.ceil((bucket.resetAt - now) / 1000)),
    remaining: Math.max(0, rule.max - bucket.count),
  };
}

/** Forget a bucket (e.g. after a successful login). */
export function clear(name: string, key: string): void {
  buckets.delete(`${name}:${key}`);
}

/** Test helper — reset all state. */
export function resetRateLimits(): void {
  buckets.clear();
}

/** The shared 429 response, including a `Retry-After` header. */
export function rateLimited(c: Context, retryAfterSeconds: number): Response {
  return c.json(
    {
      error: {
        code: 'RATE_LIMITED',
        message: 'Too many requests — please wait a moment and try again.',
      },
    },
    429,
    { 'Retry-After': String(retryAfterSeconds) },
  );
}

/**
 * Middleware that rejects with 429 when the rule is exceeded.
 *
 * `key` may add a second identifier (e.g. the account email).
 */
export function rateLimit(
  name: string,
  rule: RateLimitRule,
  key?: (c: Context) => string | null,
): MiddlewareHandler {
  return async (c, next) => {
    if (process.env['RATE_LIMIT_DISABLED'] === '1') return next();
    const extra = key?.(c);
    const bucketKey = extra ? `${clientKey(c)}|${extra}` : clientKey(c);
    const result = consume(name, bucketKey, rule);
    if (!result.allowed) return rateLimited(c, result.retryAfterSeconds);
    return next();
  };
}
