import { describe, expect, test } from 'bun:test';
import {
  MAX_SUBSCRIBERS_PER_USER,
  addSubscriber,
  canSubscribe,
  removeSubscriber,
  subscriberCount,
} from '../../src/events.ts';

describe('SSE subscriber bounds', () => {
  test('caps open streams per user and releases them on close', () => {
    const subscribers = Array.from({ length: MAX_SUBSCRIBERS_PER_USER }, () => () => {});
    for (const subscriber of subscribers) addSubscriber('user-1', subscriber);

    expect(canSubscribe('user-1')).toBe(false);
    expect(canSubscribe('user-2')).toBe(true);

    removeSubscriber('user-1', subscribers[0]!);
    expect(canSubscribe('user-1')).toBe(true);

    for (const subscriber of subscribers.slice(1)) removeSubscriber('user-1', subscriber);
    expect(subscriberCount()).toBe(0);
  });
});
