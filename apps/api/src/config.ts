/**
 * Runtime configuration, read from the environment.
 *
 * DATABASE_URL is required; everything else has a safe default.
 */
export interface AppConfig {
  databaseUrl: string;
  port: number;
  /** Session lifetime in days. Sliding: each authenticated request refreshes it. */
  sessionTtlDays: number;
  /** Hard upper bound on a session's age, regardless of activity. */
  sessionAbsoluteTtlDays: number;
  /** Maximum accepted request body size, in bytes. */
  maxBodyBytes: number;
  /** Optional SL Journey Planner API key, forwarded as `X-Api-Key`. */
  slApiKey?: string;
  /**
   * Optional allowed origin for cross-origin requests. Production runs behind
   * the same-origin proxy and needs none; bypassing the Vite proxy does.
   */
  corsOrigin?: string;
  /**
   * Whether the session cookie is marked `Secure`. Defaults to true in
   * production (TLS terminated at the host proxy); override with
   * `COOKIE_SECURE=false` for plain-HTTP local development.
   */
  cookieSecure: boolean;
}

/**
 * Only a concrete origin is acceptable for credentialed CORS. A wildcard would
 * let any site make authenticated requests with the session cookie.
 */
function normalizeCorsOrigin(value: string | undefined): string | undefined {
  if (!value) return undefined;
  const origin = value.trim();
  if (origin === '*' || origin === 'null') {
    throw new Error('CORS_ORIGIN must be a concrete origin (wildcards are not allowed)');
  }
  try {
    const parsed = new URL(origin);
    if (parsed.origin !== origin) {
      throw new Error('CORS_ORIGIN must not contain a path or trailing slash');
    }
    return origin;
  } catch {
    throw new Error(`Invalid CORS_ORIGIN: ${origin}`);
  }
}

function env(name: string, fallback?: string): string {
  const value = Bun.env[name] ?? fallback;
  if (value === undefined) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export const config: AppConfig = {
  databaseUrl: env('DATABASE_URL'),
  port: Number(env('PORT', '8080')),
  sessionTtlDays: Number(env('SESSION_TTL_DAYS', '30')),
  sessionAbsoluteTtlDays: Number(env('SESSION_ABSOLUTE_TTL_DAYS', '90')),
  maxBodyBytes: Number(env('MAX_BODY_BYTES', String(8 * 1024 * 1024))),
  slApiKey: Bun.env['SL_API_KEY'] || undefined,
  corsOrigin: normalizeCorsOrigin(Bun.env['CORS_ORIGIN']),
  cookieSecure: Bun.env['COOKIE_SECURE']
    ? Bun.env['COOKIE_SECURE'] === 'true'
    : Bun.env['NODE_ENV'] === 'production',
};
