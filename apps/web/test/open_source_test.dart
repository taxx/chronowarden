import 'package:chronowarden/app_info.dart';
import 'package:chronowarden/screens/about_screen.dart';
import 'package:chronowarden/widgets/about_app_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppInfo', () {
    test('exposes well-formed, consistent project URLs', () {
      for (final url in [
        AppInfo.repoUrl,
        AppInfo.issuesUrl,
        AppInfo.readmeUrl,
        AppInfo.licenseUrl,
        AppInfo.hostedUrl,
      ]) {
        final uri = Uri.parse(url);
        expect(uri.isAbsolute, isTrue, reason: '$url should be absolute');
        expect(uri.scheme, 'https');
      }

      expect(AppInfo.repoUrl, 'https://github.com/taxx/chronowarden');
      expect(AppInfo.issuesUrl, '${AppInfo.repoUrl}/issues');
      expect(AppInfo.readmeUrl, '${AppInfo.repoUrl}/blob/main/README.md');
      expect(AppInfo.licenseUrl, '${AppInfo.repoUrl}/blob/main/LICENSE');
      expect(AppInfo.licenseName, 'MIT License');
    });
  });

  group('AboutAppSection', () {
    testWidgets('surfaces the repo, license and issue tracker', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: AboutAppSection())),
        ),
      );

      expect(find.text('About & Open Source'), findsOneWidget);
      expect(find.textContaining('MIT License'), findsWidgets);
      expect(find.text('About ChronoWarden'), findsOneWidget);
      expect(find.text("What's New"), findsOneWidget);
      expect(find.text('Check for updates'), findsOneWidget);
      expect(find.text('View source on GitHub'), findsOneWidget);
      expect(find.text('Report an issue'), findsOneWidget);
    });
  });

  group('AboutScreen', () {
    testWidgets('explains open source, self-hosting and the hosted instance', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AboutScreen()));

      expect(find.text('About ChronoWarden'), findsOneWidget);
      expect(find.text('Open Source'), findsOneWidget);
      expect(find.text("What's New"), findsOneWidget);
      expect(find.text('View changelog'), findsOneWidget);
      expect(find.text('Host It Yourself'), findsOneWidget);
      expect(find.text('The Hosted Instance'), findsOneWidget);
      expect(find.textContaining(AppInfo.hostedUrl), findsOneWidget);
      expect(find.text('View source on GitHub'), findsOneWidget);
      expect(find.text('Report an issue or request a feature'), findsOneWidget);
      expect(find.text('Self-hosting guide (README)'), findsOneWidget);
    });
  });
}
