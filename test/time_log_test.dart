import 'package:chronowarden/models/time_log.dart';
import 'package:chronowarden/models/travel_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeLog.leaveTime', () {
    // Helper to create a TimeLog with the given values
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
        overheadMinutes: overheadMinutes,
        lunchMinutes: lunchMinutes,
        productiveCommuteMinutes: productiveCommuteMinutes,
        overtimeMinutes: 0,
      );
    }

    test('no productive commute — leave time = start + expected + lunch', () {
      final log = makeLog(productiveCommuteMinutes: 0);
      // Formula: start + expected + lunch (overhead not included)
      final leave = log.leaveTime;
      final expected = DateTime(2024, 1, 15, 7, 30)
          .add(const Duration(minutes: 480));
      expect(leave, expected);
    });

    test('with productive commute — leave time subtracts evening portion', () {
      // User works 60 min on train (30 each direction)
      // Evening portion (30 min) subtracted from leave time
      final log = makeLog(
        startTime: '07:30:00',
        expectedMinutes: 480,
        overheadMinutes: 50,
        productiveCommuteMinutes: 60,
      );
      final leave = log.leaveTime;
      // start + expected + lunch - (productiveCommute ~/ 2)
      // = 07:30 + 480 - 30 = 07:30 + 450 = 15:00
      final expected = DateTime(2024, 1, 15, 7, 30)
          .add(const Duration(minutes: 480 - 30));
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
      // 07:30 + 480 + 30 - 30 = 07:30 + 480 = 15:30
      final expected = DateTime(2024, 1, 15, 7, 30)
          .add(const Duration(minutes: 480 + 30 - 30));
      expect(leave, expected);
    });

    test('odd productive commute minutes — integer division truncates', () {
      // 45 min total = 22.5 evening, truncates to 22
      final log = makeLog(
        startTime: '07:30:00',
        expectedMinutes: 480,
        overheadMinutes: 50,
        productiveCommuteMinutes: 45,
      );
      final leave = log.leaveTime;
      final expected = DateTime(2024, 1, 15, 7, 30)
          .add(const Duration(minutes: 480 - 22));
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
        overheadMinutes: overheadMinutes,
        lunchMinutes: lunchMinutes,
        productiveCommuteMinutes: productiveCommuteMinutes,
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

  group('TimeLog.totalExpectedMinutes', () {
    test('sums expected and overhead', () {
      final log = TimeLog(
        date: '2024-01-15',
        startTime: '07:30:00',
        expectedMinutes: 480,
        overheadMinutes: 50,
        lunchMinutes: 30,
        productiveCommuteMinutes: 60,
        overtimeMinutes: 0,
      );
      expect(log.totalExpectedMinutes, 530);
    });
  });

  group('TimeLog.copyWith', () {
    test('includes productiveCommuteMinutes', () {
      final original = TimeLog(
        date: '2024-01-15',
        startTime: '07:30:00',
        expectedMinutes: 480,
        overheadMinutes: 50,
        productiveCommuteMinutes: 60,
        overtimeMinutes: 0,
      );
      final copy = original.copyWith(productiveCommuteMinutes: 30);
      expect(copy.productiveCommuteMinutes, 30);
      expect(original.productiveCommuteMinutes, 60);
    });
  });

  group('TravelPreset JSON round-trip', () {
    test('fromJson parses productive_commute_minutes', () {
      final json = {
        'id': 'test-id',
        'user_id': 'test-user',
        'name': 'Train Commute',
        'default_overhead_minutes': 50,
        'productive_commute_minutes': 60,
        'created_at': '2024-01-01T00:00:00Z',
      };
      final preset = TravelPreset.fromJson(json);
      expect(preset.productiveCommuteMinutes, 60);
    });

    test('fromJson defaults to 0 when field missing', () {
      final json = {
        'name': 'Car Commute',
        'default_overhead_minutes': 30,
      };
      final preset = TravelPreset.fromJson(json);
      expect(preset.productiveCommuteMinutes, 0);
    });

    test('toJson includes productive_commute_minutes', () {
      final preset = TravelPreset(
        name: 'Train',
        defaultOverheadMinutes: 50,
        productiveCommuteMinutes: 60,
      );
      final json = preset.toJson();
      expect(json['productive_commute_minutes'], 60);
    });
  });

  group('TimeLog JSON round-trip', () {
    test('fromJson parses productive_commute_minutes', () {
      final json = {
        'date': '2024-01-15',
        'start_time': '07:30:00',
        'overhead_minutes': 50,
        'expected_minutes': 480,
        'overtime_minutes': 0,
        'productive_commute_minutes': 60,
      };
      final log = TimeLog.fromJson(json);
      expect(log.productiveCommuteMinutes, 60);
    });

    test('fromJson defaults to 0 when field missing', () {
      final json = {
        'date': '2024-01-15',
        'start_time': '07:30:00',
        'overhead_minutes': 50,
        'expected_minutes': 480,
        'overtime_minutes': 0,
      };
      final log = TimeLog.fromJson(json);
      expect(log.productiveCommuteMinutes, 0);
    });

    test('toJson includes productive_commute_minutes', () {
      final log = TimeLog(
        date: '2024-01-15',
        startTime: '07:30:00',
        expectedMinutes: 480,
        overheadMinutes: 50,
        productiveCommuteMinutes: 60,
        overtimeMinutes: 0,
      );
      final json = log.toJson();
      expect(json['productive_commute_minutes'], 60);
    });
  });
}
