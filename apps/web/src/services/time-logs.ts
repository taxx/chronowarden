import { timeLogsApi } from '../api/time-logs';
import type { TimeLogRow } from '../api/types';
import { decryptString, encryptString } from '../lib/crypto';
import { toDateStr } from '../lib/date';
import { timeLogFromJson, timeLogToJson, type TimeLog } from '../lib/domain/time-log';

/** Field names as stored in the encrypted payload (snake_case). */
export type TimeLogPatch = Record<string, unknown>;

/** Decrypt an API row into a domain log (or null when unreadable). */
export async function decryptTimeLogRow(
  row: TimeLogRow,
  dek: Uint8Array | null,
): Promise<TimeLog | null> {
  if (!dek || !row.encrypted_data) return null;
  try {
    const json = JSON.parse(await decryptString(row.encrypted_data, dek)) as Record<string, unknown>;
    json['id'] = row.id;
    json['user_id'] = row.user_id;
    json['date'] = row.date;
    json['created_at'] = row.created_at;
    return timeLogFromJson(json);
  } catch {
    return null;
  }
}

/** The payload that gets encrypted for a brand-new log. */
function newLogPayload(log: TimeLog): Record<string, unknown> {
  const json = timeLogToJson(log);
  delete json['id'];
  delete json['user_id'];
  delete json['created_at'];
  return json;
}

export async function listTimeLogs(dek: Uint8Array | null): Promise<TimeLog[]> {
  const rows = await timeLogsApi.list();
  const logs: TimeLog[] = [];
  for (const row of rows) {
    const log = await decryptTimeLogRow(row, dek);
    if (log) logs.push(log);
  }
  return logs;
}

export async function todayTimeLog(dek: Uint8Array | null): Promise<TimeLog | null> {
  const rows = await timeLogsApi.list(toDateStr(new Date()));
  if (rows.length === 0) return null;
  return decryptTimeLogRow(rows[0]!, dek);
}

export async function createTimeLog(log: TimeLog, dek: Uint8Array): Promise<TimeLog> {
  const ciphertext = await encryptString(JSON.stringify(newLogPayload(log)), dek);
  const row = await timeLogsApi.create({ date: log.date, encrypted_data: ciphertext });
  const decrypted = await decryptTimeLogRow(row, dek);
  if (!decrypted) throw new Error('Failed to decrypt the inserted time log');
  return decrypted;
}

/** Merge snake_case [fields] into the encrypted payload of an existing log. */
export async function updateTimeLog(
  id: string,
  fields: TimeLogPatch,
  dek: Uint8Array,
): Promise<void> {
  const row = await timeLogsApi.get(id);
  if (!row.encrypted_data) return;

  const existing = JSON.parse(await decryptString(row.encrypted_data, dek)) as Record<string, unknown>;
  delete existing['id'];
  delete existing['user_id'];
  delete existing['date'];
  delete existing['created_at'];
  Object.assign(existing, fields);

  const ciphertext = await encryptString(JSON.stringify(existing), dek);
  await timeLogsApi.update(id, { encrypted_data: ciphertext });
}

export async function deleteTimeLog(id: string): Promise<void> {
  await timeLogsApi.remove(id);
}
