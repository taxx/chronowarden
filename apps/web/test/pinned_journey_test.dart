import 'dart:convert';

import 'package:chronowarden/models/journey_info.dart';
import 'package:chronowarden/models/pinned_journey.dart';
import 'package:chronowarden/models/transit_config.dart';
import 'package:chronowarden/services/pinned_journey_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build a JourneyInfo for a given line + departure time-of-day.
JourneyInfo journey(String line, int hour, int minute) {
  final dep = DateTime(2024, 1, 15, hour, minute);
  return JourneyInfo(
    departureTime: dep,
    departureEstimated: dep,
    arrivalTime: dep.add(const Duration(minutes: 30)),
    arrivalEstimated: dep.add(const Duration(minutes: 30)),
    durationMinutes: 30,
    rtDurationMinutes: 30,
    legs: [
      LegInfo(type: LegType.transport, durationMinutes: 30, line: line),
    ],
  );
}

TransitConfig cfg() => const TransitConfig(
      enabled: true,
      workStopId: 'work',
      homeStopId: 'home',
      workStopName: 'Work',
      homeStopName: 'Home',
    );

void main() {
  group('PinnedJourney.matches', () {
    PinnedJourney pin() => PinnedJourney(
          originId: 'home',
          destId: 'work',
          isMorning: true,
          line: '28',
          destination: 'Work',
          departure: DateTime(2024, 1, 15, 8, 30),
          durationMinutes: 30,
        );

    test('matches same line + departure time + route', () {
      expect(pin().matches(journey('28', 8, 30), 'home', 'work', true), isTrue);
    });

    test('does not match wrong direction', () {
      expect(pin().matches(journey('28', 8, 30), 'home', 'work', false), isFalse);
    });

    test('does not match different route (dest)', () {
      expect(pin().matches(journey('28', 8, 30), 'home', 'other', true), isFalse);
    });

    test('does not match different line', () {
      expect(pin().matches(journey('27', 8, 30), 'home', 'work', true), isFalse);
    });

    test('does not match different departure time', () {
      expect(pin().matches(journey('28', 8, 45), 'home', 'work', true), isFalse);
    });
  });

  group('PinnedJourney.isExpired', () {
    test('not expired on same day even after departure passes', () {
      final pin = PinnedJourney(
        originId: 'home',
        destId: 'work',
        isMorning: true,
        line: '28',
        destination: 'Work',
        departure: DateTime.now().subtract(const Duration(minutes: 1)),
        durationMinutes: 30,
      );
      // Still the same day — not expired.
      expect(pin.isExpired, isFalse);
    });

    test('expired once the day ends', () {
      final pin = PinnedJourney(
        originId: 'home',
        destId: 'work',
        isMorning: true,
        line: '28',
        destination: 'Work',
        departure: DateTime.now().subtract(const Duration(days: 1)),
        durationMinutes: 30,
      );
      expect(pin.isExpired, isTrue);
    });

    test('not expired before departure', () {
      final pin = PinnedJourney(
        originId: 'home',
        destId: 'work',
        isMorning: true,
        line: '28',
        destination: 'Work',
        departure: DateTime.now().add(const Duration(minutes: 5)),
        durationMinutes: 30,
      );
      expect(pin.isExpired, isFalse);
    });
  });

  group('PinnedJourney.toJourneyInfo', () {
    test('synthetic journey exposes main line/destination/duration', () {
      final pin = PinnedJourney(
        originId: 'home',
        destId: 'work',
        isMorning: true,
        line: '28',
        destination: 'Work',
        departure: DateTime(2024, 1, 15, 8, 30),
        durationMinutes: 35,
      );
      final j = pin.toJourneyInfo();
      expect(j.mainLine, '28');
      expect(j.mainDestination, 'Work');
      expect(j.durationMinutes, 35);
      expect(j.departureTime.toLocal().hour, 8);
      expect(j.departureTime.toLocal().minute, 30);
    });
  });

  group('PinnedJourney JSON round-trip', () {
    test('toJson/fromJson preserves fields', () {
      final pin = PinnedJourney(
        originId: 'home',
        destId: 'work',
        isMorning: true,
        line: '28',
        destination: 'Work',
        departure: DateTime(2024, 1, 15, 8, 30),
        durationMinutes: 35,
        occupancy: 'FEW_SEATS',
      );
      final decoded = PinnedJourney.fromJson(jsonDecode(jsonEncode(pin.toJson())));
      expect(decoded.originId, 'home');
      expect(decoded.destId, 'work');
      expect(decoded.isMorning, isTrue);
      expect(decoded.line, '28');
      expect(decoded.destination, 'Work');
      expect(decoded.durationMinutes, 35);
      expect(decoded.occupancy, 'FEW_SEATS');
      expect(decoded.departure, DateTime(2024, 1, 15, 8, 30));
    });
  });

  group('PinnedJourneyStore', () {
    // Helper: a journey departing in the near future (so pins don't expire).
    JourneyInfo futureJourney(String line, int addMinutes) {
      final dep = DateTime.now().add(Duration(minutes: addMinutes));
      return JourneyInfo(
        departureTime: dep,
        departureEstimated: dep,
        arrivalTime: dep.add(const Duration(minutes: 30)),
        arrivalEstimated: dep.add(const Duration(minutes: 30)),
        durationMinutes: 30,
        rtDurationMinutes: 30,
        legs: [
          LegInfo(type: LegType.transport, durationMinutes: 30, line: line),
        ],
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('pin persists and unpin clears', () async {
      final store = PinnedJourneyStore();
      await store.init();
      expect(store.pinned, isNull);

      await store.pin(futureJourney('28', 30), cfg(), true);
      expect(store.pinned, isNotNull);
      expect(store.pinned!.line, '28');

      await store.unpin();
      expect(store.pinned, isNull);
    });

    test('effectivePinnedJourney returns live match when present', () async {
      final store = PinnedJourneyStore();
      await store.init();
      await store.pin(futureJourney('28', 30), cfg(), true);

      final j = futureJourney('28', 30);
      final eff = store.effectivePinnedJourney([j], 'home', 'work', true);
      expect(eff, same(j)); // live journey, not synthetic
    });

    test('effectivePinnedJourney returns synthetic when window pushed it out',
        () async {
      final store = PinnedJourneyStore();
      await store.init();
      final pinnedJourney = futureJourney('28', 30);
      await store.pin(pinnedJourney, cfg(), true);

      // Not in the current list — returns synthetic built from the pin
      final eff = store.effectivePinnedJourney(
          [futureJourney('28', 60)], 'home', 'work', true);
      expect(eff, isNotNull);
      expect(eff!.mainLine, '28');
      expect(eff.departureTime.toLocal().hour, pinnedJourney.departureTime.hour);
      expect(eff.departureTime.toLocal().minute,
          pinnedJourney.departureTime.minute);
    });

    test('ignores pin for different route', () async {
      final store = PinnedJourneyStore();
      await store.init();
      await store.pin(futureJourney('28', 30), cfg(), true);
      expect(store.effectivePinnedJourney(
          [futureJourney('28', 30)], 'home', 'other', true), isNull);
    });

    test('expired pin (previous day) is dropped', () async {
      final store = PinnedJourneyStore();
      SharedPreferences.setMockInitialValues({
        'pinned_journey': jsonEncode(PinnedJourney(
          originId: 'home',
          destId: 'work',
          isMorning: true,
          line: '28',
          destination: 'Work',
          departure: DateTime.now().subtract(const Duration(days: 1)),
          durationMinutes: 30,
        ).toJson()),
      });
      await store.init();
      expect(store.pinned, isNull);
    });

    test('clearForRouteChange drops the pin', () async {
      final store = PinnedJourneyStore();
      await store.init();
      await store.pin(futureJourney('28', 30), cfg(), true);
      await store.clearForRouteChange();
      expect(store.pinned, isNull);
    });
  });
}
