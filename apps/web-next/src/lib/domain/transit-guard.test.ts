import { describe, expect, test, vi } from 'vitest';

import { TransitApiException, TRANSIT_NETWORK_ERROR_STATUS, TransitFetchGuard } from './transit-guard';

function fixedRng(value: number) {
  return () => value;
}

describe('TransitApiException.retryable', () => {
  test('network errors, 429 and 5xx are retryable', () => {
    expect(new TransitApiException(TRANSIT_NETWORK_ERROR_STATUS, 'net').retryable).toBe(true);
    expect(new TransitApiException(429, 'rate limited').retryable).toBe(true);
    expect(new TransitApiException(503, 'down').retryable).toBe(true);
  });

  test('client errors are not retryable', () => {
    expect(new TransitApiException(400, 'bad').retryable).toBe(false);
    expect(new TransitApiException(403, 'waf').retryable).toBe(false);
  });
});

describe('TransitFetchGuard', () => {
  test('allows attempts while healthy', () => {
    const guard = new TransitFetchGuard();
    expect(guard.canAttempt(0)).toBe(true);
    expect(guard.availability(0)).toBe('ok');
  });

  test('backs off exponentially with equal jitter', () => {
    const guard = new TransitFetchGuard({ rng: fixedRng(1) }); // full delay, no jitter reduction
    const delay = guard.recordFailure(0, { status: 503 });
    expect(delay).toBe(15_000);
    expect(guard.canAttempt(0)).toBe(false);
    expect(guard.availability(0)).toBe('backingOff');
    expect(guard.canAttempt(15_000)).toBe(true);
    expect(guard.remainingMs(5_000)).toBe(10_000);

    // Second failure doubles the base before jitter.
    const second = guard.recordFailure(0, { status: 503, message: 'boom' });
    expect(second).toBe(30_000);
    expect(guard.lastErrorMessage).toBe('boom');
  });

  test('jitter never collapses to zero', () => {
    const guard = new TransitFetchGuard({ rng: fixedRng(0) });
    expect(guard.recordFailure(0, { status: 503 })).toBe(7_500); // half of 15s
  });

  test('gives up immediately on a non-retryable status', () => {
    const guard = new TransitFetchGuard();
    guard.recordFailure(0, { status: 403 });
    expect(guard.hasGivenUp).toBe(true);
    expect(guard.availability(0)).toBe('unavailable');
    expect(guard.canAttempt(1_000_000)).toBe(false);
  });

  test('gives up after maxFailures consecutive retryable failures', () => {
    const guard = new TransitFetchGuard({ maxFailures: 3, rng: fixedRng(1) });
    guard.recordFailure(0, { status: 500 });
    guard.recordFailure(0, { status: 500 });
    guard.recordFailure(0, { status: 500 });
    expect(guard.hasGivenUp).toBe(true);
    expect(guard.availability(0)).toBe('unavailable');
  });

  test('honours Retry-After over the exponential curve', () => {
    const guard = new TransitFetchGuard({ rng: fixedRng(1) });
    const delay = guard.recordFailure(0, { status: 429, retryAfterMs: 60_000 });
    expect(delay).toBe(62_000);
  });

  test('success resets the failure state', () => {
    const guard = new TransitFetchGuard({ rng: fixedRng(1) });
    guard.recordFailure(0, { status: 500 });
    guard.recordSuccess();
    expect(guard.failures).toBe(0);
    expect(guard.canAttempt(0)).toBe(true);
    expect(guard.lastErrorMessage).toBeNull();
  });

  test('an explicit reset re-enables traffic after giving up', () => {
    const guard = new TransitFetchGuard();
    guard.recordFailure(0, { status: 403 });
    guard.reset();
    expect(guard.availability(0)).toBe('ok');
  });

  test('caps the delay at maxDelay', () => {
    const guard = new TransitFetchGuard({ maxDelayMs: 20_000, rng: fixedRng(1), maxFailures: 10 });
    guard.recordFailure(0, { status: 500 });
    const delay = guard.recordFailure(0, { status: 500 });
    expect(delay).toBe(20_000);
  });

  test('does not call the rng when the exponential delay is zero', () => {
    const rng = vi.fn(() => 0.5);
    const guard = new TransitFetchGuard({ baseDelayMs: 0, rng });
    guard.recordFailure(0, { status: 500 });
    expect(rng).not.toHaveBeenCalled();
  });
});
