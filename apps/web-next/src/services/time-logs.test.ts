import { beforeEach, describe, expect, test, vi } from 'vitest';

import { timeLogsApi } from '../api/time-logs';
import { decryptString, encryptString, generateDek } from '../lib/crypto';
import { toDateStr } from '../lib/date';
import type { TimeLog } from '../lib/domain/time-log';
import { createTimeLog, listTimeLogs, todayTimeLog, updateTimeLog } from './time-logs';

vi.mock('../api/time-logs', () => ({
  timeLogsApi: {
    list: vi.fn(),
    get: vi.fn(),
    create: vi.fn(),
    update: vi.fn(),
    remove: vi.fn(),
  },
}));

const mocked = vi.mocked(timeLogsApi);

function baseLog(overrides: Partial<TimeLog> = {}): TimeLog {
  return {
    date: '2026-01-15',
    startTime: '08:00:00',
    expectedMinutes: 480,
    lunchMinutes: 0,
    nonWorkMinutes: 0,
    flexMinutes: 0,
    morningOverheadMinutes: 0,
    morningProductiveCommuteMinutes: 0,
    eveningOverheadMinutes: 0,
    eveningProductiveCommuteMinutes: 0,
    overtimeMinutes: 0,
    ...overrides,
  };
}

beforeEach(() => vi.clearAllMocks());

describe('createTimeLog', () => {
  test('encrypts a payload without envelope fields and returns the decrypted log', async () => {
    const dek = generateDek();
    mocked.create.mockImplementation(async (body) => ({
      id: 'row-1',
      user_id: 'user-1',
      date: body.date,
      encrypted_data: body.encrypted_data,
      created_at: '2026-01-15T07:00:00Z',
    }));

    const log = await createTimeLog(baseLog({ startTime: '08:15:00', note: 'hello' }), dek);

    expect(log.id).toBe('row-1');
    expect(log.userId).toBe('user-1');
    expect(log.startTime).toBe('08:15:00');
    expect(log.note).toBe('hello');

    const ciphertext = mocked.create.mock.calls[0]![0].encrypted_data;
    const payload = JSON.parse(await decryptString(ciphertext, dek)) as Record<string, unknown>;
    expect(payload['start_time']).toBe('08:15:00');
    expect(payload['user_id']).toBeUndefined();
    expect(payload['id']).toBeUndefined();
    expect(payload['created_at']).toBeUndefined();
  });
});

describe('listTimeLogs', () => {
  test('decrypts rows into domain logs and skips unreadable ones', async () => {
    const dek = generateDek();
    const good = await encryptString(
      JSON.stringify({ start_time: '09:00:00', expected_minutes: 480, overtime_minutes: 15 }),
      dek,
    );

    mocked.list.mockResolvedValue([
      { id: 'a', user_id: 'u', date: '2026-01-16', encrypted_data: good, created_at: '' },
      { id: 'b', user_id: 'u', date: '2026-01-17', encrypted_data: 'not-ciphertext', created_at: '' },
    ]);

    const logs = await listTimeLogs(dek);
    expect(logs).toHaveLength(1);
    expect(logs[0]!.startTime).toBe('09:00:00');
    expect(logs[0]!.overtimeMinutes).toBe(15);
  });

  test('returns nothing without a DEK', async () => {
    const logs = await listTimeLogs(null);
    expect(logs).toEqual([]);
  });
});

describe('updateTimeLog', () => {
  test('merges snake_case fields into the existing encrypted payload', async () => {
    const dek = generateDek();
    const existing = {
      start_time: '08:00:00',
      expected_minutes: 480,
      overtime_minutes: 0,
      lunch_minutes: 0,
    };
    mocked.get.mockResolvedValue({
      id: 'row-1',
      user_id: 'u',
      date: '2026-01-15',
      encrypted_data: await encryptString(JSON.stringify(existing), dek),
      created_at: '',
    });

    let patched = '';
    mocked.update.mockImplementation(async (_id, body) => {
      patched = body.encrypted_data;
      return { id: 'row-1', user_id: 'u', date: '2026-01-15', encrypted_data: patched, created_at: '' };
    });

    await updateTimeLog('row-1', { lunch_minutes: 30, lunch_started_at: null }, dek);

    const merged = JSON.parse(await decryptString(patched, dek)) as Record<string, unknown>;
    expect(merged['lunch_minutes']).toBe(30);
    expect(merged['start_time']).toBe('08:00:00');
    expect(merged['lunch_started_at']).toBeNull();
  });
});

describe('todayTimeLog', () => {
  test('queries the server for today and decrypts the first row', async () => {
    const dek = generateDek();
    const ciphertext = await encryptString(
      JSON.stringify({ start_time: '07:30:00', expected_minutes: 480, overtime_minutes: 0 }),
      dek,
    );
    mocked.list.mockResolvedValue([
      { id: 'today', user_id: 'u', date: toDateStr(new Date()), encrypted_data: ciphertext, created_at: '' },
    ]);

    const log = await todayTimeLog(dek);
    expect(log?.startTime).toBe('07:30:00');
    expect(mocked.list).toHaveBeenCalledWith(toDateStr(new Date()));
  });
});
