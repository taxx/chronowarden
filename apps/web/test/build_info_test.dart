import 'package:chronowarden/models/build_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BuildInfo.parse', () {
    test('parses the generated JSON', () {
      final info = BuildInfo.parse(
        '{"version":"0.1.0","commit":"b1245a9","built_at":"2026-10-09T20:59:11Z"}',
      );
      expect(info, isNotNull);
      expect(info!.version, '0.1.0');
      expect(info.commit, 'b1245a9');
      expect(info.builtAt, '2026-10-09T20:59:11Z');
      expect(info.isKnown, isTrue);
    });

    test('returns null for malformed input', () {
      expect(BuildInfo.parse('not json'), isNull);
      expect(BuildInfo.parse('[]'), isNull);
      expect(BuildInfo.parse(''), isNull);
    });

    test('missing fields fall back to empty strings', () {
      final info = BuildInfo.parse('{}');
      expect(info, isNotNull);
      expect(info!.commit, isEmpty);
      expect(info.isKnown, isFalse);
    });

    test('a "dev" commit is not a known build', () {
      final info = BuildInfo.parse('{"version":"0.1.0","commit":"dev"}');
      expect(info!.isKnown, isFalse);
    });
  });

  group('isUpdateAvailable', () {
    BuildInfo build(String commit) =>
        BuildInfo(version: '0.1.0', commit: commit, builtAt: '');

    test('prompts when the commits differ', () {
      expect(
        isUpdateAvailable(running: build('aaa1111'), server: build('bbb2222')),
        isTrue,
      );
    });

    test('stays quiet when the commits match', () {
      expect(
        isUpdateAvailable(running: build('aaa1111'), server: build('aaa1111')),
        isFalse,
      );
    });

    test('stays quiet when either side is missing', () {
      expect(isUpdateAvailable(running: null, server: build('bbb2222')), isFalse);
      expect(isUpdateAvailable(running: build('aaa1111'), server: null), isFalse);
    });

    test('stays quiet for dev builds', () {
      expect(
        isUpdateAvailable(running: build('dev'), server: build('bbb2222')),
        isFalse,
      );
      expect(
        isUpdateAvailable(running: build('aaa1111'), server: build('dev')),
        isFalse,
      );
    });

    test('a dismissed server build is suppressed', () {
      expect(
        isUpdateAvailable(
          running: build('aaa1111'),
          server: build('bbb2222'),
          dismissedCommit: 'bbb2222',
        ),
        isFalse,
      );
    });

    test('a dismissal does not suppress the next deploy', () {
      expect(
        isUpdateAvailable(
          running: build('aaa1111'),
          server: build('ccc3333'),
          dismissedCommit: 'bbb2222',
        ),
        isTrue,
      );
    });
  });
}
