import { describe, expect, test } from 'vitest';

import {
  calculateLeaveTime,
  calculateOvertimeMinutes,
  combineDateAndTime,
  copyWithTimeLog,
  leaveTime,
  leaveTimeWithBreaks,
  overheadMinutes,
  timeLogFromJson,
  timeLogToJson,
  totalExpectedMinutes,
  type TimeLog,
} from './time-log';

function log(overrides: Partial<TimeLog> = {}): TimeLog {
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

const hm = (d: Date) => `${d.getHours()}:${String(d.getMinutes()).padStart(2, '0')}`;

describe('leave time', () => {
  test('no commute: start + expected', () => {
    expect(hm(leaveTime(log()))).toBe('16:00');
  });

  test('productive commute subtracts the evening portion', () => {
    // 480 + 20 (morning overhead) − 40 (evening productive) = 460 → 15:40
    expect(hm(leaveTime(log({ morningOverheadMinutes: 20, eveningProductiveCommuteMinutes: 40 })))).toBe(
      '15:40',
    );
  });

  test('odd overhead minutes', () => {
    // 480 + 15 − 25 = 470 → 15:50
    expect(hm(leaveTime(log({ morningOverheadMinutes: 15, eveningProductiveCommuteMinutes: 25 })))).toBe(
      '15:50',
    );
  });

  test('calculateLeaveTime matches the getter', () => {
    const entry = log({ morningOverheadMinutes: 20, eveningProductiveCommuteMinutes: 40 });
    expect(calculateLeaveTime(entry, combineDateAndTime(entry.date, entry.startTime)).getTime()).toBe(
      leaveTime(entry).getTime(),
    );
  });

  test('lunch and non-work extend the leave time', () => {
    expect(hm(leaveTime(log({ lunchMinutes: 30 })))).toBe('16:30');
    expect(hm(leaveTime(log({ nonWorkMinutes: 45 })))).toBe('16:45');
  });

  test('flex withdrawal moves the leave time earlier', () => {
    expect(hm(leaveTime(log({ flexMinutes: 60 })))).toBe('15:00');
  });

  test('leaveTimeWithBreaks overrides lunch and non-work independently', () => {
    const entry = log({ lunchMinutes: 30, nonWorkMinutes: 15 });
    // 480 + 60 lunch + 15 non-work = 555 → 17:15
    expect(hm(leaveTimeWithBreaks(entry, { lunchMinutes: 60 }))).toBe('17:15');
    // 480 + 30 lunch + 60 non-work = 570 → 17:30
    expect(hm(leaveTimeWithBreaks(entry, { nonWorkMinutes: 60 }))).toBe('17:30');
  });
});

describe('overtime', () => {
  test('no end time → 0', () => {
    expect(calculateOvertimeMinutes(log())).toBe(0);
  });

  test('exactly on target → 0', () => {
    expect(calculateOvertimeMinutes(log({ endTime: '16:00:00' }))).toBe(0);
  });

  test('overtime worked → positive', () => {
    expect(calculateOvertimeMinutes(log({ endTime: '16:30:00' }))).toBe(30);
  });

  test('left early → negative', () => {
    expect(calculateOvertimeMinutes(log({ endTime: '15:30:00' }))).toBe(-30);
  });

  test('lunch and non-work are subtracted', () => {
    expect(calculateOvertimeMinutes(log({ endTime: '16:45:00', lunchMinutes: 30, nonWorkMinutes: 15 }))).toBe(
      0,
    );
  });

  test('overhead is included in the expected total', () => {
    expect(
      calculateOvertimeMinutes(log({ endTime: '16:50:00', morningOverheadMinutes: 25, eveningOverheadMinutes: 25 })),
    ).toBe(0);
  });

  test('flex is ignored for final overtime', () => {
    expect(calculateOvertimeMinutes(log({ endTime: '16:00:00', flexMinutes: 60 }))).toBe(0);
  });

  test('totalExpectedMinutes sums expected and total overhead', () => {
    expect(totalExpectedMinutes(log({ morningOverheadMinutes: 25, eveningOverheadMinutes: 25 }))).toBe(530);
  });
});

describe('JSON', () => {
  test('parses per-direction fields', () => {
    const entry = timeLogFromJson({
      id: 'a',
      date: '2026-01-15',
      start_time: '08:00:00',
      expected_minutes: 480,
      overtime_minutes: 0,
      morning_overhead_minutes: 10,
      evening_overhead_minutes: 15,
      morning_productive_commute_minutes: 20,
      evening_productive_commute_minutes: 10,
    });
    expect(entry.morningOverheadMinutes).toBe(10);
    expect(entry.eveningOverheadMinutes).toBe(15);
    expect(overheadMinutes(entry)).toBe(25);
  });

  test('falls back to legacy totals, splitting 50/50', () => {
    const entry = timeLogFromJson({
      date: '2026-01-15',
      start_time: '08:00:00',
      expected_minutes: 480,
      overtime_minutes: 0,
      overhead_minutes: 31,
      productive_commute_minutes: 10,
    });
    expect(entry.morningOverheadMinutes).toBe(15);
    expect(entry.eveningOverheadMinutes).toBe(16);
    expect(entry.morningProductiveCommuteMinutes).toBe(5);
    expect(entry.eveningProductiveCommuteMinutes).toBe(5);
  });

  test('missing non_work_minutes defaults to 0', () => {
    const entry = timeLogFromJson({
      date: '2026-01-15',
      start_time: '08:00:00',
      expected_minutes: 480,
      overtime_minutes: 0,
      overhead_minutes: 0,
    });
    expect(entry.nonWorkMinutes).toBe(0);
  });

  test('round-trips', () => {
    const entry = log({ nonWorkMinutes: 75 });
    const json = timeLogToJson(entry);
    expect(json['non_work_minutes']).toBe(75);
    expect(timeLogFromJson(json).nonWorkMinutes).toBe(75);
  });
});

describe('copyWithTimeLog', () => {
  test('replaces only the given fields', () => {
    const original = log({ morningOverheadMinutes: 25, eveningOverheadMinutes: 25 });
    const copy = copyWithTimeLog(original, { eveningOverheadMinutes: 50 });
    expect(copy.morningOverheadMinutes).toBe(25);
    expect(copy.eveningOverheadMinutes).toBe(50);
    expect(original.eveningOverheadMinutes).toBe(25);
  });
});
