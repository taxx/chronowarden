import 'package:chronowarden/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatMins (unsigned magnitude)', () {
    test('formats values', () {
      expect(formatMins(0), '0 min');
      expect(formatMins(30), '30 min');
      expect(formatMins(60), '1h');
      expect(formatMins(90), '1h 30m');
      expect(formatMins(480), '8h');
      expect(formatMins(495), '8h 15m');
    });

    test('drops the sign (callers prefix it themselves)', () {
      expect(formatMins(-90), '1h 30m');
      expect(formatMins(-45), '45 min');
    });
  });

  group('formatDurationMinutes (signed, no leading +)', () {
    test('formats values', () {
      expect(formatDurationMinutes(0), '0 min');
      expect(formatDurationMinutes(30), '30 min');
      expect(formatDurationMinutes(60), '1h');
      expect(formatDurationMinutes(90), '1h 30m');
    });

    test('shows a minus for negative values', () {
      expect(formatDurationMinutes(-30), '-30 min');
      expect(formatDurationMinutes(-60), '-1h');
      expect(formatDurationMinutes(-90), '-1h 30m');
    });
  });

  group('formatSignedMinutes (always signed)', () {
    test('formats values with an explicit +', () {
      expect(formatSignedMinutes(0), '+0 min');
      expect(formatSignedMinutes(30), '+30 min');
      expect(formatSignedMinutes(60), '+1h');
      expect(formatSignedMinutes(90), '+1h 30m');
    });

    test('shows a minus for negative values (regression: was hidden)', () {
      expect(formatSignedMinutes(-30), '-30 min');
      expect(formatSignedMinutes(-60), '-1h');
      expect(formatSignedMinutes(-90), '-1h 30m');
    });
  });

  group('formatOvertimeStatus', () {
    test('shows a check when exactly on target', () {
      expect(formatOvertimeStatus(0), '✓');
    });

    test('shows the signed balance otherwise', () {
      expect(formatOvertimeStatus(90), '+1h 30m');
      expect(formatOvertimeStatus(-45), '-45 min');
    });
  });
}
