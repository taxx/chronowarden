import 'package:chronowarden/widgets/recovery_phrase_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _phrase =
    'abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon abandon abandon abandon abandon art';

Widget _wrap(Brightness brightness, Widget child) {
  return MaterialApp(
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFF1E3A5F),
      brightness: brightness,
      useMaterial3: true,
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

Color? _outerColor(WidgetTester tester, Type widgetType) {
  final container = tester.widget<Container>(
    find
        .descendant(of: find.byType(widgetType), matching: find.byType(Container))
        .first,
  );
  return (container.decoration as BoxDecoration).color;
}

void main() {
  testWidgets('recovery phrase renders on theme surface in both modes',
      (tester) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        _wrap(brightness, const RecoveryPhraseCard(phrase: _phrase)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recovery Phrase'), findsOneWidget);
      expect(find.text(_phrase), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);

      // Regression: the panel must use a theme colour, not hardcoded
      // Colors.amber.shade50 (which made dark-mode text unreadable).
      final context =
          tester.element(find.byType(RecoveryPhraseCard));
      final scheme = Theme.of(context).colorScheme;
      expect(_outerColor(tester, RecoveryPhraseCard), scheme.tertiaryContainer);

      // The phrase itself sits on a surface with matching foreground.
      final phraseText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(phraseText.style?.color, scheme.onSurface);
    }
  });

  testWidgets('recovery warning uses error container colours in both modes',
      (tester) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        _wrap(
          brightness,
          const RecoveryWarningCard(message: 'data is gone forever'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.text('data is gone forever'), findsOneWidget);

      final context =
          tester.element(find.byType(RecoveryWarningCard));
      final scheme = Theme.of(context).colorScheme;
      expect(_outerColor(tester, RecoveryWarningCard), scheme.errorContainer);
    }
  });

  testWidgets('title can be hidden for dialog usage', (tester) async {
    await tester.pumpWidget(
      _wrap(Brightness.light, const RecoveryPhraseCard(phrase: _phrase, title: null)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recovery Phrase'), findsNothing);
    expect(find.text(_phrase), findsOneWidget);
  });
}
