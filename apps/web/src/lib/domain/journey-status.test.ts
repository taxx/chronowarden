import { describe, expect, test } from 'vitest';

import { computeJourneyStatus } from './journey-status';
import type { JourneyInfo } from './transit';

function journey(departureIso: string): JourneyInfo {
  const departure = new Date(departureIso);
  return {
    departureTime: departure,
    departureEstimated: departure,
    arrivalTime: departure,
    arrivalEstimated: departure,
    durationMinutes: 30,
    rtDurationMinutes: 30,
    legs: [],
  };
}

describe('computeJourneyStatus', () => {
  const dep = '2026-03-03T08:30:00.000Z';

  test('is catchable with a countdown and a leave time that accounts for the walk', () => {
    const now = new Date('2026-03-03T08:00:00.000Z');
    const status = computeJourneyStatus(journey(dep), now, 10, false);
    expect(status.kind).toBe('leave');
    expect(status.catchable).toBe(true);
    expect(status.leaveTime.toISOString()).toBe('2026-03-03T08:20:00.000Z');
    expect(status.minutesUntilLeave).toBe(20);
  });

  test('is missed once the leave time has passed', () => {
    const now = new Date('2026-03-03T08:25:00.000Z');
    const status = computeJourneyStatus(journey(dep), now, 10, false);
    expect(status.kind).toBe('missed');
    expect(status.catchable).toBe(false);
  });

  test('a pinned journey counts down to departure instead of showing missed', () => {
    const now = new Date('2026-03-03T08:25:00.000Z');
    const status = computeJourneyStatus(journey(dep), now, 10, true);
    expect(status.kind).toBe('departs');
    expect(status.minutesUntilDeparture).toBe(5);
    expect(status.catchable).toBe(false);
  });

  test('a pinned journey that has departed is neutral, not an error', () => {
    const now = new Date('2026-03-03T08:40:00.000Z');
    const status = computeJourneyStatus(journey(dep), now, 10, true);
    expect(status.kind).toBe('departed');
  });
});
