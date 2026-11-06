import { describe, expect, test } from 'vitest';

import { evaluateLeaveAlert } from './leave-alert';

const base = {
  thresholdMinutes: 30,
  dismissed: false,
  snoozed: false,
  wrapUpAlreadyAlerted: false,
  overtimeAlreadyAlerted: false,
};

describe('evaluateLeaveAlert', () => {
  test('returns no alert before the threshold', () => {
    expect(evaluateLeaveAlert({ ...base, remainingMinutes: 31 })).toBeNull();
  });

  test('returns a wrap-up alert at the threshold boundary', () => {
    expect(evaluateLeaveAlert({ ...base, remainingMinutes: 30 })).toEqual({
      kind: 'wrapUp',
      remainingMinutes: 30,
    });
    expect(evaluateLeaveAlert({ ...base, remainingMinutes: 0 })).toEqual({
      kind: 'wrapUp',
      remainingMinutes: 0,
    });
  });

  test('returns an overtime alert up to 60 minutes past leave', () => {
    expect(evaluateLeaveAlert({ ...base, remainingMinutes: -10 })).toEqual({
      kind: 'overtime',
      remainingMinutes: -10,
    });
    expect(evaluateLeaveAlert({ ...base, remainingMinutes: -60 })).toEqual({
      kind: 'overtime',
      remainingMinutes: -60,
    });
  });

  test('stops alerting beyond 60 minutes past leave', () => {
    expect(evaluateLeaveAlert({ ...base, remainingMinutes: -61 })).toBeNull();
  });

  test('suppresses alerts when dismissed or snoozed', () => {
    expect(evaluateLeaveAlert({ ...base, remainingMinutes: 10, dismissed: true })).toBeNull();
    expect(evaluateLeaveAlert({ ...base, remainingMinutes: 10, snoozed: true })).toBeNull();
  });

  test('tracks the two phases independently', () => {
    // Wrap-up already fired, but overtime must still be allowed.
    expect(
      evaluateLeaveAlert({ ...base, remainingMinutes: 10, wrapUpAlreadyAlerted: true }),
    ).toBeNull();
    expect(
      evaluateLeaveAlert({ ...base, remainingMinutes: -5, wrapUpAlreadyAlerted: true }),
    ).toEqual({ kind: 'overtime', remainingMinutes: -5 });

    // Overtime already fired, but a new wrap-up is still allowed.
    expect(
      evaluateLeaveAlert({ ...base, remainingMinutes: -5, overtimeAlreadyAlerted: true }),
    ).toBeNull();
    expect(
      evaluateLeaveAlert({ ...base, remainingMinutes: 10, overtimeAlreadyAlerted: true }),
    ).toEqual({ kind: 'wrapUp', remainingMinutes: 10 });
  });

  test('honours a custom threshold', () => {
    expect(evaluateLeaveAlert({ ...base, thresholdMinutes: 5, remainingMinutes: 10 })).toBeNull();
    expect(evaluateLeaveAlert({ ...base, thresholdMinutes: 15, remainingMinutes: 10 })?.kind).toBe(
      'wrapUp',
    );
  });
});
