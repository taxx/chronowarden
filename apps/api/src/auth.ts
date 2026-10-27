import type { MiddlewareHandler } from 'hono';
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

const USER_COLUMNS = 'id, email, role, status, full_name, created_at';

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

function bearerToken(header: string | undefined): string | null {
  if (!header) return null;
  const match = /^bearer\s+(.+)$/i.exec(header.trim());
  return match?.[1]?.trim() || null;
}

/** Requires a valid session; puts the user on `c.get('user')`. */
export const requireAuth: MiddlewareHandler<AppEnv> = async (c, next) => {
  const user = await authenticateToken(bearerToken(c.req.header('authorization')));
  if (!user) throw ApiError.unauthorized();
  c.set('user', user);
  await next();
};

/** Requires the authenticated user to be an approved admin. */
export const requireAdmin: MiddlewareHandler<AppEnv> = async (c, next) => {
  const user = await authenticateToken(bearerToken(c.req.header('authorization')));
  if (!user) throw ApiError.unauthorized();
  if (user.role !== 'admin' || user.status !== 'approved') throw ApiError.forbidden();
  c.set('user', user);
  await next();
};

export { USER_COLUMNS };
