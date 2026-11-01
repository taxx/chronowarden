import { Hono } from 'hono';
import type { AppEnv } from '../auth.ts';
import { requireAuth } from '../auth.ts';
import { sql } from '../db.ts';
import { ApiError } from '../errors.ts';
import {
  MAX_ENCRYPTED,
  MAX_ENVELOPE_FIELD,
  MAX_KEK_ITERATIONS,
  MAX_NAME,
  MIN_KEK_ITERATIONS,
  optionalInteger,
  optionalText,
  requireDate,
  requireString,
} from '../validation.ts';

export const backupRoutes = new Hono<AppEnv>();


const FORMAT = 'chronowarden-backup';
const VERSION = 1;
/** Hard cap on rows restored in one bundle (the request body is also capped). */
const MAX_IMPORT_ROWS = 5_000;
const IMPORT_CHUNK_SIZE = 500;

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
  if (!Array.isArray(bundle.time_logs) && bundle.time_logs !== undefined) {
    throw ApiError.badRequest('INVALID_BUNDLE', 'time_logs must be an array');
  }
  if (!Array.isArray(bundle.travel_presets) && bundle.travel_presets !== undefined) {
    throw ApiError.badRequest('INVALID_BUNDLE', 'travel_presets must be an array');
  }
  const logs = Array.isArray(bundle.time_logs) ? bundle.time_logs : [];
  const presets = Array.isArray(bundle.travel_presets) ? bundle.travel_presets : [];
  if (logs.length > MAX_IMPORT_ROWS || presets.length > MAX_IMPORT_ROWS) {
    throw ApiError.badRequest('BUNDLE_TOO_LARGE', `A backup may contain at most ${MAX_IMPORT_ROWS} rows per table`);
  }

  const settingsEncrypted = requireString(
    bundle.settings?.encrypted_data ?? '',
    'settings.encrypted_data',
    MAX_ENCRYPTED,
  );
  const encryptedDek = requireString(envelope.encrypted_dek ?? '', 'envelope.encrypted_dek', MAX_ENVELOPE_FIELD);
  const kekSalt = requireString(envelope.kek_salt ?? '', 'envelope.kek_salt', MAX_ENVELOPE_FIELD);
  const kekIterations =
    optionalInteger(envelope.kek_iterations, 'envelope.kek_iterations', MIN_KEK_ITERATIONS, MAX_KEK_ITERATIONS) ??
    310_000;
  const recoveryHash = optionalText(envelope.recovery_hash, 'envelope.recovery_hash', MAX_ENVELOPE_FIELD);

  // Validate every row before writing anything, so a malformed bundle cannot
  // partially replace the account's data.
  const logRows = logs.map((log: any, index: number) => ({
    user_id: userId,
    date: requireDate(log?.date ?? undefined),
    encrypted_data: requireString(log?.encrypted_data, `time_logs[${index}].encrypted_data`, MAX_ENCRYPTED),
  }));
  const presetRows = presets.map((preset: any, index: number) => ({
    user_id: userId,
    name: requireString(preset?.name, `travel_presets[${index}].name`, MAX_NAME),
    encrypted_data: requireString(preset?.encrypted_data, `travel_presets[${index}].encrypted_data`, MAX_ENCRYPTED),
  }));

  await sql.begin(async (tx) => {
    await tx`
      insert into user_settings (
        user_id, encrypted_data, encrypted_dek, kek_salt, kek_iterations, recovery_hash
      ) values (
        ${userId},
        ${settingsEncrypted},
        ${encryptedDek},
        ${kekSalt},
        ${kekIterations},
        ${recoveryHash}
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
    for (let i = 0; i < logRows.length; i += IMPORT_CHUNK_SIZE) {
      const chunk = logRows.slice(i, i + IMPORT_CHUNK_SIZE);
      await tx`insert into time_logs ${tx(chunk, 'user_id', 'date', 'encrypted_data')}`;
    }

    await tx`delete from travel_presets where user_id = ${userId}`;
    for (let i = 0; i < presetRows.length; i += IMPORT_CHUNK_SIZE) {
      const chunk = presetRows.slice(i, i + IMPORT_CHUNK_SIZE);
      await tx`insert into travel_presets ${tx(chunk, 'user_id', 'name', 'encrypted_data')}`;
    }
  });

  return c.json({
    imported: { time_logs: logs.length, travel_presets: presets.length },
  });
});
