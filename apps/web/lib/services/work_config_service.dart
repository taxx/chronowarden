import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../models/work_config.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'crypto_service.dart';

/// Reads and writes the per-user work-time configuration.
///
/// Data lives inside the `encrypted_data` of the single `user_settings` row,
/// encrypted with the user's DEK.
class WorkConfigService {
  ApiClient get _api => ApiClient();

  String? get _userId => AuthService().profile?.id;

  SecretKey? get _dek => AuthService().dek;

  /// Fetch the current work config, or `null` if none exists yet.
  Future<WorkConfig?> get() async {
    final dek = _dek;
    if (_userId == null) return null;

    final settings = await _readEncryptedSettings(dek);
    final ciphertext = settings['encrypted_data'] as String?;
    if (ciphertext == null || ciphertext.isEmpty || dek == null) return null;

    try {
      final json =
          jsonDecode(await CryptoService.decrypt(ciphertext, dek)) as Map<String, dynamic>;
      json['user_id'] = _userId;
      return WorkConfig.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Save (merge) a work config for the current user.
  Future<void> save(WorkConfig config) async {
    final dek = _dek;
    if (_userId == null || dek == null) return;

    final existing = await _readDecryptedSettings(dek);
    existing.addAll(config.toJson());
    existing.remove('user_id');
    existing.remove('id');

    final ciphertext = await CryptoService.encrypt(jsonEncode(existing), dek);
    await _api.patch('/settings', {'encrypted_data': ciphertext});
  }

  Future<Map<String, dynamic>> _readEncryptedSettings(SecretKey? dek) async {
    try {
      final resp = await _api.get('/settings');
      if (resp is Map<String, dynamic>) return resp;
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _readDecryptedSettings(SecretKey? dek) async {
    try {
      final row = await _readEncryptedSettings(dek);
      final ciphertext = row['encrypted_data'] as String?;
      if (ciphertext == null || ciphertext.isEmpty || dek == null) return {};
      return jsonDecode(await CryptoService.decrypt(ciphertext, dek)) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
