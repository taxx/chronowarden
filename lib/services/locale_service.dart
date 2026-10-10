import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_settings_service.dart';

/// App-wide UI language.
///
/// The choice is cached in `SharedPreferences` (so it applies instantly, even
/// before the encryption passphrase unlocks the DEK) and mirrored to the
/// encrypted `user_settings` row so it follows the user across devices.
class LocaleService extends ChangeNotifier {
  LocaleService._();
  static final LocaleService _instance = LocaleService._();
  factory LocaleService() => _instance;

  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = ['en', 'sv'];
  static const _prefKey = 'app_language';

  Locale _locale = const Locale(defaultLanguage);
  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  /// Load the cached language, then try to pull the cross-device value.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefKey);
    if (cached != null && supportedLanguages.contains(cached)) {
      _locale = Locale(cached);
      notifyListeners();
    }
    await syncFromServer();
  }

  /// Pull the language stored in the encrypted user settings (cross-device).
  Future<void> syncFromServer() async {
    try {
      final code = await UserSettingsService().getLanguage();
      if (code != null &&
          supportedLanguages.contains(code) &&
          _locale.languageCode != code) {
        _locale = Locale(code);
        await _cacheLocally(code);
        notifyListeners();
      }
    } catch (_) {
      // Offline / not unlocked — the local cache remains authoritative.
    }
  }

  /// Switch language and persist it (locally + cross-device).
  Future<void> setLanguage(String code) async {
    if (!supportedLanguages.contains(code) || _locale.languageCode == code) {
      return;
    }
    _locale = Locale(code);
    await _cacheLocally(code);
    notifyListeners();
    await UserSettingsService().setLanguage(code);
  }

  Future<void> _cacheLocally(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
  }
}
