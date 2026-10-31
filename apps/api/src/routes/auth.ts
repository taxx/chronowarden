import { Hono } from 'hono';
import { deleteCookie, setCookie } from 'hono/cookie';
import type { AppEnv } from '../auth.ts';
import { SESSION_COOKIE, requireAuth, sessionCookieOptions, tokenFromRequest } from '../auth.ts';
import { config } from '../config.ts';
import { sql } from '../db.ts';
import { ApiError } from '../errors.ts';
import { hashPassword, validatePasswordStrength, verifyPassword } from '../password.ts';
import { generateToken, hashToken } from '../tokens.ts';

export const authRoutes = new Hono<AppEnv>();

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const USER_COLUMNS = 'id, email, role, status, full_name, created_at';

function normalizeEmail(email: unknown): string {
  if (typeof email !== 'string') throw ApiError.badRequest('INVALID_EMAIL', 'Email is required');
  const value = email.trim().toLowerCase();
  if (!EMAIL_RE.test(value)) throw ApiError.badRequest('INVALID_EMAIL', 'Enter a valid email address');
  return value;
}

async function issueSession(userId: string): Promise<string> {
  const token = generateToken();
  const expiresAt = new Date(Date.now() + config.sessionTtlDays * 86_400_000);
  await sql`
    insert into sessions (token_hash, user_id, expires_at)
    values (${hashToken(token)}, ${userId}, ${expiresAt})
  `;
  return token;
}

async function body(c: { req: { json: () => Promise<unknown> } }): Promise<Record<string, any>> {
  try {
    return (await c.req.json()) as Record<string, any>;
  } catch {
    return {};
  }
}

/**
 * Public bootstrap probe: whether any user exists yet.
 * Drives the client's first-run admin setup screen.
 */
authRoutes.get('/state', async (c) => {
  const rows = await sql<{ has_users: boolean }[]>`
    select exists(select 1 from users) as has_users
  `;
  return c.json({ has_users: rows[0]?.has_users ?? false });
});

/** Creates the first administrator. Only succeeds while the database is empty. */
authRoutes.post('/auth/setup', async (c) => {
  const input = await body(c);
  const count = await sql<{ n: number }[]>`select count(*)::int as n from users`;
  if ((count[0]?.n ?? 0) > 0) {
    throw ApiError.conflict('SETUP_COMPLETE', 'Initial setup has already been completed');
  }

  const email = normalizeEmail(input.email);
  const passwordError = validatePasswordStrength(input.password);
  if (passwordError) throw ApiError.badRequest('WEAK_PASSWORD', passwordError);

  const rows = await sql`
    insert into users (email, password_hash, full_name, role, status)
    values (${email}, ${await hashPassword(input.password)}, ${input.fullName ?? null}, 'admin', 'approved')
    returning ${sql.unsafe(USER_COLUMNS)}
  `;
  const user = rows[0]!;
  const token = await issueSession(user.id);
  setCookie(c, SESSION_COOKIE, token, sessionCookieOptions());
  return c.json({ token, user }, 201);
});

/** Invite-only registration. The invitation is bound to the email address. */
authRoutes.post('/auth/register', async (c) => {
  const input = await body(c);
  const email = normalizeEmail(input.email);
  const passwordError = validatePasswordStrength(input.password);
  if (passwordError) throw ApiError.badRequest('WEAK_PASSWORD', passwordError);

  const inviteToken = typeof input.inviteToken === 'string' ? input.inviteToken.trim() : '';
  if (!inviteToken) throw ApiError.badRequest('INVITE_REQUIRED', 'An invitation is required to register');

  const user = await sql.begin(async (tx) => {
    const invites = await tx`
      select * from invites where token_hash = ${hashToken(inviteToken)} limit 1
    `;
    const invite = invites[0];
    if (!invite) throw ApiError.badRequest('INVALID_INVITE', 'Invitation is not valid');
    if (invite.used_at) throw ApiError.badRequest('INVITE_USED', 'Invitation has already been used');
    if (new Date(invite.expires_at).getTime() < Date.now()) {
      throw ApiError.badRequest('INVITE_EXPIRED', 'Invitation has expired');
    }
    if (invite.email !== email) {
      throw ApiError.badRequest('INVITE_EMAIL_MISMATCH', 'Invitation was issued to a different email');
    }

    const existing = await tx`select id from users where email = ${email} limit 1`;
    if (existing.length > 0) {
      throw ApiError.conflict('EMAIL_TAKEN', 'An account with this email already exists');
    }

    const created = await tx`
      insert into users (email, password_hash, full_name, role, status)
      values (${email}, ${await hashPassword(input.password)}, ${input.fullName ?? null}, ${invite.role}, 'approved')
      returning ${tx.unsafe(USER_COLUMNS)}
    `;
    await tx`update invites set used_at = now() where id = ${invite.id}`;
    return created[0]!;
  });

  const token = await issueSession(user.id);
  setCookie(c, SESSION_COOKIE, token, sessionCookieOptions());
  return c.json({ token, user }, 201);
});

authRoutes.post('/auth/login', async (c) => {
  const input = await body(c);
  const email = normalizeEmail(input.email);

  const rows = await sql<
    { id: string; status: string; password_hash: string }[]
  >`select id, status, password_hash from users where email = ${email} limit 1`;
  const account = rows[0];

  // Same message for unknown user and wrong password.
  const valid = account ? await verifyPassword(account.password_hash, String(input.password ?? '')) : false;
  if (!account || !valid) {
    throw ApiError.badRequest('INVALID_CREDENTIALS', 'Invalid email or password');
  }
  if (account.status === 'rejected') {
    throw ApiError.badRequest('ACCOUNT_DISABLED', 'This account has been disabled');
  }

  const users = await sql`select ${sql.unsafe(USER_COLUMNS)} from users where id = ${account.id}`;
  const token = await issueSession(account.id);
  setCookie(c, SESSION_COOKIE, token, sessionCookieOptions());
  return c.json({ token, user: users[0] });
});

/** Revokes the presented session token. */
authRoutes.post('/auth/logout', requireAuth, async (c) => {
  const token = tokenFromRequest(c);
  if (token) {
    await sql`delete from sessions where token_hash = ${hashToken(token)}`;
  }
  deleteCookie(c, SESSION_COOKIE, { path: '/' });
  return c.json({ ok: true });
});

/** Validates an invitation before registration (public). */
authRoutes.post('/invites/validate', async (c) => {
  const input = await body(c);
  const token = typeof input.token === 'string' ? input.token.trim() : '';
  if (!token) return c.json({ valid: false, reason: 'missing' });

  const rows = await sql`select email, used_at, expires_at from invites where token_hash = ${hashToken(token)} limit 1`;
  const invite = rows[0];
  if (!invite) return c.json({ valid: false, reason: 'not_found' });
  if (invite.used_at) return c.json({ valid: false, reason: 'used' });
  if (new Date(invite.expires_at).getTime() < Date.now()) return c.json({ valid: false, reason: 'expired' });
  return c.json({ valid: true, email: invite.email });
});

authRoutes.get('/me', requireAuth, async (c) => c.json(c.get('user')));

authRoutes.patch('/me', requireAuth, async (c) => {
  const input = await body(c);
  const user = c.get('user');
  const rows = await sql`
    update users set full_name = ${input.fullName ?? null}, updated_at = now()
    where id = ${user.id}
    returning ${sql.unsafe(USER_COLUMNS)}
  `;
  return c.json(rows[0]);
});

/** Changes the authenticated user's password after verifying the current one. */
authRoutes.patch('/me/password', requireAuth, async (c) => {
  const input = await body(c);
  const userId = c.get('user').id;

  const rows = await sql<{ password_hash: string }[]>`select password_hash from users where id = ${userId}`;
  const valid = rows[0] ? await verifyPassword(rows[0].password_hash, String(input.currentPassword ?? '')) : false;
  if (!valid) throw ApiError.badRequest('WRONG_PASSWORD', 'Current password is incorrect');

  const passwordError = validatePasswordStrength(input.newPassword);
  if (passwordError) throw ApiError.badRequest('WEAK_PASSWORD', passwordError);

  await sql`update users set password_hash = ${await hashPassword(input.newPassword)}, updated_at = now() where id = ${userId}`;
  return c.json({ ok: true });
});
