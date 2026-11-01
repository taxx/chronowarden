import { describe, expect, test } from 'bun:test';
import { clear, consume, peek, resetRateLimits } from '../../src/rate-limit.ts';

describe('rate limiter', () => {
  test('allows up to the maximum, then rejects with a retry hint', () => {
    resetRateLimits();
    const rule = { windowMs: 1_000, max: 3 };
    expect(consume('unit', 'k', rule, 0).allowed).toBe(true);
    expect(consume('unit', 'k', rule, 0).allowed).toBe(true);
    expect(consume('unit', 'k', rule, 0).allowed).toBe(true);
    const denied = consume('unit', 'k', rule, 0);
    expect(denied.allowed).toBe(false);
    expect(denied.retryAfterSeconds).toBeGreaterThan(0);
  });

  test('resets once the window elapses', () => {
    resetRateLimits();
    const rule = { windowMs: 1_000, max: 1 };
    expect(consume('unit-window', 'k', rule, 0).allowed).toBe(true);
    expect(consume('unit-window', 'k', rule, 0).allowed).toBe(false);
    expect(consume('unit-window', 'k', rule, 1_001).allowed).toBe(true);
  });

  test('peek does not consume; clear forgets a bucket', () => {
    resetRateLimits();
    const rule = { windowMs: 1_000, max: 2 };
    peek('unit-peek', 'k', rule, 0);
    peek('unit-peek', 'k', rule, 0);
    expect(peek('unit-peek', 'k', rule, 0).remaining).toBe(2);
    consume('unit-peek', 'k', rule, 0);
    expect(peek('unit-peek', 'k', rule, 0).remaining).toBe(1);
    clear('unit-peek', 'k');
    expect(peek('unit-peek', 'k', rule, 0).remaining).toBe(2);
  });
});
