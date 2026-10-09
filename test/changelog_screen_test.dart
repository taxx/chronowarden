import 'package:chronowarden/screens/changelog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders changelog entries loaded from the asset', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChangelogScreen()));
    await tester.pumpAndSettle();

    expect(find.text("What's New"), findsOneWidget);
    // The generated CHANGELOG.md starts with the most recent commit.
    expect(find.textContaining('Rework leave-time notifications'), findsOneWidget);
  });
}
