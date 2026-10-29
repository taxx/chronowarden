import { describe, expect, test } from 'vitest';

import type { TimeLog } from './time-log';
import { computeAvgGrowthWeekly, computeProjection } from './projection';

function log(date: string, overtimeMinutes: number, open = false): TimeLog {
  return {
    date,
    startTime: '08:00:00',
    endTime: open ? null : '16:00:00',
    expectedMinutes: 480,
    lunchMinutes: 0,
    nonWorkMinutes: 0,
    flexMinutes: 0,
    morningOverheadMinutes: 0,
    morningProductiveCommuteMinutes: 0,
    eveningOverheadMinutes: 0,
    eveningProductiveCommuteMinutes: 0,
    overtimeMinutes,
    ...(open ? {} : {}),
  };
}

const today = new Date(2026, 0, 20); // 2026-01-20

describe('computeAvgGrowthWeekly', () => {
  test('returns 0 with too few completed days', () => {
    const logs = [log('2026-01-05', 30), log('2026-01-06', 30)];
    expect(computeAvgGrowthWeekly(logs, today)).toBe(0);
  });

  test('averages recent completed days and scales to a week', () => {
    const logs = [
      log('2026-01-05', 30),
      log('2026-01-06', 30),
      log('2026-01-07', 30),
      log('2026-01-08', 30),
      log('2026-01-09', 30),
    ];
    // avg 30/day → 150/week
    expect(computeAvgGrowthWeekly(logs, today)).toBe(150);
  });

  test('ignores the open day and days outside the window', () => {
    const logs = [
      log('2025-10-01', 999), // too old
      log('2026-01-05', 30),
      log('2026-01-06', 30),
      log('2026-01-07', 30),
      log('2026-01-08', 30),
      log('2026-01-09', 30),
      log('2026-01-20', 600, true), // still open
    ];
    expect(computeAvgGrowthWeekly(logs, today)).toBe(150);
  });
});

describe('computeProjection', () => {
  test('computes weeks to zero and a zero date', () => {
    const logs = [
      log('2026-01-05', 100),
      log('2026-01-06', 100),
      log('2026-01-07', 100),
      log('2026-01-08', 100),
      log('2026-01-09', 100),
    ];
    const result = computeProjection(logs, 30, false, today);
    expect(result.currentBalance).toBe(500);
    // 500 / (30*5) = 3.33 → 4 weeks
    expect(result.weeksToZero).toBe(4);
    expect(result.zeroDate).not.toBeNull();
  });

  test('reports no depletion when flex is zero', () => {
    const logs = [log('2026-01-05', 100)];
    const result = computeProjection(logs, 0, false, today);
    expect(result.weeksToZero).toBe(0);
    expect(result.zeroDate).toBeNull();
  });

  test('builds historical points then a projection that reaches zero', () => {
    const logs = [log('2026-01-05', 100), log('2026-01-06', 100)];
    const result = computeProjection(logs, 60, false, today);
    const historical = result.points.filter((p) => p.actual !== null);
    const projected = result.points.filter((p) => p.projected !== null);
    expect(historical.length).toBe(3); // 2 days + the "now" connection point
    expect(projected[projected.length - 1]!.projected).toBe(0);
  });
});
