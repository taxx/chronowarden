import 'package:chronowarden/models/time_log.dart';
import 'package:chronowarden/models/travel_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TimeLog makeLog({
    int morningOverhead = 0,
    int morningProductive = 0,
    int eveningOverhead = 0,
    int eveningProductive = 0,
  }) {
    return TimeLog(
      date: '2026-10-09',
      startTime: '07:30:00',
      expectedMinutes: 480,
      morningOverheadMinutes: morningOverhead,
      morningProductiveCommuteMinutes: morningProductive,
      eveningOverheadMinutes: eveningOverhead,
      eveningProductiveCommuteMinutes: eveningProductive,
      overtimeMinutes: 0,
    );
  }

  group('TravelPreset.usesTransit', () {
    test('is true only for the transit commute mode', () {
      expect(
        const TravelPreset(name: 'Train', commuteMode: CommuteMode.transit)
            .usesTransit,
        isTrue,
      );
      for (final mode in [
        CommuteMode.none,
        CommuteMode.car,
        CommuteMode.vespa,
      ]) {
        expect(
          TravelPreset(name: 'x', commuteMode: mode).usesTransit,
          isFalse,
          reason: '$mode should not use transit',
        );
      }
    });
  });

  group('TravelPreset.matchesLog', () {
    test('matches when all four commute values are equal', () {
      const preset = TravelPreset(
        name: 'Train',
        morningOverheadMinutes: 10,
        morningProductiveCommuteMinutes: 20,
        eveningOverheadMinutes: 15,
        eveningProductiveCommuteMinutes: 25,
      );
      expect(
        preset.matchesLog(makeLog(
          morningOverhead: 10,
          morningProductive: 20,
          eveningOverhead: 15,
          eveningProductive: 25,
        )),
        isTrue,
      );
    });

    test('does not match when any value differs', () {
      const preset = TravelPreset(
        name: 'Train',
        morningOverheadMinutes: 10,
        eveningOverheadMinutes: 15,
      );
      expect(preset.matchesLog(makeLog(morningOverhead: 11)), isFalse);
      expect(preset.matchesLog(makeLog(eveningOverhead: 0)), isFalse);
    });
  });

  group('findPresetForLog', () {
    test('returns the matching preset', () {
      const wfh = TravelPreset(name: 'Work from home');
      const train = TravelPreset(
        name: 'Train',
        commuteMode: CommuteMode.transit,
        morningOverheadMinutes: 10,
        eveningOverheadMinutes: 10,
      );

      final matched = findPresetForLog([wfh, train], makeLog(morningOverhead: 10, eveningOverhead: 10));
      expect(matched, isNotNull);
      expect(matched!.name, 'Train');
      expect(matched.usesTransit, isTrue);
    });

    test('maps an all-zero log to the work-from-home preset', () {
      const wfh = TravelPreset(name: 'Work from home');
      const train = TravelPreset(
        name: 'Train',
        commuteMode: CommuteMode.transit,
        morningOverheadMinutes: 10,
        eveningOverheadMinutes: 10,
      );

      final matched = findPresetForLog([wfh, train], makeLog());
      expect(matched, isNotNull);
      expect(matched!.usesTransit, isFalse);
    });

    test('returns null when nothing matches', () {
      const train = TravelPreset(
        name: 'Train',
        commuteMode: CommuteMode.transit,
        morningOverheadMinutes: 10,
      );
      expect(findPresetForLog([train], makeLog(eveningOverhead: 99)), isNull);
      expect(findPresetForLog(const [], makeLog()), isNull);
    });
  });
}
