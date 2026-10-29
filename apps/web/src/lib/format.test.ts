import { describe, expect, test } from 'vitest';

import {
  formatDurationMinutes,
  formatMins,
  formatOvertimeStatus,
  formatSignedMinutes,
} from './format';

describe('formatMins', () => {
  test('formats magnitudes', () => {
    expect(formatMins(0)).toBe('0 min');
    expect(formatMins(45)).toBe('45 min');
    expect(formatMins(480)).toBe('8h');
    expect(formatMins(510)).toBe('8h 30m');
  });

  test('drops the sign', () => {
    expect(formatMins(-45)).toBe('45 min');
  });
});

describe('formatDurationMinutes', () => {
  test('formats signed durations without a leading plus', () => {
    expect(formatDurationMinutes(0)).toBe('0 min');
    expect(formatDurationMinutes(45)).toBe('45 min');
    expect(formatDurationMinutes(480)).toBe('8h');
    expect(formatDurationMinutes(510)).toBe('8h 30m');
    expect(formatDurationMinutes(-45)).toBe('-45 min');
    expect(formatDurationMinutes(-480)).toBe('-8h');
  });
});

describe('formatSignedMinutes', () => {
  test('always prefixes a sign', () => {
    expect(formatSignedMinutes(0)).toBe('+0 min');
    expect(formatSignedMinutes(510)).toBe('+8h 30m');
    expect(formatSignedMinutes(-45)).toBe('-45 min');
  });
});

describe('formatOvertimeStatus', () => {
  test('uses a tick when exactly on target', () => {
    expect(formatOvertimeStatus(0)).toBe('✓');
    expect(formatOvertimeStatus(60)).toBe('+1h');
  });
});
