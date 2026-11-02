import { describe, expect, test } from 'vitest';

import {
  formatCompactMinutes,
  formatDurationMinutes,
  formatMins,
  formatOvertimeStatus,
  formatSignedMinutes,
  overtimeBadgeVariant,
  overtimeTextClass,
  overtimeTone,
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

describe('overtime tone (time-warding semantics)', () => {
  test('working less is good, working more is flagged', () => {
    expect(overtimeTone(-30)).toBe('success');
    expect(overtimeTone(30)).toBe('warning');
    expect(overtimeTone(0)).toBe('neutral');
  });

  test('maps to text classes and badge variants', () => {
    expect(overtimeTextClass(-30)).toBe('text-success');
    expect(overtimeTextClass(30)).toBe('text-warning');
    expect(overtimeTextClass(0)).toBe('text-muted-foreground');
    expect(overtimeBadgeVariant(-30)).toBe('success');
    expect(overtimeBadgeVariant(30)).toBe('warning');
    expect(overtimeBadgeVariant(0)).toBe('secondary');
  });
});

describe('formatCompactMinutes', () => {
  test('stays short enough for a narrow calendar cell', () => {
    expect(formatCompactMinutes(0)).toBe('0');
    expect(formatCompactMinutes(-30)).toBe('-30m');
    expect(formatCompactMinutes(45)).toBe('+45m');
    expect(formatCompactMinutes(-120)).toBe('-2h');
    expect(formatCompactMinutes(90)).toBe('+1:30');
    expect(formatCompactMinutes(-7 * 60 - 5)).toBe('-7:05');
  });
});
