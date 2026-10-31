import { describe, expect, test } from 'bun:test';
import { mapProductClass, slimTripsResponse } from '../../src/sl.ts';

const sample = {
  systemMessages: [{ message: 'hello' }],
  journeys: [
    {
      tripDuration: 1800,
      tripRtDuration: 1860,
      legs: [
        {
          duration: 300,
          origin: { departureTimePlanned: '2026-10-15T08:00:00Z' },
          destination: { arrivalTimePlanned: '2026-10-15T08:05:00Z' },
        },
        {
          duration: 1200,
          transportation: {
            name: 'Buss 4',
            product: { class: 5 },
            destination: { name: 'Radiohuset' },
          },
          origin: {
            departureTimePlanned: '2026-10-15T08:10:00Z',
            departureTimeEstimated: '2026-10-15T08:13:00Z',
            properties: { occupancy: 'LOW', platformName: 'A' },
          },
          destination: { arrivalTimePlanned: '2026-10-15T08:30:00Z' },
        },
      ],
    },
  ],
};

describe('slimTripsResponse', () => {
  test('keeps journey times and maps legs', () => {
    const slimmed = slimTripsResponse(JSON.stringify(sample)) as any;
    expect(slimmed.journeys).toHaveLength(1);

    const journey = slimmed.journeys[0];
    expect(journey.departure_time).toBe('2026-10-15T08:00:00Z');
    expect(journey.duration_minutes).toBe(30);
    expect(journey.rt_duration_minutes).toBe(31);
    expect(journey.legs).toHaveLength(2);

    const [walk, bus] = journey.legs;
    expect(walk.type).toBe('walk');
    expect(walk.line).toBeUndefined();
    expect(bus.type).toBe('transport');
    expect(bus.line).toBe('4');
    expect(bus.transport_mode).toBe('BUS');
    expect(bus.destination).toBe('Radiohuset');
    expect(bus.departure_platform).toBe('A');
    expect(bus.occupancy).toBe('LOW');
    expect(bus.delay_minutes).toBe(3);
  });

  test('returns an empty journey list for a malformed payload', () => {
    const slimmed = slimTripsResponse(JSON.stringify({ systemMessages: [] })) as any;
    expect(slimmed.journeys).toEqual([]);
  });

  test('omits a zero delay', () => {
    const onTime = structuredClone(sample);
    onTime.journeys[0]!.legs[1]!.origin.departureTimeEstimated = '2026-10-15T08:10:00Z';
    const slimmed = slimTripsResponse(JSON.stringify(onTime)) as any;
    expect(slimmed.journeys[0].legs[1].delay_minutes).toBeUndefined();
  });
});

describe('mapProductClass', () => {
  test('maps known product classes', () => {
    expect(mapProductClass(0)).toBe('TRAIN');
    expect(mapProductClass(5)).toBe('BUS');
    expect(mapProductClass(9)).toBe('FERRY');
    expect(mapProductClass(999)).toBe('OTHER');
  });
});
