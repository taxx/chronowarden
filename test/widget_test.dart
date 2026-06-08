import 'package:chronowarden/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app builds without crashing', (tester) async {
    // ChronoWardenApp is built without Supabase initialized.
    // It shows the _NoConfigScreen placeholder, which we can verify.
    await tester.pumpWidget(const ChronoWardenApp());
    await tester.pump();

    // When no credentials are provided the app shows the config hint.
    expect(find.textContaining('Supabase credentials not found'), findsOneWidget);
  });
}
