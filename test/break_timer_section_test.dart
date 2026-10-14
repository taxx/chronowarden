import 'package:chronowarden/widgets/break_timer_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {double width = 272}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: width, child: child)),
      ),
    );
  }

  BreakTimerSection section({required bool active}) => BreakTimerSection(
        icon: Icons.work_off_outlined,
        label: 'Non-work time',
        minutes: 25,
        startTime: active ? DateTime.now() : null,
        endTime: null,
        active: active,
        onStart: () {},
        onStop: () {},
        onEdit: () {},
        theme: ThemeData.light(),
        color: Colors.blue,
        onColor: Colors.white,
      );

  testWidgets('running row does not overflow on a narrow screen',
      (tester) async {
    await tester.pumpWidget(wrap(section(active: true)));
    expect(tester.takeException(), isNull);
    // The live timer stays fully visible.
    expect(find.textContaining(':'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
  });

  testWidgets('idle row keeps the minutes and buttons visible when narrow',
      (tester) async {
    await tester.pumpWidget(wrap(section(active: false)));
    expect(tester.takeException(), isNull);
    expect(find.text('25 min'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
  });
}
