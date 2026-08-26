import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'crypto_service.dart';
import 'supabase_service.dart';

/// Reads and writes per-user settings from the `encrypted_data` column
/// of [user_settings].
///
/// The envelope columns (encrypted_dek, kek_salt, etc.) live in the same
/// table but are managed by [AuthService] — this service only touches
/// the encrypted settings payload.
class UserSettingsService {
  SupabaseClient get _client => SupabaseService.instance.client;

  String? get _userId {
    final session = _client.auth.currentSession;
    return session?.user.id;
  }

  SecretKey? get _dek => AuthService().dek;

  Future<int> getDefaultFlexMinutes() async {
    final userId = _userId;
    final dek = _dek;
    if (userId == null || dek == null) return 0;

    final settings = await _readSettings(userId, dek);
    return (settings['default_flex_minutes'] as int?) ?? 0;
  }

  Future<void> setDefaultFlexMinutes(int minutes) async {
    final userId = _userId;
    final dek = _dek;
    if (userId == null || dek == null) return;

    final settings = await _readSettings(userId, dek);
    settings['default_flex_minutes'] = minutes;

    final plaintext = jsonEncode(settings);
    final ciphertext = await CryptoService.encrypt(plaintext, dek);

    await _client.from('user_settings').upsert({
      'user_id': userId,
      'encrypted_data': ciphertext,
    }, onConflict: 'user_id');
  }

  // -----------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------

  Future<Map<String, dynamic>> _readSettings(
    String userId,
    SecretKey dek,
  ) async {
    try {
      final resp = await _client
          .from('user_settings')
          .select('encrypted_data')
          .eq('user_id', userId)
          .limit(1);
      final rows = resp as List<dynamic>;
      if (rows.isEmpty) return {};
      final row = rows.first as Map<String, dynamic>;
      final encrypted = row['encrypted_data'] as String?;
      if (encrypted == null || encrypted.isEmpty) return {};
      final plaintext = await CryptoService.decrypt(encrypted, dek);
      return jsonDecode(plaintext) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
