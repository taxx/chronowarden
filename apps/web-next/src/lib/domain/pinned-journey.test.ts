import { describe, expect, test } from 'vitest';

import type { JourneyInfo } from './transit';
import {
  journeyMatchesPin,
  pinBelongsToRoute,
  pinFromJourney,
  pinIsExpired,
} from './pinned-journey';

const journey: JourneyInfo = {
  departureTime: new Date(2026, 0, 15, 8, 12),
  departureEstimated: new Date(2026, 0, 15, 8, 12),
  arrivalTime: new Date(2026, 0, 15, 8, 40),
  arrivalEstimated: new Date(2026, 0, 15, 8, 40),
  durationMinutes: 28,
  rtDurationMinutes: 28,
  legs: [
    { type: 'walk', durationMinutes: 4 },
    {
      type: 'transport',
      durationMinutes: 24,
      line: '28',
      destination: 'Östra station',
      departurePlatform: 'A',
    },
  ],
};

describe('pinned journeys', () => {
  test('builds a pin from a journey', () => {
    const pin = pinFromJourney(journey, 'home', 'work', '2026-01-15');
    expect(pin.timeOfDay).toBe('08:12');
    expect(pin.line).toBe('28');
    expect(pin.destination).toBe('Östra station');
    expect(pin.durationMinutes).toBe(28);
    expect(pin.pinnedDate).toBe('2026-01-15');
  });

  test('matches a live journey on scheduled time and line', () => {
    const pin = pinFromJourney(journey, 'home', 'work', '2026-01-15');
    expect(journeyMatchesPin(journey, pin)).toBe(true);

    const late = { ...journey, departureEstimated: new Date(2026, 0, 15, 8, 20) };
    expect(journeyMatchesPin(late, pin)).toBe(true); // delays don't unpin it

    const differentLine = {
      ...journey,
      legs: [{ type: 'transport', durationMinutes: 24, line: '4' } as const],
    };
    expect(journeyMatchesPin(differentLine as JourneyInfo, pin)).toBe(false);
  });

  test('expires the day after it was pinned', () => {
    const pin = pinFromJourney(journey, 'home', 'work', '2026-01-15');
    expect(pinIsExpired(pin, '2026-01-15')).toBe(false);
    expect(pinIsExpired(pin, '2026-01-16')).toBe(true);
  });

  test('belongs to a route', () => {
    const pin = pinFromJourney(journey, 'home', 'work', '2026-01-15');
    expect(pinBelongsToRoute(pin, 'home', 'work')).toBe(true);
    expect(pinBelongsToRoute(pin, 'work', 'home')).toBe(false);
  });
});
