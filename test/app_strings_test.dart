import 'dart:io';

import 'package:chronowarden/l10n/app_strings.dart';
import 'package:chronowarden/l10n/app_strings_sv.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every English string passed to `context.t(...)` / `ctx.t(...)` must have a
/// Swedish entry, and every Swedish entry must still be used. This keeps the
/// map-keyed catalog honest without code generation.
void main() {
  test('Swedish catalog covers every t() call and has no stale entries', () {
    final keys = _extractTranslationKeys();

    final missing = keys.difference(svCatalog.keys.toSet()).toList()..sort();
    final stale = svCatalog.keys.toSet().difference(keys).toList()..sort();

    expect(
      missing,
      isEmpty,
      reason:
          'Missing Swedish translations (${missing.length}):\n${missing.map((k) => '  - $k').join('\n')}',
    );
    expect(
      stale,
      isEmpty,
      reason:
          'Unused Swedish entries (${stale.length}):\n${stale.map((k) => '  - $k').join('\n')}',
    );
  });

  group('AppStrings', () {
    test('falls back to English for unknown keys', () {
      const sv = AppStringsSv();
      expect(sv.translate('Some string that has no translation'), 'Some string that has no translation');
    });

    test('substitutes placeholders', () {
      final sv = AppStringsSv();
      expect(sv.translate('Snooze {minutes}m', {'minutes': 10}), contains('10'));
    });

    test('English catalog translates with placeholder substitution', () {
      const en = AppStringsEn();
      expect(en.translate('Hello'), 'Hello');
      expect(en.translate('{n} days', {'n': 3}), '3 days');
    });
  });
}

/// Scan `lib/` for `.t('…')` calls and return the concatenated literal keys.
Set<String> _extractTranslationKeys() {
  final keys = <String>{};
  final dir = Directory('lib');
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.contains('/l10n/')) continue;
    keys.addAll(_keysInSource(entity.readAsStringSync()));
  }
  return keys;
}

Set<String> _keysInSource(String source) {
  final keys = <String>{};
  var i = 0;
  while (true) {
    final idx = source.indexOf('.t(', i);
    if (idx < 0) break;
    i = idx + 3;
    final parsed = _parseFirstArgument(source, i);
    if (parsed != null) keys.add(parsed);
  }
  return keys;
}

/// Parse the first argument of a `t(...)` call starting at [start].
///
/// Supports adjacent string literals (`'a ' 'b'`) which Dart concatenates.
/// Returns null when the argument is not a literal (e.g. a variable).
String? _parseFirstArgument(String source, int start) {
  var i = start;
  final buffer = StringBuffer();
  var sawLiteral = false;

  while (i < source.length) {
    // Skip whitespace.
    while (i < source.length && _isWhitespace(source.codeUnitAt(i))) {
      i++;
    }
    if (i >= source.length) break;
    final c = source[i];
    if (c == "'" || c == '"') {
      final parsed = _readLiteral(source, i);
      if (parsed == null) return null;
      buffer.write(parsed.value);
      i = parsed.next;
      sawLiteral = true;
      continue;
    }
    break;
  }

  return sawLiteral ? buffer.toString() : null;
}

bool _isWhitespace(int code) =>
    code == 0x20 || code == 0x09 || code == 0x0a || code == 0x0d;

class _Literal {
  final String value;
  final int next;
  _Literal(this.value, this.next);
}

/// Read a single- or double-quoted string literal starting at [start].
_Literal? _readLiteral(String source, int start) {
  final quote = source[start];
  final buffer = StringBuffer();
  var i = start + 1;
  while (i < source.length) {
    final c = source[i];
    if (c == r'\') {
      if (i + 1 >= source.length) return null;
      final next = source[i + 1];
      switch (next) {
        case 'n':
          buffer.write('\n');
          break;
        case 't':
          buffer.write('\t');
          break;
        case 'r':
          buffer.write('\r');
          break;
        default:
          buffer.write(next);
      }
      i += 2;
      continue;
    }
    if (c == quote) {
      // Handle adjacent literal in the caller (return after this one).
      return _Literal(buffer.toString(), i + 1);
    }
    if (c == r'$') {
      // Interpolation would make this a non-static key; bail out.
      return null;
    }
    buffer.write(c);
    i++;
  }
  return null;
}
