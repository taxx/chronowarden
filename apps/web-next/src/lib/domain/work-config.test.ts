import { describe, expect, test } from 'vitest';

import { expectedMinutesForDate, type WorkConfig, isoWeekNumber } from './work-config';

describe('isoWeekNumber', () => {
  // Reference values from Python's datetime.isocalendar() (ISO 8601).
  // Straddle DST transitions (Europe/Sweden) and ISO-year boundaries.
  const cases: Array<[number, number, number, number]> = [
    [2026, 9, 14, 38],
    [2026, 9, 20, 38],
    [2026, 10, 25, 43],
    [2026, 3, 30, 14],
    [2023, 1, 1, 52],
    [2023, 1, 2, 1],
    [2025, 12, 29, 1],
    [2026, 12, 31, 53],
    [2024, 1, 1, 1],
    [2024, 12, 31, 1],
    [2023, 10, 26, 43],
  ];

  for (const [year, month, day, expected] of cases) {
    test(`${year}-${month}-${day} is ISO week ${expected}`, () => {
      expect(isoWeekNumber(new Date(year, month - 1, day))).toBe(expected);
    });
  }
});

describe('expectedMinutesForDate', () => {
  const config: WorkConfig = {
    defaultExpectedMinutes: 480,
    reducedExpectedMinutes: 435,
    reducedStartWeek: 20,
    reducedEndWeek: 37,
  };

  test('uses reduced minutes inside the period', () => {
    expect(expectedMinutesForDate(config, new Date(2026, 6, 27))).toBe(435);
  });

  test('uses default minutes after the period ends', () => {
    expect(expectedMinutesForDate(config, new Date(2026, 8, 14))).toBe(480);
  });

  test('uses default minutes before the period starts', () => {
    expect(expectedMinutesForDate(config, new Date(2026, 2, 2))).toBe(480);
  });

  test('falls back to default without a reduced period', () => {
    expect(expectedMinutesForDate({ defaultExpectedMinutes: 480 }, new Date(2026, 8, 14))).toBe(480);
  });
});
