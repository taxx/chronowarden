import { Hono } from 'hono';
import type { AppEnv } from '../auth.ts';
import { requireAuth } from '../auth.ts';
import { sql } from '../db.ts';
import { publish } from '../events.ts';
import { ApiError } from '../errors.ts';

export const dataRoutes = new Hono<AppEnv>();


// `date` is cast to text so it serialises as YYYY-MM-DD (matching the client),
// not as a full ISO timestamp.
const LOG_COLUMNS = "id, user_id, date::text as date, encrypted_data, created_at";
const PRESET_COLUMNS = 'id, user_id, name, encrypted_data, created_at';

async function json(c: { req: { json: () => Promise<unknown> } }): Promise<Record<string, any>> {
  try {
    return (await c.req.json()) as Record<string, any>;
  } catch {
    return {};
  }
}

function requireString(value: unknown, field: string): string {
  if (typeof value !== 'string') throw ApiError.badRequest('INVALID_BODY', `${field} is required`);
  return value;
}

// ---------------------------------------------------------------------------
// Time logs — one encrypted row per user per day
// ---------------------------------------------------------------------------

dataRoutes.get('/time-logs', requireAuth, async (c) => {
  const userId = c.get('user').id;
  const date = c.req.query('date');

  const rows = date
    ? await sql`
        select ${sql.unsafe(LOG_COLUMNS)} from time_logs
        where user_id = ${userId} and date = ${date}
        limit 1
      `
    : await sql`
        select ${sql.unsafe(LOG_COLUMNS)} from time_logs
        where user_id = ${userId} order by date desc
      `;
  return c.json(rows);
});

dataRoutes.get('/time-logs/:id', requireAuth, async (c) => {
  const userId = c.get('user').id;
  const rows = await sql`
    select ${sql.unsafe(LOG_COLUMNS)} from time_logs
    where id = ${c.req.param('id')} and user_id = ${userId}
    limit 1
  `;
  if (rows.length === 0) throw ApiError.notFound('Time log not found');
  return c.json(rows[0]);
});

dataRoutes.post('/time-logs', requireAuth, async (c) => {
  const userId = c.get('user').id;
  const input = await json(c);
  const date = requireString(input.date, 'date');
  const encrypted = requireString(input.encrypted_data, 'encrypted_data');

  const rows = await sql`
    insert into time_logs (user_id, date, encrypted_data)
    values (${userId}, ${date}, ${encrypted})
    returning ${sql.unsafe(LOG_COLUMNS)}
  `;
  const row = rows[0]!;
  publish(userId, { table: 'time_logs', type: 'INSERT', row });
  return c.json(row, 201);
});

dataRoutes.patch('/time-logs/:id', requireAuth, async (c) => {
  const userId = c.get('user').id;
  const id = c.req.param('id');
  const input = await json(c);
  const encrypted = requireString(input.encrypted_data, 'encrypted_data');

  const rows = await sql`
    update time_logs set encrypted_data = ${encrypted}
    where id = ${id} and user_id = ${userId}
    returning ${sql.unsafe(LOG_COLUMNS)}
  `;
  if (rows.length === 0) throw ApiError.notFound('Time log not found');
  publish(userId, { table: 'time_logs', type: 'UPDATE', row: rows[0]! });
  return c.json(rows[0]);
});

dataRoutes.delete('/time-logs/:id', requireAuth, async (c) => {
  const userId = c.get('user').id;
  const id = c.req.param('id');
  const rows = await sql`
    delete from time_logs where id = ${id} and user_id = ${userId}
    returning ${sql.unsafe(LOG_COLUMNS)}
  `;
  if (rows.length === 0) throw ApiError.notFound('Time log not found');
  publish(userId, { table: 'time_logs', type: 'DELETE', row: rows[0]! });
  return c.body(null, 204);
});

// ---------------------------------------------------------------------------
// Travel presets — `name` is plaintext for dropdowns, the rest is encrypted
// ---------------------------------------------------------------------------

dataRoutes.get('/travel-presets', requireAuth, async (c) => {
  const userId = c.get('user').id;
  const rows = await sql`
    select ${sql.unsafe(PRESET_COLUMNS)} from travel_presets
    where user_id = ${userId} order by name
  `;
  return c.json(rows);
});

dataRoutes.get('/travel-presets/:id', requireAuth, async (c) => {
  const userId = c.get('user').id;
  const rows = await sql`
    select ${sql.unsafe(PRESET_COLUMNS)} from travel_presets
    where id = ${c.req.param('id')} and user_id = ${userId}
    limit 1
  `;
  if (rows.length === 0) throw ApiError.notFound('Travel preset not found');
  return c.json(rows[0]);
});

dataRoutes.post('/travel-presets', requireAuth, async (c) => {
  const userId = c.get('user').id;
  const input = await json(c);
  const name = requireString(input.name, 'name');
  const encrypted = requireString(input.encrypted_data, 'encrypted_data');

  const rows = await sql`
    insert into travel_presets (user_id, name, encrypted_data)
    values (${userId}, ${name}, ${encrypted})
    returning ${sql.unsafe(PRESET_COLUMNS)}
  `;
  const row = rows[0]!;
  publish(userId, { table: 'travel_presets', type: 'INSERT', row });
  return c.json(row, 201);
});

dataRoutes.patch('/travel-presets/:id', requireAuth, async (c) => {
  const userId = c.get('user').id;
  const id = c.req.param('id');
  const input = await json(c);
  const name = typeof input.name === 'string' ? input.name : null;
  const encrypted = requireString(input.encrypted_data, 'encrypted_data');

  const rows = await sql`
    update travel_presets set
      name = coalesce(${name}, name),
      encrypted_data = ${encrypted}
    where id = ${id} and user_id = ${userId}
    returning ${sql.unsafe(PRESET_COLUMNS)}
  `;
  if (rows.length === 0) throw ApiError.notFound('Travel preset not found');
  publish(userId, { table: 'travel_presets', type: 'UPDATE', row: rows[0]! });
  return c.json(rows[0]);
});

dataRoutes.delete('/travel-presets/:id', requireAuth, async (c) => {
  const userId = c.get('user').id;
  const id = c.req.param('id');
  const rows = await sql`
    delete from travel_presets where id = ${id} and user_id = ${userId}
    returning ${sql.unsafe(PRESET_COLUMNS)}
  `;
  if (rows.length === 0) throw ApiError.notFound('Travel preset not found');
  publish(userId, { table: 'travel_presets', type: 'DELETE', row: rows[0]! });
  return c.body(null, 204);
});

// ---------------------------------------------------------------------------
// Settings — a single encrypted row per user, holding the DEK envelope plus
// the encrypted settings payload. PATCH merges whichever fields are supplied.
// ---------------------------------------------------------------------------

dataRoutes.get('/settings', requireAuth, async (c) => {
  const userId = c.get('user').id;
  const rows = await sql`select * from user_settings where user_id = ${userId} limit 1`;
  return c.json(rows[0] ?? null);
});

dataRoutes.patch('/settings', requireAuth, async (c) => {
  const userId = c.get('user').id;
  const input = await json(c);

  const encryptedData = typeof input.encrypted_data === 'string' ? input.encrypted_data : null;
  const encryptedDek = typeof input.encrypted_dek === 'string' ? input.encrypted_dek : null;
  const kekSalt = typeof input.kek_salt === 'string' ? input.kek_salt : null;
  const kekIterations = typeof input.kek_iterations === 'number' ? input.kek_iterations : null;
  const recoveryHash = typeof input.recovery_hash === 'string' ? input.recovery_hash : null;

  const rows = await sql`
    insert into user_settings (
      user_id, encrypted_data, encrypted_dek, kek_salt, kek_iterations, recovery_hash
    ) values (
      ${userId},
      ${encryptedData ?? ''},
      ${encryptedDek ?? ''},
      ${kekSalt ?? ''},
      ${kekIterations ?? 310000},
      ${recoveryHash}
    )
    on conflict (user_id) do update set
      encrypted_data = coalesce(${encryptedData}, user_settings.encrypted_data),
      encrypted_dek  = coalesce(${encryptedDek}, user_settings.encrypted_dek),
      kek_salt       = coalesce(${kekSalt}, user_settings.kek_salt),
      kek_iterations = coalesce(${kekIterations}, user_settings.kek_iterations),
      recovery_hash  = coalesce(${recoveryHash}, user_settings.recovery_hash),
      updated_at     = now()
    returning *
  `;
  return c.json(rows[0]);
});
