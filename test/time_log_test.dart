import 'package:chronowarden/models/time_log.dart';
import 'package:chronowarden/models/travel_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeLog.leaveTime', () {
    // Helper to create a TimeLog with the given values.
    // Splits total overhead/productive commute 50/50 into morning/evening.
    TimeLog makeLog({
      String startTime = '07:30:00',
      int expectedMinutes = 480,
      int overheadMinutes = 50,
      int lunchMinutes = 0,
      int productiveCommuteMinutes = 0,
      String date = '2024-01-15',
    }) {
      return TimeLog(
        date: date,
        startTime: startTime,
        expectedMinutes: expectedMinutes,
        lunchMinutes: lunchMinutes,
        morningOverheadMinutes: overheadMinutes ~/ 2,
        morningProductiveCommuteMinutes: productiveCommuteMinutes ~/ 2,
        eveningOverheadMinutes: overheadMinutes - (overheadMinutes ~/ 2),
        eveningProductiveCommuteMinutes:
            productiveCommuteMinutes - (productiveCommuteMinutes ~/ 2),
        overtimeMinutes: 0,
      );
    }

    test('no commute — leave time = start + expected + lunch', () {
      final log = makeLog(overheadMinutes: 0, productiveCommuteMinutes: 0);
      // Formula: start + expected + lunch + morningOverhead - eveningProductive
      // With zero commute: start + expected + lunch
      final leave = log.leaveTime;
      final expected = DateTime(2024, 1, 15, 7, 30)
          .add(const Duration(minutes: 480));
      expect(leave, expected);
    });

    test('with productive commute — leave time subtracts evening portion', () {
      // User works 60 min on train (30 each direction).
      // Evening portion (30 min) subtracted from leave time.
      final log = makeLog(
        startTime: '07:30:00',
        expectedMinutes: 480,
        overheadMinutes: 50,
        productiveCommuteMinutes: 60,
      );
      final leave = log.leaveTime;
      // start + expected + lunch + morningOverhead - eveningProductive
      // = 07:30 + 480 + 0 + 25 - 30 = 07:30 + 475 = 15:25
      final expected = DateTime(2024, 1, 15, 7, 30)
          .add(const Duration(minutes: 480 + 25 - 30));
      expect(leave, expected);
    });

    test('with lunch and productive commute', () {
      final log = makeLog(
        startTime: '07:30:00',
        expectedMinutes: 480,
        overheadMinutes: 50,
        lunchMinutes: 30,
        productiveCommuteMinutes: 60,
      );
      final leave = log.leaveTime;
      // 07:30 + 480 + 30 + 25 - 30 = 07:30 + 505 = 15:55
      final expected = DateTime(2024, 1, 15, 7, 30)
          .add(const Duration(minutes: 480 + 30 + 25 - 30));
      expect(leave, expected);
    });

    test('odd overhead minutes — integer division', () {
      // 25 total overhead = 12 morning, 13 evening
      final log = makeLog(
        startTime: '07:30:00',
        expectedMinutes: 480,
        overheadMinutes: 25,
      );
      final leave = log.leaveTime;
      // 07:30 + 480 + 0 + 12 - 0 = 07:30 + 492
      final expected = DateTime(2024, 1, 15, 7, 30)
          .add(const Duration(minutes: 480 + 12));
      expect(leave, expected);
    });

    test('calculateLeaveTime() matches leaveTime getter', () {
      final log = makeLog(
        startTime: '07:30:00',
        expectedMinutes: 480,
        overheadMinutes: 50,
        productiveCommuteMinutes: 60,
      );
      final dayStart = DateTime(2024, 1, 15, 7, 30);
      final calculated = log.calculateLeaveTime(dayStart);
      expect(calculated, log.leaveTime);
    });
  });

  group('TimeLog.calculateOvertimeMinutes', () {
    TimeLog makeLogWithEnd({
      String startTime = '07:30:00',
      String? endTime,
      int expectedMinutes = 480,
      int overheadMinutes = 50,
      int lunchMinutes = 0,
      int productiveCommuteMinutes = 0,
      String date = '2024-01-15',
    }) {
      return TimeLog(
        date: date,
        startTime: startTime,
        endTime: endTime,
        expectedMinutes: expectedMinutes,
        lunchMinutes: lunchMinutes,
        morningOverheadMinutes: overheadMinutes ~/ 2,
        morningProductiveCommuteMinutes: productiveCommuteMinutes ~/ 2,
        eveningOverheadMinutes: overheadMinutes - (overheadMinutes ~/ 2),
        eveningProductiveCommuteMinutes:
            productiveCommuteMinutes - (productiveCommuteMinutes ~/ 2),
        overtimeMinutes: 0,
      );
    }

    test('no end time — returns 0', () {
      final log = makeLogWithEnd(endTime: null);
      expect(log.calculateOvertimeMinutes(), 0);
    });

    test('exactly on target — no overtime', () {
      // Start 07:30, end 16:20 = 530 min
      // expected(480) + overhead(50) = 530 → 0 overtime
      final log = makeLogWithEnd(
        startTime: '07:30:00',
        endTime: '16:20:00',
        expectedMinutes: 480,
        overheadMinutes: 50,
      );
      expect(log.calculateOvertimeMinutes(), 0);
    });

    test('with productive commute and on target — no overtime', () {
      // Total elapsed = expected + overhead regardless of productive commute
      // Start 07:30, end 16:20 = 530 min, expected+overhead = 530 → 0
      final log = makeLogWithEnd(
        startTime: '07:30:00',
        endTime: '16:20:00',
        expectedMinutes: 480,
        overheadMinutes: 50,
        productiveCommuteMinutes: 60,
      );
      expect(log.calculateOvertimeMinutes(), 0);
    });

    test('overtime worked — positive overtime', () {
      // Start 07:30, end 17:20 = 590 min
      // 590 - 480 - 50 = 60 min overtime
      final log = makeLogWithEnd(
        startTime: '07:30:00',
        endTime: '17:20:00',
        expectedMinutes: 480,
        overheadMinutes: 50,
      );
      expect(log.calculateOvertimeMinutes(), 60);
    });

    test('left early — negative overtime (time bank credit)', () {
      // Start 07:30, end 15:20 = 470 min
      // 470 - 480 - 50 = -60 min (time bank credit)
      final log = makeLogWithEnd(
        startTime: '07:30:00',
        endTime: '15:20:00',
        expectedMinutes: 480,
        overheadMinutes: 50,
      );
      expect(log.calculateOvertimeMinutes(), -60);
    });

    test('with lunch — lunch minutes subtracted', () {
      // Start 07:30, end 16:50 = 560 min
      // 560 - 30 (lunch) - 480 - 50 = 0
      final log = makeLogWithEnd(
        startTime: '07:30:00',
        endTime: '16:50:00',
        expectedMinutes: 480,
        overheadMinutes: 50,
        lunchMinutes: 30,
      );
      expect(log.calculateOvertimeMinutes(), 0);
    });

    test('with productive commute and lunch — correct overtime', () {
      // Start 07:30, end 16:50 = 560 min
      // 560 - 30 (lunch) - 480 - 50 = 0
      // productive commute doesn't affect overtime formula
      final log = makeLogWithEnd(
        startTime: '07:30:00',
        endTime: '16:50:00',
        expectedMinutes: 480,
        overheadMinutes: 50,
        lunchMinutes: 30,
        productiveCommuteMinutes: 60,
      );
      expect(log.calculateOvertimeMinutes(), 0);
    });
  });

  group('TimeLog.flexMinutes (banked-time withdrawal projection)', () {
    test('leave time shifts earlier by the flex minutes', () {
      // No flex: start + expected + lunch + morningOverhead - eveningProductive
      final noFlex = TimeLog(
        date: '2024-01-15',
        startTime: '07:30:00',
        expectedMinutes: 480,
        lunchMinutes: 0,
        morningOverheadMinutes: 25,
        eveningOverheadMinutes: 25,
        eveningProductiveCommuteMinutes: 30,
        overtimeMinutes: 0,
      );
      final withFlex = TimeLog(
        date: '2024-01-15',
        startTime: '07:30:00',
        expectedMinutes: 480,
        lunchMinutes: 0,
        flexMinutes: 60,
        morningOverheadMinutes: 25,
        eveningOverheadMinutes: 25,
        eveningProductiveCommuteMinutes: 30,
        overtimeMinutes: 0,
      );
      // 07:30 + 480 + 25 - 30 = 15:25
      final base = DateTime(2024, 1, 15, 15, 25);
      expect(noFlex.leaveTime, base);
      // With 60 min flex: 15:25 - 60 = 14:25
      expect(withFlex.leaveTime, base.subtract(const Duration(minutes: 60)));
    });

    test('overtime calculation ignores flex (live projection only)', () {
      // flex is a planning offset for the active day; final overtime must not
      // be affected by it.
      final withFlex = TimeLog(
        date: '2024-01-15',
        startTime: '07:30:00',
        endTime: '16:20:00',
        expectedMinutes: 480,
        lunchMinutes: 0,
        flexMinutes: 60,
        morningOverheadMinutes: 25,
        eveningOverheadMinutes: 25,
        overtimeMinutes: 0,
      );
      // 530 elapsed - 480 - 50 overhead = 0 overtime (flex excluded)
      expect(withFlex.calculateOvertimeMinutes(), 0);
    });
  });

  group('TimeLog.totalExpectedMinutes', () {
    test('sums expected and total overhead', () {
      final log = TimeLog(
        date: '2024-01-15',
        startTime: '07:30:00',
        expectedMinutes: 480,
        lunchMinutes: 30,
        morningOverheadMinutes: 25,
        morningProductiveCommuteMinutes: 30,
        eveningOverheadMinutes: 25,
        eveningProductiveCommuteMinutes: 30,
        overtimeMinutes: 0,
      );
      expect(log.totalExpectedMinutes, 530);
    });
  });

  group('TimeLog.copyWith', () {
    test('includes per-direction commute fields', () {
      final original = TimeLog(
        date: '2024-01-15',
        startTime: '07:30:00',
        expectedMinutes: 480,
        morningOverheadMinutes: 25,
        morningProductiveCommuteMinutes: 30,
        eveningOverheadMinutes: 25,
        eveningProductiveCommuteMinutes: 30,
        overtimeMinutes: 0,
      );
      final copy = original.copyWith(
        morningOverheadMinutes: 0,
        eveningOverheadMinutes: 50,
      );
      expect(copy.morningOverheadMinutes, 0);
      expect(copy.eveningOverheadMinutes, 50);
      expect(original.morningOverheadMinutes, 25);
      expect(original.eveningOverheadMinutes, 25);
    });
  });

  group('TravelPreset JSON round-trip', () {
    test('fromJson parses per-direction fields', () {
      final json = {
        'id': 'test-id',
        'user_id': 'test-user',
        'name': 'Train Commute',
        'morning_overhead_minutes': 10,
        'morning_productive_commute_minutes': 15,
        'evening_overhead_minutes': 15,
        'evening_productive_commute_minutes': 15,
        'created_at': '2024-01-01T00:00:00Z',
      };
      final preset = TravelPreset.fromJson(json);
      expect(preset.morningOverheadMinutes, 10);
      expect(preset.eveningOverheadMinutes, 15);
      expect(preset.productiveCommuteMinutes, 30);
      expect(preset.defaultOverheadMinutes, 25);
    });

    test('fromJson falls back to legacy total fields', () {
      final json = {
        'name': 'Car Commute',
        'default_overhead_minutes': 30,
      };
      final preset = TravelPreset.fromJson(json);
      expect(preset.defaultOverheadMinutes, 30);
      expect(preset.morningOverheadMinutes, 15);
      expect(preset.eveningOverheadMinutes, 15);
    });

    test('toJson includes both legacy and new fields', () {
      final preset = TravelPreset(
        name: 'Train',
        morningOverheadMinutes: 10,
        morningProductiveCommuteMinutes: 15,
        eveningOverheadMinutes: 15,
        eveningProductiveCommuteMinutes: 15,
      );
      final json = preset.toJson();
      expect(json['morning_overhead_minutes'], 10);
      expect(json['evening_overhead_minutes'], 15);
      expect(json['default_overhead_minutes'], 25);
      expect(json['productive_commute_minutes'], 30);
    });
  });

  group('TimeLog JSON round-trip', () {
    test('fromJson parses per-direction fields', () {
      final json = {
        'date': '2024-01-15',
        'start_time': '07:30:00',
        'expected_minutes': 480,
        'overtime_minutes': 0,
        'morning_overhead_minutes': 10,
        'morning_productive_commute_minutes': 15,
        'evening_overhead_minutes': 15,
        'evening_productive_commute_minutes': 15,
      };
      final log = TimeLog.fromJson(json);
      expect(log.morningOverheadMinutes, 10);
      expect(log.eveningOverheadMinutes, 15);
      expect(log.overheadMinutes, 25);
      expect(log.productiveCommuteMinutes, 30);
    });

    test('fromJson falls back to legacy total fields', () {
      final json = {
        'date': '2024-01-15',
        'start_time': '07:30:00',
        'overhead_minutes': 50,
        'expected_minutes': 480,
        'overtime_minutes': 0,
      };
      final log = TimeLog.fromJson(json);
      expect(log.overheadMinutes, 50);
      expect(log.morningOverheadMinutes, 25);
      expect(log.eveningOverheadMinutes, 25);
    });

    test('toJson includes both legacy and new fields', () {
      final log = TimeLog(
        date: '2024-01-15',
        startTime: '07:30:00',
        expectedMinutes: 480,
        morningOverheadMinutes: 10,
        morningProductiveCommuteMinutes: 15,
        eveningOverheadMinutes: 15,
        eveningProductiveCommuteMinutes: 15,
        overtimeMinutes: 0,
      );
      final json = log.toJson();
      expect(json['morning_overhead_minutes'], 10);
      expect(json['evening_overhead_minutes'], 15);
      expect(json['overhead_minutes'], 25);
      expect(json['productive_commute_minutes'], 30);
    });
  });
}
