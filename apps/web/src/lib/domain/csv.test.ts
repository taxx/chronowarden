import { describe, expect, test } from 'vitest';

import { parseCsvTimeLogs, timeLogsToCsv } from './csv';
import type { TimeLog } from './time-log';

const log: TimeLog = {
  date: '2026-01-15',
  startTime: '08:00:00',
  endTime: '16:30:00',
  expectedMinutes: 480,
  lunchMinutes: 30,
  nonWorkMinutes: 15,
  flexMinutes: 0,
  morningOverheadMinutes: 20,
  morningProductiveCommuteMinutes: 5,
  eveningOverheadMinutes: 40,
  eveningProductiveCommuteMinutes: 5,
  overtimeMinutes: 0,
  note: 'Office, quiet',
};

describe('timeLogsToCsv', () => {
  test('writes the header and escapes notes with commas', () => {
    const csv = timeLogsToCsv([log]);
    const [header, row] = csv.trim().split('\n');
    expect(header).toBe(
      'date,start_time,end_time,expected_minutes,overhead_minutes,lunch_minutes,productive_commute_minutes,note,non_work_minutes',
    );
    expect(row).toContain('"Office, quiet"');
    expect(row!.endsWith(',15')).toBe(true); // non-work is the last column
  });
});

describe('parseCsvTimeLogs', () => {
  const header = 'date,start_time,end_time,expected_minutes,overhead_minutes,lunch_minutes,productive_commute_minutes,note';

  test('parses a valid row and splits totals 50/50', () => {
    const result = parseCsvTimeLogs(`${header}\n2026-01-15,08:00:00,16:30:00,480,61,30,9,Office day`);
    expect(result.errors).toEqual([]);
    const parsed = result.imported[0]!;
    expect(parsed.date).toBe('2026-01-15');
    expect(parsed.morningOverheadMinutes).toBe(30);
    expect(parsed.eveningOverheadMinutes).toBe(31);
    expect(parsed.morningProductiveCommuteMinutes).toBe(4);
    expect(parsed.eveningProductiveCommuteMinutes).toBe(5);
    expect(parsed.nonWorkMinutes).toBe(0); // absent column defaults to 0
  });

  test('honours a quoted note containing a comma', () => {
    const result = parseCsvTimeLogs(`${header}\n2026-01-15,08:00:00,,480,0,0,0,"Office, quiet"`);
    expect(result.imported[0]!.note).toBe('Office, quiet');
  });

  test('rejects a missing header', () => {
    const result = parseCsvTimeLogs('2026-01-15,08:00:00,,480,0');
    expect(result.imported).toEqual([]);
    expect(result.errors[0]).toContain('Missing header row');
  });

  test('rejects invalid dates and times', () => {
    const bad = parseCsvTimeLogs(`${header}\n15/01/2026,08:00:00,,480,0`);
    expect(bad.errors[0]).toContain('Invalid date');

    const badTime = parseCsvTimeLogs(`${header}\n2026-01-15,8:00,,480,0`);
    expect(badTime.errors[0]).toContain('Invalid start_time');
  });

  test('rejects non-numeric expected minutes', () => {
    const result = parseCsvTimeLogs(`${header}\n2026-01-15,08:00:00,,abc,0`);
    expect(result.errors[0]).toContain('Invalid expected_minutes');
  });

  test('skips dates that already exist', () => {
    const result = parseCsvTimeLogs(`${header}\n2026-01-15,08:00:00,,480,0`, new Set(['2026-01-15']));
    expect(result.imported).toEqual([]);
    expect(result.skipped).toBe(1);
  });

  test('round-trips through export and import', () => {
    const csv = timeLogsToCsv([log]);
    const result = parseCsvTimeLogs(csv);
    expect(result.errors).toEqual([]);
    const parsed = result.imported[0]!;
    expect(parsed.date).toBe(log.date);
    expect(parsed.startTime).toBe(log.startTime);
    expect(parsed.endTime).toBe(log.endTime);
    expect(parsed.expectedMinutes).toBe(log.expectedMinutes);
    expect(parsed.lunchMinutes).toBe(log.lunchMinutes);
    expect(parsed.nonWorkMinutes).toBe(log.nonWorkMinutes);
    expect(parsed.note).toBe(log.note);
  });
});
