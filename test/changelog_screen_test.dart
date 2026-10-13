import 'package:chronowarden/screens/changelog_screen.dart';
import 'package:chronowarden/services/changelog_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the first changelog entry loaded from the asset', (
    tester,
  ) async {
    // Resolve the expected text from the asset itself so the test does not
    // depend on a specific commit message.
    final groups = await ChangelogService().load();
    expect(groups, isNotEmpty);
    final firstEntry = groups.first.entries.first.text;

    await tester.pumpWidget(const MaterialApp(home: ChangelogScreen()));
    await tester.pumpAndSettle();

    expect(find.text("What's New"), findsOneWidget);
    expect(find.textContaining(firstEntry), findsOneWidget);
  });
}
