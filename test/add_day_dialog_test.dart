import 'package:chronowarden/models/travel_preset.dart';
import 'package:chronowarden/widgets/add_day_dialog.dart';
import 'package:chronowarden/widgets/commute_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _preset = TravelPreset(
  id: 'p1',
  name: 'Train',
  morningOverheadMinutes: 10,
  morningProductiveCommuteMinutes: 15,
  eveningOverheadMinutes: 20,
  eveningProductiveCommuteMinutes: 5,
);

Future<void> _open(WidgetTester tester, {String? initialPresetId}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AddDayDialog(
                initialDate: DateTime(2026, 9, 1),
                expectedMinutes: 480,
                travelPresets: const [_preset],
                initialPresetId: initialPresetId,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders the shared dialog with the commute summary',
      (tester) async {
    await _open(tester);

    expect(find.text('Add a past day'), findsOneWidget);
    expect(find.byType(CommuteSummary), findsOneWidget);
    expect(find.text('8h per day'), findsOneWidget);

    // Approved divergence: the preset dropdown shows the overhead suffix.
    expect(find.text('Train (+30 min)'), findsOneWidget);
  });

  testWidgets('selects the preset matching initialPresetId', (tester) async {
    await _open(tester, initialPresetId: 'p1');
    expect(find.text('Train (+30 min)'), findsOneWidget);
  });
}
