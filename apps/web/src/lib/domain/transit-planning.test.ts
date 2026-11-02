import { describe, expect, test } from 'vitest';

import { isMorningCommute } from './journey-status';
import type { TimeLog } from './time-log';
import { commuteUsesTransit, type TravelPreset } from './travel-preset';
import { shouldShowTransitPlanning } from './transit';

function preset(overrides: Partial<TravelPreset> & { id: string; name: string }): TravelPreset {
  return {
    morningOverheadMinutes: 0,
    morningProductiveCommuteMinutes: 0,
    eveningOverheadMinutes: 0,
    eveningProductiveCommuteMinutes: 0,
    commuteMode: 'none',
    ...overrides,
  };
}

const activeCar = preset({
  id: 'car',
  name: 'Car',
  commuteMode: 'car',
  morningOverheadMinutes: 10,
  eveningOverheadMinutes: 10,
});
const transit = preset({ id: 'train', name: 'Train', commuteMode: 'transit' });
const wfh = preset({ id: 'wfh', name: 'Work from home', commuteMode: 'none' });

function log(overrides: Partial<TimeLog> = {}): TimeLog {
  return {
    date: '2026-03-03',
    startTime: '08:00:00',
    endTime: null,
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

describe('shouldShowTransitPlanning', () => {
  test('shows weekdays regardless of the weekend setting', () => {
    const monday = new Date(2026, 2, 2); // Mon
    expect(shouldShowTransitPlanning(monday, false)).toBe(true);
    expect(shouldShowTransitPlanning(monday, true)).toBe(true);
  });

  test('hides weekends unless the user works them', () => {
    const saturday = new Date(2026, 2, 7);
    expect(shouldShowTransitPlanning(saturday, false)).toBe(false);
    expect(shouldShowTransitPlanning(saturday, true)).toBe(true);
  });
});

describe('isMorningCommute (the 11:00 cutover)', () => {
  test('before 11:00 with no active day → to work', () => {
    expect(isMorningCommute(new Date(2026, 2, 3, 9, 0), null)).toBe(true);
  });

  test('after 11:00 with no active day → home', () => {
    expect(isMorningCommute(new Date(2026, 2, 3, 12, 0), null)).toBe(false);
  });

  test('an active day always heads home, even early', () => {
    expect(isMorningCommute(new Date(2026, 2, 3, 9, 0), log())).toBe(false);
  });

  test('a finished day falls back to the clock', () => {
    expect(isMorningCommute(new Date(2026, 2, 3, 9, 0), log({ endTime: '16:00:00' }))).toBe(true);
    expect(isMorningCommute(new Date(2026, 2, 3, 12, 0), log({ endTime: '16:00:00' }))).toBe(false);
  });
});

describe('commuteUsesTransit', () => {
  test('planning: any transit preset keeps it visible', () => {
    expect(commuteUsesTransit([wfh, transit], null, null)).toBe(true);
    expect(commuteUsesTransit([wfh], null, 'wfh')).toBe(false);
    // Presets still loading → keep visible rather than flicker.
    expect(commuteUsesTransit([], null, null)).toBe(true);
  });

  test('active day: trusts the day’s matched preset', () => {
    // The day was started from the car preset → hide transit even though a
    // transit preset exists.
    expect(
      commuteUsesTransit(
        [transit, activeCar],
        log({
          morningOverheadMinutes: 10,
          eveningOverheadMinutes: 10,
        }),
        'train',
      ),
    ).toBe(false);
  });

  test('active day: transit preset shows the card', () => {
    expect(commuteUsesTransit([transit], log(), 'train')).toBe(true);
  });
});
