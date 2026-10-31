import { describe, expect, test } from 'vitest';

import type { TimeLog } from './time-log';
import { buildTimeBankChart, filterLogsForPeriod, summarizePeriod } from './time-bank-chart';

function log(date: string, overtimeMinutes: number, overrides: Partial<TimeLog> = {}): TimeLog {
  return {
    date,
    startTime: '08:00:00',
    endTime: '16:00:00',
    expectedMinutes: 480,
    lunchMinutes: 0,
    nonWorkMinutes: 0,
    flexMinutes: 0,
    morningOverheadMinutes: 30,
    morningProductiveCommuteMinutes: 0,
    eveningOverheadMinutes: 0,
    eveningProductiveCommuteMinutes: 0,
    overtimeMinutes,
    ...overrides,
  };
}

const weekRef = new Date(2026, 0, 14); // Wed 2026-01-14 → week Mon 12th–Sun 18th

describe('buildTimeBankChart', () => {
  const logs = [
    log('2026-01-05', 60), // before the week → baseline
    log('2026-01-12', -30),
    log('2026-01-13', 45),
    log('2026-01-14', -60),
  ];

  test('baseline is the balance before the period', () => {
    const data = buildTimeBankChart(logs, 'week', weekRef, true);
    expect(data.baseline).toBe(60);
  });

  test('bars are the per-day relative change, trend is the running deviation', () => {
    const data = buildTimeBankChart(logs, 'week', weekRef, true);
    expect(data.points.map((p) => p.delta)).toEqual([-30, 45, -60]);
    expect(data.points.map((p) => p.deviation)).toEqual([-30, 15, -45]);
    expect(data.endBalance).toBe(15);
    expect(data.netChange).toBe(-45);
  });

  test('year view aggregates by month', () => {
    const data = buildTimeBankChart(
      [log('2026-01-05', 60), log('2026-03-03', 30), log('2026-03-04', -10)],
      'year',
      new Date(2026, 0, 1),
      true,
    );
    expect(data.points).toHaveLength(12);
    expect(data.points[0]!.delta).toBe(60); // Jan
    expect(data.points[2]!.delta).toBe(20); // Mar
    expect(data.points[11]!.delta).toBe(0); // Dec
  });

  test('returns an empty point set when nothing was logged', () => {
    const data = buildTimeBankChart([], 'week', weekRef, true);
    expect(data.points).toEqual([]);
    expect(data.netChange).toBe(0);
  });
});

describe('filterLogsForPeriod', () => {
  test('hides weekends unless the preference says otherwise', () => {
    const logs = [log('2026-01-12', 0), log('2026-01-17', 0), log('2026-01-18', 0)];
    expect(filterLogsForPeriod(logs, 'week', weekRef, false).map((l) => l.date)).toEqual([
      '2026-01-12',
    ]);
    expect(filterLogsForPeriod(logs, 'week', weekRef, true)).toHaveLength(3);
  });
});

describe('summarizePeriod', () => {
  test('aggregates the period totals', () => {
    const logs = [
      log('2026-01-12', 0),
      log('2026-01-13', 0, { endTime: '17:00:00', overtimeMinutes: 60 }), // 9h gross
    ];
    const summary = summarizePeriod(logs, 'week', weekRef, true);
    expect(summary.daysLogged).toBe(2);
    expect(summary.workedMinutes).toBe(8 * 60 + 9 * 60);
    expect(summary.expectedMinutes).toBe(960);
    expect(summary.overheadBufferMinutes).toBe(60);
    expect(summary.overtimeMinutes).toBe(60);
  });
});
