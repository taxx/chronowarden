import 'package:chronowarden/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('evaluateLeaveAlert', () {
    LeaveAlert? eval({
      required double remaining,
      int threshold = 30,
      bool dismissed = false,
      bool snoozed = false,
      bool alreadyAlerted = false,
    }) {
      return evaluateLeaveAlert(
        remainingMinutes: remaining,
        thresholdMinutes: threshold,
        dismissed: dismissed,
        snoozed: snoozed,
        alreadyAlerted: alreadyAlerted,
      );
    }

    test('wrap-up alert fires inside the threshold', () {
      final alert = eval(remaining: 25);
      expect(alert, isNotNull);
      expect(alert!.kind, LeaveAlertKind.wrapUp);
      expect(alert.isUrgent, isFalse);
      expect(alert.remainingMinutes, 25);
    });

    test('wrap-up alert fires exactly at the threshold', () {
      final alert = eval(remaining: 30);
      expect(alert?.kind, LeaveAlertKind.wrapUp);
    });

    test('no alert while more time remains than the threshold', () {
      // This is the regression: 2h+ remaining must never produce a 30 min alert.
      expect(eval(remaining: 125), isNull);
    });

    test('overtime alert fires just past leave time', () {
      final alert = eval(remaining: -12);
      expect(alert?.kind, LeaveAlertKind.overtime);
      expect(alert!.isUrgent, isTrue);
      expect(alert.message, contains('12 min past'));
    });

    test('overtime alert stops after an hour past leave', () {
      expect(eval(remaining: -61), isNull);
    });

    test('dismissed suppresses the alert for the day', () {
      expect(eval(remaining: 10, dismissed: true), isNull);
    });

    test('snoozed suppresses the alert while the window runs', () {
      expect(eval(remaining: 10, snoozed: true), isNull);
    });

    test('already-delivered alert is not repeated without snooze', () {
      expect(eval(remaining: 10, alreadyAlerted: true), isNull);
    });

    test('right at leave time still counts as wrap-up', () {
      final alert = eval(remaining: 0);
      expect(alert?.kind, LeaveAlertKind.wrapUp);
      expect(alert?.message, contains('0 min left'));
    });
  });

  group('LeaveAlert messages', () {
    test('wrap-up formats hours and minutes', () {
      final alert = LeaveAlert.wrapUp(90);
      expect(alert.message, contains('1h 30m left'));
    });

    test('wrap-up rounds fractional minutes', () {
      expect(LeaveAlert.wrapUp(29.6).message, contains('30 min left'));
    });

    test('overtime uses absolute minutes past leave', () {
      expect(LeaveAlert.overtime(-45).message, contains('45 min past'));
    });
  });
}
