import 'package:chronowarden/models/work_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isoWeekNumber', () {
    // Reference values from Python's datetime.isocalendar() (ISO 8601).
    // Dates deliberately straddle DST transitions (Europe/Sweden) and
    // ISO-year boundaries.
    const cases = <(int, int, int, int)>[
      (2026, 9, 14, 38), // Monday — the reported bug date (DST drift)
      (2026, 9, 20, 38), // Sunday — Thu of the week is before the date
      (2026, 10, 25, 43), // Sunday after the autumn DST fall-back
      (2026, 3, 30, 14), // Monday after the spring DST spring-forward
      (2023, 1, 1, 52), // Sunday — ISO week belongs to previous year
      (2023, 1, 2, 1), // Monday — start of ISO year 2023
      (2025, 12, 29, 1), // Monday — ISO year 2026 starts mid-December
      (2026, 12, 31, 53), // Thursday — last week of ISO year 2026
      (2024, 1, 1, 1), // Monday — leap year start
      (2024, 12, 31, 1), // Tuesday — ISO year 2025 starts in 2024
      (2023, 10, 26, 43), // Thursday
    ];

    for (final (y, m, d, expected) in cases) {
      test('ISO week of $y-$m-$d is $expected', () {
        expect(isoWeekNumber(DateTime(y, m, d)), expected);
      });
    }
  });

  group('WorkConfig.expectedMinutesForDate', () {
    // Reduced period: weeks 20–37 at 435 min, default 480 min.
    const config = WorkConfig(
      userId: 'u1',
      defaultExpectedMinutes: 480,
      reducedExpectedMinutes: 435,
      reducedStartWeek: 20,
      reducedEndWeek: 37,
    );

    test('uses reduced minutes inside the period', () {
      // ISO week 30 of 2026.
      expect(config.expectedMinutesForDate(DateTime(2026, 7, 27)), 435);
    });

    test('uses default minutes after the period ends (week 38)', () {
      // 2026-09-14 is ISO week 38 — outside the reduced period.
      expect(config.expectedMinutesForDate(DateTime(2026, 9, 14)), 480);
    });

    test('uses default minutes before the period starts', () {
      // ISO week 10 of 2026.
      expect(config.expectedMinutesForDate(DateTime(2026, 3, 2)), 480);
    });

    test('falls back to default when no reduced period configured', () {
      const plain = WorkConfig(userId: 'u1', defaultExpectedMinutes: 480);
      expect(plain.expectedMinutesForDate(DateTime(2026, 9, 14)), 480);
    });
  });
}
