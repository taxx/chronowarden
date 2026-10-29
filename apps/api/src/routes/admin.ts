import { Hono } from 'hono';
import type { AppEnv } from '../auth.ts';
import { requireAdmin } from '../auth.ts';
import { sql } from '../db.ts';
import { ApiError } from '../errors.ts';
import { generateTemporaryPassword, generateToken, hashToken } from '../tokens.ts';
import { hashPassword } from '../password.ts';

export const adminRoutes = new Hono<AppEnv>();

const USER_COLUMNS = 'id, email, role, status, full_name, created_at';
const DAY_MS = 86_400_000;

adminRoutes.get('/admin/users', requireAdmin, async (c) => {
  const rows = await sql`select ${sql.unsafe(USER_COLUMNS)} from users order by created_at desc`;
  return c.json(rows);
});

/** Approve / reject / promote a user, or rename them. */
adminRoutes.patch('/admin/users/:id', requireAdmin, async (c) => {
  const id = c.req.param('id');
  const input = (await c.req.json().catch(() => ({}))) as Record<string, any>;

  const status = input.status as string | undefined;
  const role = input.role as string | undefined;
  const fullName = input.fullName as string | undefined;

  if (status !== undefined && !['pending', 'approved', 'rejected'].includes(status)) {
    throw ApiError.badRequest('INVALID_STATUS', 'Unknown status value');
  }
  if (role !== undefined && !['admin', 'user'].includes(role)) {
    throw ApiError.badRequest('INVALID_ROLE', 'Unknown role value');
  }

  const rows = await sql`
    update users set
      status    = coalesce(${status ?? null}, status),
      role      = coalesce(${role ?? null}, role),
      full_name = coalesce(${fullName ?? null}, full_name),
      updated_at = now()
    where id = ${id}
    returning ${sql.unsafe(USER_COLUMNS)}
  `;
  if (rows.length === 0) throw ApiError.notFound('User not found');
  return c.json(rows[0]);
});

/**
 * Admin-assisted password reset. Issues a fresh temporary password (shown once)
 * and revokes the user's existing sessions. The encryption envelope is never
 * touched — the user's passphrase is separate and unchanged.
 */
adminRoutes.post('/admin/users/:id/reset-password', requireAdmin, async (c) => {
  const id = c.req.param('id');
  const rows = await sql`select id, email from users where id = ${id}`;
  if (rows.length === 0) throw ApiError.notFound('User not found');

  const temporaryPassword = generateTemporaryPassword();
  await sql`
    update users set password_hash = ${await hashPassword(temporaryPassword)}, updated_at = now()
    where id = ${id}
  `;
  await sql`delete from sessions where user_id = ${id}`;

  return c.json({ email: rows[0].email, temporaryPassword });
});

/** Permanently deletes a user; sessions, data and presets cascade. */
adminRoutes.delete('/admin/users/:id', requireAdmin, async (c) => {
  const id = c.req.param('id');
  const currentUser = c.get('user');
  if (id === currentUser.id) throw ApiError.badRequest('CANNOT_DELETE_SELF', 'You cannot delete your own account');
  await sql`delete from users where id = ${id}`;
  return c.body(null, 204);
});

adminRoutes.get('/admin/invites', requireAdmin, async (c) => {
  const rows = await sql`
    select id, email, role, used_at, expires_at, created_at
    from invites order by created_at desc
  `;
  return c.json(rows);
});

/** Creates (or refreshes) an invitation and returns the raw token exactly once. */
adminRoutes.post('/admin/invites', requireAdmin, async (c) => {
  const input = (await c.req.json().catch(() => ({}))) as Record<string, any>;
  const email = typeof input.email === 'string' ? input.email.trim().toLowerCase() : '';
  if (!email) throw ApiError.badRequest('INVALID_EMAIL', 'An email address is required');

  const role = input.role === 'admin' ? 'admin' : 'user';
  const ttlDays = Math.min(Math.max(Number(input.ttlDays) || 14, 1), 90);

  const token = generateToken();
  const expiresAt = new Date(Date.now() + ttlDays * DAY_MS);
  const user = c.get('user');

  // One live invite per email: refresh it instead of stacking duplicates.
  await sql`delete from invites where email = ${email} and used_at is null`;
  const rows = await sql`
    insert into invites (email, token_hash, role, invited_by, expires_at)
    values (${email}, ${hashToken(token)}, ${role}, ${user.id}, ${expiresAt})
    returning id, email, role, expires_at, created_at
  `;
  return c.json({ ...rows[0], token }, 201);
});

adminRoutes.delete('/admin/invites/:id', requireAdmin, async (c) => {
  await sql`delete from invites where id = ${c.req.param('id')}`;
  return c.body(null, 204);
});
