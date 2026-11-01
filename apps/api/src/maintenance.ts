import type { Sql } from './db.ts';

/**
 * Housekeeping: drop expired sessions and stale invitations so those tables
 * cannot grow without bound. Run at startup and periodically.
 */
export async function cleanupExpired(sql: Sql): Promise<void> {
  await sql`delete from sessions where expires_at < now()`;
  await sql`delete from invites where expires_at < now() - interval '30 days'`;
}
