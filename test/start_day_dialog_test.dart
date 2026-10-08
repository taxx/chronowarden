import 'package:chronowarden/models/travel_preset.dart';
import 'package:chronowarden/services/preferences_service.dart';
import 'package:chronowarden/widgets/start_stop_day_dialogs.dart';
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

Future<StartDayResult?> _openAndConfirm(
  WidgetTester tester, {
  String? note,
}) async {
  StartDayResult? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<StartDayResult>(
                context: context,
                builder: (_) => const StartDayDialog(
                  expectedMinutes: 480,
                  travelPresets: [_preset],
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  if (note != null) {
    await tester.enterText(find.byType(TextField), note);
    await tester.pump();
  }

  await tester.tap(find.text('Start'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows a note field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const StartDayDialog(
                  expectedMinutes: 480,
                  travelPresets: [_preset],
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

    expect(find.text('Note'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('returns the typed note', (tester) async {
    final result = await _openAndConfirm(tester, note: '  Worked on release  ');
    expect(result, isNotNull);
    expect(result!.note, 'Worked on release');
  });

  testWidgets('returns null note when left empty', (tester) async {
    final result = await _openAndConfirm(tester);
    expect(result, isNotNull);
    expect(result!.note, isNull);
  });

  testWidgets('lunch slider allows a 6-hour break', (tester) async {
    StartDayResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<StartDayResult>(
                  context: context,
                  builder: (_) => const StartDayDialog(
                    expectedMinutes: 480,
                    travelPresets: [_preset],
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final lunchSlider = tester.widget<Slider>(find.byType(Slider).first);
    expect(lunchSlider.max, PreferencesService.maxLunchMinutes.toDouble());

    lunchSlider.onChanged!(300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.lunchMinutes, 300);
  });
}
