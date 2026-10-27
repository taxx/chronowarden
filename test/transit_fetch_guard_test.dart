import 'dart:math';

import 'package:chronowarden/services/transit_fetch_guard.dart';
import 'package:chronowarden/services/transit_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// A manually advanced clock so the guard/service tests never wait.
class _Clock {
  DateTime now;
  _Clock(this.now);
  void advance(Duration d) => now = now.add(d);
}

void main() {
  group('TransitApiException.retryable', () {
    test('network errors, 429 and 5xx are retryable', () {
      expect(const TransitApiException(status: 0, message: '').retryable, isTrue);
      expect(const TransitApiException(status: 429, message: '').retryable, isTrue);
      expect(const TransitApiException(status: 500, message: '').retryable, isTrue);
      expect(const TransitApiException(status: 503, message: '').retryable, isTrue);
    });

    test('client errors are not retryable', () {
      expect(const TransitApiException(status: 400, message: '').retryable, isFalse);
      expect(const TransitApiException(status: 401, message: '').retryable, isFalse);
      expect(const TransitApiException(status: 403, message: '').retryable, isFalse);
      expect(const TransitApiException(status: 404, message: '').retryable, isFalse);
    });
  });

  group('TransitFetchGuard', () {
    final t0 = DateTime(2026, 1, 1, 12);

    test('starts healthy', () {
      final guard = TransitFetchGuard(random: Random(1));
      expect(guard.canAttempt(t0), isTrue);
      expect(guard.availability(t0), TransitAvailability.ok);
      expect(guard.failureCount, 0);
    });

    test('back-off delays grow and stay within half the exponential', () {
      final guard = TransitFetchGuard(
        baseDelay: const Duration(seconds: 10),
        random: Random(1),
      );
      final delays = <Duration>[];
      var now = t0;
      for (var i = 0; i < 4; i++) {
        final delay = guard.recordFailure(now, status: 500, message: 'boom');
        delays.add(delay);
        now = now.add(delay);
      }

      // Exponential caps: 10, 20, 40, 80 seconds; equal jitter is 50–100%.
      final expected = [10, 20, 40, 80];
      for (var i = 0; i < delays.length; i++) {
        expect(delays[i].inMilliseconds, greaterThanOrEqualTo(expected[i] * 1000 ~/ 2));
        expect(delays[i].inMilliseconds, lessThanOrEqualTo(expected[i] * 1000));
      }
      // Strictly growing envelopes.
      expect(delays[0] < delays[3], isTrue);
    });

    test('blocks attempts until the back-off window has elapsed', () {
      final clock = _Clock(t0);
      final guard = TransitFetchGuard(
        baseDelay: const Duration(seconds: 20),
        random: Random(2),
      );
      final delay = guard.recordFailure(clock.now, status: 500, message: 'boom');

      expect(guard.canAttempt(clock.now), isFalse);
      expect(guard.availability(clock.now), TransitAvailability.backingOff);
      expect(guard.remaining(clock.now), delay);

      clock.advance(delay - const Duration(seconds: 1));
      expect(guard.canAttempt(clock.now), isFalse);

      clock.advance(const Duration(seconds: 2));
      expect(guard.canAttempt(clock.now), isTrue);
    });

    test('403 gives up immediately and never retries automatically', () {
      final clock = _Clock(t0);
      final guard = TransitFetchGuard(random: Random(3));
      final delay = guard.recordFailure(clock.now, status: 403, message: 'forbidden');

      expect(delay, Duration.zero);
      expect(guard.hasGivenUp, isTrue);
      expect(guard.availability(clock.now), TransitAvailability.unavailable);
      expect(guard.availability(clock.now.add(const Duration(days: 1))),
          TransitAvailability.unavailable);
    });

    test('honors Retry-After when it exceeds the exponential delay', () {
      final guard = TransitFetchGuard(
        baseDelay: const Duration(seconds: 5),
        random: Random(4),
      );
      final delay = guard.recordFailure(
        t0,
        status: 429,
        message: 'slow down',
        retryAfter: const Duration(minutes: 3),
      );
      expect(delay, greaterThanOrEqualTo(const Duration(minutes: 3)));
    });

    test('gives up after maxFailures retryable failures', () {
      final guard = TransitFetchGuard(
        maxFailures: 3,
        random: Random(5),
      );
      var now = t0;
      guard.recordFailure(now, status: 500);
      now = now.add(const Duration(hours: 1));
      guard.recordFailure(now, status: 500);
      now = now.add(const Duration(hours: 1));
      guard.recordFailure(now, status: 500);

      expect(guard.hasGivenUp, isTrue);
      expect(guard.canAttempt(now), isFalse);
    });

    test('success resets the failure state', () {
      final guard = TransitFetchGuard(random: Random(6));
      guard.recordFailure(t0, status: 500, message: 'x');
      expect(guard.failureCount, 1);

      guard.recordSuccess();
      expect(guard.failureCount, 0);
      expect(guard.hasGivenUp, isFalse);
      expect(guard.backoffUntil, isNull);
      expect(guard.canAttempt(t0), isTrue);
    });

    test('reset clears a give-up', () {
      final guard = TransitFetchGuard(random: Random(7));
      guard.recordFailure(t0, status: 403);
      expect(guard.hasGivenUp, isTrue);

      guard.reset();
      expect(guard.hasGivenUp, isFalse);
      expect(guard.canAttempt(t0), isTrue);
    });
  });

  group('TransitService fetch integration', () {
    late _Clock clock;
    late int calls;
    late Object? errorToThrow;

    setUp(() {
      clock = _Clock(DateTime(2026, 1, 1, 8));
      calls = 0;
      errorToThrow = null;
    });

    TransitService buildService() => TransitService.createForTest(
          now: () => clock.now,
          proxyOverride: (path) async {
            calls++;
            if (errorToThrow != null) throw errorToThrow!;
            return {'journeys': <dynamic>[]};
          },
        );

    test('concurrent fetches coalesce into a single network call', () async {
      final service = buildService();
      final a = service.fetchJourneys(originId: 'a', destId: 'b');
      final b = service.fetchJourneys(originId: 'a', destId: 'b');
      await Future.wait([a, b]);
      expect(calls, 1);
    });

    test('a failure never rejects coalesced callers', () async {
      final service = buildService();
      errorToThrow = const TransitApiException(status: 500, message: 'boom');

      final a = service.fetchJourneys(originId: 'a', destId: 'b');
      final b = service.fetchJourneys(originId: 'a', destId: 'b');

      // Both complete normally with null (or stale cache), no uncaught error.
      expect(await a, isNull);
      expect(await b, isNull);
      expect(calls, 1);
    });

    test('backs off and skips the network until the window elapses', () async {
      final service = buildService();
      errorToThrow = const TransitApiException(status: 500, message: 'boom');

      await service.fetchJourneys(originId: 'a', destId: 'b');
      expect(calls, 1);
      expect(service.canAttempt, isFalse);
      expect(service.availability, TransitAvailability.backingOff);

      // A rebuild a second later must not hit the network.
      clock.advance(const Duration(seconds: 1));
      await service.fetchJourneys(originId: 'a', destId: 'b');
      expect(calls, 1);

      // Clear the error and let the window elapse — the next call goes out.
      errorToThrow = null;
      clock.advance(service.backoffRemaining + const Duration(seconds: 1));
      final journeys =
          await service.fetchJourneys(originId: 'a', destId: 'b');
      expect(calls, 2);
      expect(journeys, isNotNull);
      expect(service.availability, TransitAvailability.ok);
    });

    test('403 gives up and stops traffic until retryNow()', () async {
      final service = buildService();
      errorToThrow = const TransitApiException(status: 403, message: 'forbidden');

      await service.fetchJourneys(originId: 'a', destId: 'b');
      expect(calls, 1);
      expect(service.hasGivenUp, isTrue);

      clock.advance(const Duration(hours: 2));
      await service.fetchJourneys(originId: 'a', destId: 'b');
      expect(calls, 1, reason: 'should not retry automatically after give-up');

      errorToThrow = null;
      service.retryNow();
      expect(service.availability, TransitAvailability.ok);
      await service.fetchJourneys(originId: 'a', destId: 'b');
      expect(calls, 2);
    });

    test('success is cached for the TTL window', () async {
      final service = buildService();
      await service.fetchJourneys(originId: 'a', destId: 'b');
      expect(calls, 1);

      clock.advance(const Duration(seconds: 10));
      await service.fetchJourneys(originId: 'a', destId: 'b');
      expect(calls, 1, reason: 'fresh cache should be reused');

      clock.advance(const Duration(seconds: 55));
      await service.fetchJourneys(originId: 'a', destId: 'b');
      expect(calls, 2, reason: 'cache expired after 60s');
    });
  });
}
