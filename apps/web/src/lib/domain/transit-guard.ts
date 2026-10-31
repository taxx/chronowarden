/**
 * Retry policy for the SL Journey Planner proxy.
 *
 * Ported from `apps/web/lib/services/transit_fetch_guard.dart`: pure and
 * clock-injected (timestamps in ms) so it is trivially unit-testable.
 *
 * Exponential back-off with equal jitter, honouring `Retry-After`. A
 * non-retryable status or too many consecutive failures gives up until an
 * explicit `reset()`.
 */

/** Status used when the failure happened before any response (transport error). */
export const TRANSIT_NETWORK_ERROR_STATUS = 0;

export type TransitAvailability = 'ok' | 'backingOff' | 'unavailable';

export class TransitApiException extends Error {
  readonly status: number;
  readonly retryAfterMs: number | null;

  constructor(status: number, message: string, retryAfterMs: number | null = null) {
    super(message);
    this.name = 'TransitApiException';
    this.status = status;
    this.retryAfterMs = retryAfterMs;
  }

  /** 4xx other than 429 means the request was rejected — retrying feeds a WAF. */
  get retryable(): boolean {
    return this.status === TRANSIT_NETWORK_ERROR_STATUS || this.status === 429 || this.status >= 500;
  }
}

export interface TransitGuardOptions {
  baseDelayMs?: number;
  maxDelayMs?: number;
  maxFailures?: number;
  rng?: () => number;
}

export class TransitFetchGuard {
  private readonly baseDelayMs: number;
  private readonly maxDelayMs: number;
  private readonly maxFailures: number;
  private readonly rng: () => number;

  private _failures = 0;
  private _backoffUntil: number | null = null;
  private _gaveUp = false;
  private _lastErrorMessage: string | null = null;
  private _lastDelayMs = 0;

  constructor(options: TransitGuardOptions = {}) {
    this.baseDelayMs = options.baseDelayMs ?? 15_000;
    this.maxDelayMs = options.maxDelayMs ?? 15 * 60_000;
    this.maxFailures = options.maxFailures ?? 6;
    this.rng = options.rng ?? Math.random;
  }

  get failures(): number {
    return this._failures;
  }

  get hasGivenUp(): boolean {
    return this._gaveUp;
  }

  get lastErrorMessage(): string | null {
    return this._lastErrorMessage;
  }

  get lastDelayMs(): number {
    return this._lastDelayMs;
  }

  get backoffUntilMs(): number | null {
    return this._backoffUntil;
  }

  canAttempt(nowMs: number): boolean {
    if (this._gaveUp) return false;
    if (this._backoffUntil !== null && nowMs < this._backoffUntil) return false;
    return true;
  }

  remainingMs(nowMs: number): number {
    if (this._backoffUntil === null) return 0;
    return Math.max(0, this._backoffUntil - nowMs);
  }

  availability(nowMs: number): TransitAvailability {
    if (this._gaveUp) return 'unavailable';
    if (!this.canAttempt(nowMs)) return 'backingOff';
    return 'ok';
  }

  recordSuccess(): void {
    this._failures = 0;
    this._backoffUntil = null;
    this._gaveUp = false;
    this._lastErrorMessage = null;
    this._lastDelayMs = 0;
  }

  /** Records a failure; returns the applied delay in ms (0 when giving up). */
  recordFailure(
    nowMs: number,
    options: { status: number; message?: string; retryAfterMs?: number | null },
  ): number {
    this._failures++;
    this._lastErrorMessage = options.message ?? null;

    const retryable =
      options.status === TRANSIT_NETWORK_ERROR_STATUS ||
      options.status === 429 ||
      options.status >= 500;

    if (!retryable || this._failures >= this.maxFailures) {
      this._gaveUp = true;
      this._backoffUntil = null;
      this._lastDelayMs = 0;
      return 0;
    }

    const delay = this.delayForFailure(this._failures, options.retryAfterMs ?? null);
    this._lastDelayMs = delay;
    this._backoffUntil = nowMs + delay;
    return delay;
  }

  reset(): void {
    this._failures = 0;
    this._backoffUntil = null;
    this._gaveUp = false;
    this._lastErrorMessage = null;
    this._lastDelayMs = 0;
  }

  private delayForFailure(failure: number, retryAfterMs: number | null): number {
    let millis = this.baseDelayMs * 2 ** (failure - 1);
    if (millis > this.maxDelayMs) millis = this.maxDelayMs;

    // The server knows better than our curve — honour Retry-After with a cushion.
    if (retryAfterMs !== null && retryAfterMs > millis) return retryAfterMs + 2000;

    // Equal jitter: 50–100% of the exponential delay. `nextInt(half + 1)`
    // semantics — the rng is clamped to [0, 1) so it can never exceed `half`.
    const half = Math.trunc(millis / 2);
    const jitter = half === 0 ? 0 : Math.floor(Math.min(this.rng(), 0.999999999) * (half + 1));
    return half + jitter;
  }
}
