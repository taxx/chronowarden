import 'package:flutter/widgets.dart';

import 'app_strings_sv.dart';

/// Lightweight, dependency-free localization.
///
/// **English is the source of truth.** Call sites pass the English string to
/// [AppStrings.translate] (usually via the `context.t(...)` extension) and the
/// active locale looks it up in its catalog. A missing translation falls back
/// to the English text, so a partially translated catalog degrades gracefully.
///
/// Interpolation uses `{name}` placeholders:
/// ```dart
/// context.t('Lunch: {minutes} min', {'minutes': lunch});
/// ```
///
/// `tool/../test/app_strings_test.dart` guards the catalog: every `t('…')`
/// call in `lib/` must have a Swedish entry, and every entry must be used.
abstract class AppStrings {
  const AppStrings();

  /// ISO language code this catalog serves (e.g. "en", "sv").
  String get languageCode;

  /// Translation catalog: English source text → translated text.
  Map<String, String> get catalog;

  /// Translate [en], substituting `{placeholders}` from [params].
  String translate(String en, [Map<String, Object?>? params]) {
    final template = catalog[en] ?? en;
    return _substitute(template, params);
  }

  static String _substitute(String template, Map<String, Object?>? params) {
    if (params == null || params.isEmpty) return template;
    var result = template;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', '${value ?? ''}');
    });
    return result;
  }

  /// The catalog for [locale] (English fallback for anything unknown).
  static AppStrings forLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'sv':
        return const AppStringsSv();
      default:
        return const AppStringsEn();
    }
  }
}

/// English catalog — the identity mapping.
class AppStringsEn extends AppStrings {
  const AppStringsEn();

  @override
  String get languageCode => 'en';

  @override
  Map<String, String> get catalog => const {};
}

/// Swedish catalog.
class AppStringsSv extends AppStrings {
  const AppStringsSv();

  @override
  String get languageCode => 'sv';

  @override
  Map<String, String> get catalog => svCatalog;
}

/// Loads the [AppStrings] catalog for the active locale.
class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppStrings.forLocale(locale).languageCode == locale.languageCode ||
      locale.languageCode == 'en';

  @override
  Future<AppStrings> load(Locale locale) async =>
      AppStrings.forLocale(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}

/// `context.t('English text', [params])` — translate from the build context.
///
/// Falls back to English when no [AppStrings] delegate is installed (e.g. in
/// widget tests that pump a bare `MaterialApp`), so English assertions keep
/// working without extra setup.
extension AppStringsContext on BuildContext {
  AppStrings get strings =>
      Localizations.of<AppStrings>(this, AppStrings) ?? const AppStringsEn();

  String t(String en, [Map<String, Object?>? params]) =>
      strings.translate(en, params);
}
