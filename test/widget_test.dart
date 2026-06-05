import 'package:flutter_test/flutter_test.dart';
import 'package:chronowarden/main.dart';

void main() {
  testWidgets('app shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const ChronoWardenApp());
    expect(find.text('ChronoWarden'), findsOneWidget);
  });
}
