import postgres from 'postgres';
import { config } from './config.ts';

/**
 * Shared Postgres connection pool.
 *
 * Every query is scoped to the authenticated user in the route layer — the
 * database has no RLS because this API is its only client.
 */
export const sql = postgres(config.databaseUrl, {
  max: 10,
  idle_timeout: 20,
  connect_timeout: 10,
  onnotice: () => {},
});

export type Sql = typeof sql;
