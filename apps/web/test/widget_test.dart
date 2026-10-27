import 'package:chronowarden/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app builds without crashing', (tester) async {
    // ChronoWardenApp is built without calling main(), so AuthService has not
    // finished initialising — the root shows a loading indicator.
    await tester.pumpWidget(const ChronoWardenApp());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
