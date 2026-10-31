import type { Context, MiddlewareHandler } from 'hono';
import { getCookie, setCookie } from 'hono/cookie';

/** `hono/cookie` does not export its options type, so derive it. */
type CookieOptions = NonNullable<Parameters<typeof setCookie>[3]>;
import { config } from './config.ts';
import { sql } from './db.ts';
import { ApiError } from './errors.ts';
import { hashToken } from './tokens.ts';

export interface AuthUser {
  id: string;
  email: string;
  role: 'admin' | 'user';
  status: 'pending' | 'approved' | 'rejected';
  full_name: string | null;
  created_at: string;
}

export type AppEnv = { Variables: { user: AuthUser } };

/** Session cookie name used by the web client. */
export const SESSION_COOKIE = 'cw_session';

/** httpOnly session cookie options. Secure by default in production. */
export function sessionCookieOptions(): CookieOptions {
  return {
    httpOnly: true,
    sameSite: 'Lax',
    secure: config.cookieSecure,
    path: '/',
    maxAge: config.sessionTtlDays * 86_400,
  };
}

function bearerToken(header: string | undefined): string | null {
  if (!header) return null;
  const match = /^bearer\s+(.+)$/i.exec(header.trim());
  return match?.[1]?.trim() || null;
}

/**
 * Resolves the session token from either `Authorization: Bearer` (the Flutter
 * client and API tooling) or the httpOnly session cookie (the React client).
 */
export function tokenFromRequest(c: Context): string | null {
  return bearerToken(c.req.header('authorization')) ?? getCookie(c, SESSION_COOKIE) ?? null;
}

/** Resolves a bearer token to a user, refreshing the session's sliding expiry. */
export async function authenticateToken(token: string | null): Promise<AuthUser | null> {
  if (!token) return null;
  const tokenHash = hashToken(token);

  const rows = await sql<AuthUser[]>`
    select u.id, u.email, u.role, u.status, u.full_name, u.created_at
    from sessions s
    join users u on u.id = s.user_id
    where s.token_hash = ${tokenHash} and s.expires_at > now()
    limit 1
  `;
  const user = rows[0];
  if (!user) return null;

  const expiresAt = new Date(Date.now() + config.sessionTtlDays * 86_400_000);
  await sql`
    update sessions
    set last_seen_at = now(), expires_at = ${expiresAt}
    where token_hash = ${tokenHash}
  `;
  return user;
}

/** Requires a valid session; puts the user on `c.get('user')`. */
export const requireAuth: MiddlewareHandler<AppEnv> = async (c, next) => {
  const user = await authenticateToken(tokenFromRequest(c));
  if (!user) throw ApiError.unauthorized();
  c.set('user', user);
  await next();
};

/** Requires the authenticated user to be an approved admin. */
export const requireAdmin: MiddlewareHandler<AppEnv> = async (c, next) => {
  const user = await authenticateToken(tokenFromRequest(c));
  if (!user) throw ApiError.unauthorized();
  if (user.role !== 'admin' || user.status !== 'approved') throw ApiError.forbidden();
  c.set('user', user);
  await next();
};
