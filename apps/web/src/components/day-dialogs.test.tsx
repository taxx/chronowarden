import { render, screen } from '@testing-library/react';
import { describe, expect, test } from 'vitest';

import type { TravelPreset } from '../lib/domain/travel-preset';
import { StartDayDialog } from './day-dialogs';

const base = {
  morningProductiveCommuteMinutes: 0,
  eveningProductiveCommuteMinutes: 0,
  userId: null,
  createdAt: null,
} satisfies Partial<TravelPreset>;

const presets: TravelPreset[] = [
  {
    ...base,
    id: 'p1',
    name: 'Car commute',
    morningOverheadMinutes: 10,
    eveningOverheadMinutes: 10,
    commuteMode: 'car',
  },
  {
    ...base,
    id: 'p2',
    name: 'Train commute',
    morningOverheadMinutes: 5,
    eveningOverheadMinutes: 5,
    commuteMode: 'transit',
  },
];

function renderStart(defaultPresetId: string) {
  return render(
    <StartDayDialog
      open
      onClose={() => {}}
      expectedMinutes={480}
      presets={presets}
      defaultPresetId={defaultPresetId}
      defaultFlex={0}
      defaultLunch={30}
      showNonWork
      onSubmit={() => {}}
    />,
  );
}

describe('StartDayDialog', () => {
  test('selects the last-used preset instead of the first', () => {
    renderStart('p2');
    expect(screen.getByRole('combobox').textContent).toContain('Train commute');
  });

  test('shows the commute breakdown for the selected preset', () => {
    renderStart('p1');
    expect(screen.getByText('Commute breakdown')).toBeTruthy();
    expect(screen.getByText(/Morning: 10 min walk/)).toBeTruthy();
    expect(screen.getByText(/Total: 20 min commute/)).toBeTruthy();
  });

  test('hides the breakdown for a zero-commute preset', () => {
    render(
      <StartDayDialog
        open
        onClose={() => {}}
        expectedMinutes={480}
        presets={[
          {
            ...base,
            id: 'wfh',
            name: 'Work from home',
            morningOverheadMinutes: 0,
            eveningOverheadMinutes: 0,
            commuteMode: 'none',
          },
        ]}
        defaultPresetId="wfh"
        defaultFlex={0}
        defaultLunch={0}
        showNonWork
        onSubmit={() => {}}
      />,
    );
    expect(screen.queryByText('Commute breakdown')).toBeNull();
  });
});
