import 'dart:math';

/// Status code used when the failure happened before any response was
/// received (network/transport error, TLS failure, proxy timeout, …).
const int transitNetworkErrorStatus = 0;

/// How the transit service currently regards itself.
enum TransitAvailability {
  /// Healthy — a fetch may be attempted now.
  ok,

  /// A recent failure happened and we are waiting out a back-off window.
  /// Requests are skipped (no network traffic) until [TransitFetchGuard] says
  /// otherwise.
  backingOff,

  /// We have given up: a non-retryable failure (e.g. 403 from a WAF) or too
  /// many consecutive failures. No background traffic until the user
  /// explicitly retries.
  unavailable,
}

/// A typed failure from the `sl-proxy` Edge Function or the SL API.
///
/// [status] is the HTTP status returned by the proxy (or
/// [transitNetworkErrorStatus] for transport errors). [retryAfter] is filled
/// in when the server told us how long to wait (429/503 + `Retry-After`).
class TransitApiException implements Exception {
  final int status;
  final String message;
  final Duration? retryAfter;

  const TransitApiException({
    required this.status,
    required this.message,
    this.retryAfter,
  });

  /// Whether retrying this error could plausibly succeed.
  ///
  /// 4xx other than 429 means the request itself was rejected — retrying it
  /// only feeds a rate limiter / WAF, so callers stop instead.
  bool get retryable =>
      status == transitNetworkErrorStatus || status == 429 || status >= 500;

  @override
  String toString() => 'TransitApiException($status): $message';
}

/// Decides *whether* and *when* the transit service may hit the network again
/// after a failure.
///
/// This is deliberately pure and clock-injected so it can be unit-tested
/// without timers. It implements exponential back-off with equal jitter:
///
///   delay(n) = min(base * 2^(n-1), max) * [0.5, 1.0]
///
/// and treats a non-retryable status (403/401/400/…) as "give up now". After
/// [maxFailures] consecutive retryable failures it gives up as well. In both
/// give-up cases only an explicit [reset] (a user pressing "Try again",
/// pull-to-refresh, …) re-enables traffic.
class TransitFetchGuard {
  TransitFetchGuard({
    this.baseDelay = const Duration(seconds: 15),
    this.maxDelay = const Duration(minutes: 15),
    this.maxFailures = 6,
    Random? random,
  }) : _random = random ?? Random();

  /// First back-off delay. Later failures double it up to [maxDelay].
  final Duration baseDelay;

  /// Upper bound for the exponential delay.
  final Duration maxDelay;

  /// How many consecutive retryable failures before giving up.
  final int maxFailures;

  final Random _random;

  int _failureCount = 0;
  DateTime? _backoffUntil;
  bool _gaveUp = false;
  String? _lastErrorMessage;
  Duration _lastDelay = Duration.zero;

  int get failureCount => _failureCount;
  bool get hasGivenUp => _gaveUp;
  String? get lastErrorMessage => _lastErrorMessage;

  /// When the current back-off window expires (null when not backing off).
  DateTime? get backoffUntil => _backoffUntil;

  /// The delay applied by the most recent failure.
  Duration get lastDelay => _lastDelay;

  /// Whether a network attempt is allowed right now.
  bool canAttempt(DateTime now) {
    if (_gaveUp) return false;
    final until = _backoffUntil;
    if (until != null && now.isBefore(until)) return false;
    return true;
  }

  /// Remaining back-off time, clamped to zero.
  Duration remaining(DateTime now) {
    final until = _backoffUntil;
    if (until == null) return Duration.zero;
    final diff = until.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  TransitAvailability availability(DateTime now) {
    if (_gaveUp) return TransitAvailability.unavailable;
    if (!canAttempt(now)) return TransitAvailability.backingOff;
    return TransitAvailability.ok;
  }

  /// A fetch succeeded — clear all failure state.
  void recordSuccess() {
    _failureCount = 0;
    _backoffUntil = null;
    _gaveUp = false;
    _lastErrorMessage = null;
    _lastDelay = Duration.zero;
  }

  /// A fetch failed. Returns the delay applied (zero when we gave up).
  Duration recordFailure(
    DateTime now, {
    required int status,
    String? message,
    Duration? retryAfter,
  }) {
    _failureCount++;
    _lastErrorMessage = message;

    final retryable = status == transitNetworkErrorStatus ||
        status == 429 ||
        status >= 500;

    if (!retryable || _failureCount >= maxFailures) {
      _gaveUp = true;
      _backoffUntil = null;
      _lastDelay = Duration.zero;
      return Duration.zero;
    }

    final delay = _delayForFailure(_failureCount, retryAfter);
    _lastDelay = delay;
    _backoffUntil = now.add(delay);
    return delay;
  }

  /// Explicit user retry — wipe the slate clean.
  void reset() {
    _failureCount = 0;
    _backoffUntil = null;
    _gaveUp = false;
    _lastErrorMessage = null;
    _lastDelay = Duration.zero;
  }

  Duration _delayForFailure(int failure, Duration? retryAfter) {
    var millis = baseDelay.inMilliseconds * pow(2, failure - 1);
    if (millis > maxDelay.inMilliseconds) {
      millis = maxDelay.inMilliseconds.toDouble();
    }
    final delay = Duration(milliseconds: millis.round());

    // The server knows better than our curve — honor Retry-After and add a
    // small cushion so we don't race its window.
    if (retryAfter != null && retryAfter > delay) {
      return retryAfter + const Duration(seconds: 2);
    }

    // Equal jitter: 50–100% of the exponential delay. Never collapses to
    // zero, unlike full jitter, so we don't immediately hit the WAF again.
    final half = delay.inMilliseconds ~/ 2;
    final jitter = half == 0 ? 0 : _random.nextInt(half + 1);
    return Duration(milliseconds: half + jitter);
  }
}
