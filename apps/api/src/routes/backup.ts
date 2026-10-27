import { Hono } from 'hono';
import type { AppEnv } from '../auth.ts';
import { requireAuth } from '../auth.ts';
import { sql } from '../db.ts';
import { ApiError } from '../errors.ts';

export const backupRoutes = new Hono<AppEnv>();


const FORMAT = 'chronowarden-backup';
const VERSION = 1;

/**
 * Full portable backup for the authenticated user.
 *
 * Includes the encryption envelope (wrapped DEK + KDF parameters + recovery
 * hash) because the DEK is random: without it, the same passphrase on another
 * instance would derive a different key and the ciphertext would be
 * undecryptable. The API never sees plaintext.
 */
backupRoutes.get('/export', requireAuth, async (c) => {
  const userId = c.get('user').id;

  const settingsRows = await sql`select * from user_settings where user_id = ${userId} limit 1`;
  const settings = settingsRows[0] ?? null;
  const logs = await sql`select date::text as date, encrypted_data from time_logs where user_id = ${userId} order by date`;
  const presets = await sql`select name, encrypted_data from travel_presets where user_id = ${userId} order by name`;

  return c.json({
    format: FORMAT,
    version: VERSION,
    exported_at: new Date().toISOString(),
    user: { email: c.get('user').email, full_name: c.get('user').full_name },
    envelope: settings
      ? {
          encrypted_dek: settings.encrypted_dek ?? '',
          kek_salt: settings.kek_salt ?? '',
          kek_iterations: settings.kek_iterations ?? 310000,
          recovery_hash: settings.recovery_hash ?? null,
        }
      : null,
    settings: { encrypted_data: settings?.encrypted_data ?? '' },
    time_logs: logs,
    travel_presets: presets,
  });
});

/**
 * Restores a bundle into the authenticated account, replacing its data.
 *
 * The client is expected to have created the account first; this endpoint only
 * stores ciphertext and envelope metadata, so the user must then unlock with
 * the passphrase that produced the envelope.
 */
backupRoutes.post('/import', requireAuth, async (c) => {
  const userId = c.get('user').id;
  const bundle = (await c.req.json().catch(() => null)) as Record<string, any> | null;

  if (!bundle || bundle.format !== FORMAT) {
    throw ApiError.badRequest('INVALID_BUNDLE', 'This is not a ChronoWarden backup file');
  }
  if (Number(bundle.version) > VERSION) {
    throw ApiError.badRequest('UNSUPPORTED_BUNDLE', 'This backup was made by a newer version of ChronoWarden');
  }

  const envelope = bundle.envelope ?? {};
  const logs = Array.isArray(bundle.time_logs) ? bundle.time_logs : [];
  const presets = Array.isArray(bundle.travel_presets) ? bundle.travel_presets : [];

  await sql.begin(async (tx) => {
    await tx`
      insert into user_settings (
        user_id, encrypted_data, encrypted_dek, kek_salt, kek_iterations, recovery_hash
      ) values (
        ${userId},
        ${String(bundle.settings?.encrypted_data ?? '')},
        ${String(envelope.encrypted_dek ?? '')},
        ${String(envelope.kek_salt ?? '')},
        ${Number(envelope.kek_iterations) || 310000},
        ${envelope.recovery_hash ? String(envelope.recovery_hash) : null}
      )
      on conflict (user_id) do update set
        encrypted_data = excluded.encrypted_data,
        encrypted_dek  = excluded.encrypted_dek,
        kek_salt       = excluded.kek_salt,
        kek_iterations = excluded.kek_iterations,
        recovery_hash  = excluded.recovery_hash,
        updated_at     = now()
    `;

    await tx`delete from time_logs where user_id = ${userId}`;
    for (const log of logs) {
      if (!log?.date || typeof log.encrypted_data !== 'string') continue;
      await tx`
        insert into time_logs (user_id, date, encrypted_data)
        values (${userId}, ${String(log.date)}, ${log.encrypted_data})
      `;
    }

    await tx`delete from travel_presets where user_id = ${userId}`;
    for (const preset of presets) {
      if (!preset?.name || typeof preset.encrypted_data !== 'string') continue;
      await tx`
        insert into travel_presets (user_id, name, encrypted_data)
        values (${userId}, ${String(preset.name)}, ${preset.encrypted_data})
      `;
    }
  });

  return c.json({
    imported: { time_logs: logs.length, travel_presets: presets.length },
  });
});
