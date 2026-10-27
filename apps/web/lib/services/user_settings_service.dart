import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'api_client.dart';
import 'auth_service.dart';
import 'crypto_service.dart';

/// Reads and writes per-user settings from the `encrypted_data` of the single
/// `user_settings` row.
///
/// The envelope columns (encrypted_dek, kek_salt, …) live in the same row but
/// are managed by [AuthService] — this service only touches the encrypted
/// settings payload.
class UserSettingsService {
  ApiClient get _api => ApiClient();

  String? get _userId => AuthService().profile?.id;

  SecretKey? get _dek => AuthService().dek;

  Future<int> getDefaultFlexMinutes() async {
    final settings = await _readSettings();
    return (settings['default_flex_minutes'] as int?) ?? 0;
  }

  Future<void> setDefaultFlexMinutes(int minutes) async {
    final settings = await _readSettings();
    settings['default_flex_minutes'] = minutes;
    await _writeSettings(settings);
  }

  /// UI language code stored in the encrypted settings (e.g. "en", "sv").
  Future<String?> getLanguage() async {
    final settings = await _readSettings();
    return settings['language'] as String?;
  }

  Future<void> setLanguage(String code) async {
    final settings = await _readSettings();
    settings['language'] = code;
    await _writeSettings(settings);
  }

  /// Whether the non-work-time feature is enabled. Defaults to `true`.
  Future<bool> getNonWorkEnabled() async {
    final settings = await _readSettings();
    return (settings['non_work_enabled'] as bool?) ?? true;
  }

  Future<void> setNonWorkEnabled(bool enabled) async {
    final settings = await _readSettings();
    settings['non_work_enabled'] = enabled;
    await _writeSettings(settings);
  }

  // -----------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------

  Future<Map<String, dynamic>> _readSettings() async {
    final dek = _dek;
    if (_userId == null || dek == null) return {};

    try {
      final resp = await _api.get('/settings');
      if (resp is! Map<String, dynamic>) return {};
      final encrypted = resp['encrypted_data'] as String?;
      if (encrypted == null || encrypted.isEmpty) return {};
      return jsonDecode(await CryptoService.decrypt(encrypted, dek)) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeSettings(Map<String, dynamic> settings) async {
    final dek = _dek;
    if (_userId == null || dek == null) return;

    final ciphertext = await CryptoService.encrypt(jsonEncode(settings), dek);
    await _api.patch('/settings', {'encrypted_data': ciphertext});
  }
}
