import 'package:chronowarden/widgets/update_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the message with reload and dismiss actions', (
    tester,
  ) async {
    var reloaded = false;
    var dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateBanner(
            message: 'A new version (bbb2222) is available.',
            onReload: () => reloaded = true,
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );

    expect(find.textContaining('new version'), findsOneWidget);

    await tester.tap(find.text('Reload'));
    expect(reloaded, isTrue);

    await tester.tap(find.byIcon(Icons.close));
    expect(dismissed, isTrue);
  });
}
