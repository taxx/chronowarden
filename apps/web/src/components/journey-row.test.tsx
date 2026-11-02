import { render, screen } from '@testing-library/react';
import { describe, expect, test } from 'vitest';

import type { JourneyInfo } from '../lib/domain/transit';
import { JourneyStatusLine } from './journey-row';

function journey(hour: number, minute: number): JourneyInfo {
  const departure = new Date(2026, 2, 3, hour, minute);
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

describe('JourneyStatusLine', () => {
  test('shows the walk-adjusted leave time and countdown', () => {
    render(
      <JourneyStatusLine
        journey={journey(8, 30)}
        now={new Date(2026, 2, 3, 8, 0)}
        walkBuffer={10}
        pinned={false}
        variant="transit"
      />,
    );
    expect(screen.getByText(/Leave at 08:20/)).toBeTruthy();
    expect(screen.getByText(/leave in 20 min/)).toBeTruthy();
  });

  test('shows a missed message once the leave time has passed', () => {
    render(
      <JourneyStatusLine
        journey={journey(8, 30)}
        now={new Date(2026, 2, 3, 8, 30)}
        walkBuffer={10}
        pinned={false}
        variant="transit"
      />,
    );
    expect(screen.getByText(/Missed — needed to leave by 08:20/)).toBeTruthy();
  });
});
