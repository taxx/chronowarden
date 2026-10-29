import { describe, expect, test } from 'vitest';

import { travelPresetFromJson, travelPresetToJson, findPresetForLog, type TravelPreset } from './travel-preset';
import type { TimeLog } from './time-log';

const preset: TravelPreset = {
  name: 'Train',
  morningOverheadMinutes: 10,
  morningProductiveCommuteMinutes: 20,
  eveningOverheadMinutes: 15,
  eveningProductiveCommuteMinutes: 5,
  commuteMode: 'transit',
};

const log = {
  date: '2026-01-15',
  startTime: '08:00:00',
  expectedMinutes: 480,
  morningOverheadMinutes: 10,
  morningProductiveCommuteMinutes: 20,
  eveningOverheadMinutes: 15,
  eveningProductiveCommuteMinutes: 5,
} as TimeLog;

describe('travelPresetFromJson', () => {
  test('parses per-direction fields', () => {
    const parsed = travelPresetFromJson({ name: 'Train', morning_overhead_minutes: 10, evening_overhead_minutes: 15 });
    expect(parsed.morningOverheadMinutes).toBe(10);
    expect(parsed.eveningOverheadMinutes).toBe(15);
  });

  test('falls back to legacy totals split 50/50', () => {
    const parsed = travelPresetFromJson({ name: 'Old', default_overhead_minutes: 31, productive_commute_minutes: 10 });
    expect(parsed.morningOverheadMinutes).toBe(15);
    expect(parsed.eveningOverheadMinutes).toBe(16);
  });

  test('defaults commute mode to none', () => {
    expect(travelPresetFromJson({ name: 'x' }).commuteMode).toBe('none');
  });
});

describe('preset matching', () => {
  test('matches a log with identical per-direction values', () => {
    expect(findPresetForLog([preset], log)).toBe(preset);
  });

  test('does not match a different commute profile', () => {
    const other = { ...log, morningOverheadMinutes: 99 };
    expect(findPresetForLog([preset], other)).toBeNull();
  });
});

describe('round-trip', () => {
  test('toJson carries both per-direction and legacy fields', () => {
    const json = travelPresetToJson(preset);
    expect(json['morning_overhead_minutes']).toBe(10);
    expect(json['default_overhead_minutes']).toBe(25);
    expect(json['productive_commute_minutes']).toBe(25);
    expect(travelPresetFromJson(json).name).toBe('Train');
  });
});
