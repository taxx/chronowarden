import 'package:chronowarden/models/journey_info.dart';
import 'package:chronowarden/widgets/journey_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Build a JourneyInfo departing at [dep] with a [duration] minute trip.
JourneyInfo journeyAt(DateTime dep, int duration) {
  return JourneyInfo(
    departureTime: dep,
    departureEstimated: dep,
    arrivalTime: dep.add(Duration(minutes: duration)),
    arrivalEstimated: dep.add(Duration(minutes: duration)),
    durationMinutes: duration,
    rtDurationMinutes: duration,
    legs: [
      LegInfo(type: LegType.walk, durationMinutes: 0),
      LegInfo(type: LegType.transport, durationMinutes: duration, line: '28'),
    ],
  );
}

/// Same as [journeyAt] but with a [delay] minute real-time departure delay.
JourneyInfo delayedJourney(DateTime dep, int duration, int delay) {
  final j = journeyAt(dep, duration);
  return JourneyInfo(
    departureTime: dep,
    departureEstimated: dep.add(Duration(minutes: delay)),
    arrivalTime: j.arrivalTime,
    arrivalEstimated: j.arrivalEstimated.add(Duration(minutes: delay)),
    durationMinutes: duration,
    rtDurationMinutes: duration,
    legs: j.legs,
  );
}

void main() {
  final theme = ThemeData.light();

  group('journeyStatus', () {
    test('pinned: counts down to departure after leave time passed', () {
      // Departure 08:30, walk 5 → leave 08:25. Now 08:27 (past the 1-min
      // catchable grace) → countdown to departure = 3 min.
      final s = journeyStatus(
        journey: journeyAt(DateTime(2024, 1, 15, 8, 30), 30),
        now: DateTime(2024, 1, 15, 8, 27),
        walkBuffer: 5,
        isPinned: true,
        tripLabel: 'arrive 09:00',
        theme: theme,
      );
      expect(s.text, 'Departs in 3 min · arrive 09:00');
      expect(s.color, theme.colorScheme.onSurfaceVariant);
    });

    test('pinned: shows 1 min countdown', () {
      final s = journeyStatus(
        journey: journeyAt(DateTime(2024, 1, 15, 8, 30), 30),
        now: DateTime(2024, 1, 15, 8, 29),
        walkBuffer: 5,
        isPinned: true,
        tripLabel: 'arrive 09:00',
        theme: theme,
      );
      expect(s.text, 'Departs in 1 min · arrive 09:00');
    });

    test('pinned: "departed" once departure time passes', () {
      final s = journeyStatus(
        journey: journeyAt(DateTime(2024, 1, 15, 8, 30), 30),
        now: DateTime(2024, 1, 15, 8, 31),
        walkBuffer: 5,
        isPinned: true,
        tripLabel: 'arrive 09:00',
        theme: theme,
      );
      expect(s.text, 'Committed ride — departed');
      expect(s.color, theme.colorScheme.onSurfaceVariant);
    });

    test('pinned: still shows leave time while catchable', () {
      final s = journeyStatus(
        journey: journeyAt(DateTime(2024, 1, 15, 8, 30), 30),
        now: DateTime(2024, 1, 15, 8, 20),
        walkBuffer: 5,
        isPinned: true,
        tripLabel: 'arrive 09:00',
        theme: theme,
      );
      expect(s.text, 'Leave at 08:25 · arrive 09:00 · leave in 5 min');
    });

    test('non-pinned: missed when leave time passed', () {
      final s = journeyStatus(
        journey: journeyAt(DateTime(2024, 1, 15, 8, 30), 30),
        now: DateTime(2024, 1, 15, 8, 28), // leave 08:25 passed by 3
        walkBuffer: 5,
        isPinned: false,
        tripLabel: 'arrive 09:00',
        theme: theme,
      );
      expect(s.text, 'Missed — needed to leave by 08:25');
      expect(s.color, theme.colorScheme.error);
    });

    test('catchable non-pinned uses leave time', () {
      final s = journeyStatus(
        journey: journeyAt(DateTime(2024, 1, 15, 8, 30), 30),
        now: DateTime(2024, 1, 15, 8, 10),
        walkBuffer: 5,
        isPinned: false,
        tripLabel: 'arrive 09:00',
        theme: theme,
      );
      expect(s.text, 'Leave at 08:25 · arrive 09:00 · leave in 15 min');
    });
  });

  group('journeyDelayColor', () {
    test('on time is green', () {
      expect(journeyDelayColor(journeyAt(DateTime(2024, 1, 15, 8, 30), 30)),
          Colors.green);
    });

    test('small delay (≤5 min) is orange', () {
      expect(journeyDelayColor(delayedJourney(DateTime(2024, 1, 15, 8, 30), 30, 3)),
          Colors.orange.shade700);
    });

    test('large delay is red', () {
      expect(journeyDelayColor(delayedJourney(DateTime(2024, 1, 15, 8, 30), 30, 9)),
          Colors.red);
    });
  });
}
