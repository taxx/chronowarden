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
  /** Optional SL Journey Planner API key, forwarded as `X-Api-Key`. */
  slApiKey?: string;
  /**
   * Optional allowed origin for cross-origin requests. Production runs behind
   * the same-origin proxy and needs none; local `flutter run -d chrome` does.
   */
  corsOrigin?: string;
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
  slApiKey: Bun.env['SL_API_KEY'] || undefined,
  corsOrigin: Bun.env['CORS_ORIGIN'] || undefined,
};
