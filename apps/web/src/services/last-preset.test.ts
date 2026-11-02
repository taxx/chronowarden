import { beforeEach, describe, expect, test } from 'vitest';

import { getLastPresetId, setLastPresetId } from './last-preset';

describe('last travel preset', () => {
  beforeEach(() => localStorage.clear());

  test('round-trips the preset id', () => {
    expect(getLastPresetId()).toBe('');
    setLastPresetId('p2');
    expect(getLastPresetId()).toBe('p2');
  });

  test('ignores empty or undefined ids so a real selection is not cleared', () => {
    setLastPresetId('p1');
    setLastPresetId('');
    setLastPresetId(null);
    expect(getLastPresetId()).toBe('p1');
  });
});
