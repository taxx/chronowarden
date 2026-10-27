import 'package:chronowarden/models/travel_preset.dart';
import 'package:chronowarden/screens/my_day_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldShowTransitPlanning', () {
    // 2024-01-15 is a Monday.
    final monday = DateTime(2024, 1, 15);
    final friday = DateTime(2024, 1, 19);
    final saturday = DateTime(2024, 1, 20);
    final sunday = DateTime(2024, 1, 21);

    test('shows on weekdays regardless of the weekend setting', () {
      expect(
        shouldShowTransitPlanning(now: monday, showWeekends: false),
        isTrue,
      );
      expect(
        shouldShowTransitPlanning(now: friday, showWeekends: false),
        isTrue,
      );
      expect(
        shouldShowTransitPlanning(now: monday, showWeekends: true),
        isTrue,
      );
    });

    test('hides on weekends by default', () {
      expect(
        shouldShowTransitPlanning(now: saturday, showWeekends: false),
        isFalse,
      );
      expect(
        shouldShowTransitPlanning(now: sunday, showWeekends: false),
        isFalse,
      );
    });

    test('shows on weekends when the user works them', () {
      expect(
        shouldShowTransitPlanning(now: saturday, showWeekends: true),
        isTrue,
      );
      expect(
        shouldShowTransitPlanning(now: sunday, showWeekends: true),
        isTrue,
      );
    });
  });

  group('shouldShowTransitPlanningForPresets', () {
    const wfh = TravelPreset(name: 'Work from home');
    const transit = TravelPreset(
      name: 'Train',
      commuteMode: CommuteMode.transit,
      morningOverheadMinutes: 10,
      eveningOverheadMinutes: 10,
    );

    test('keeps the card visible while presets are still loading', () {
      expect(shouldShowTransitPlanningForPresets(const []), isTrue);
    });

    test('hides when no preset uses transit', () {
      expect(shouldShowTransitPlanningForPresets(const [wfh]), isFalse);
    });

    test('shows when any preset uses transit', () {
      expect(shouldShowTransitPlanningForPresets(const [transit]), isTrue);
      // A stale last-used work-from-home preset must not hide the card.
      expect(shouldShowTransitPlanningForPresets(const [wfh, transit]), isTrue);
    });
  });
}
