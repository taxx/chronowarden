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
    if (userId == null) return 0;

    final settings = await _readSettings(userId, _dek);
    return (settings['default_flex_minutes'] as int?) ?? 0;
  }

  Future<void> setDefaultFlexMinutes(int minutes) async {
    final userId = _userId;
    if (userId == null) return;

    final settings = await _readSettings(userId, _dek);
    settings['default_flex_minutes'] = minutes;

    // If no DEK yet (pre-migration), just update the plaintext column
    final dek = _dek;
    if (dek == null) {
      await _client.from('user_settings').upsert({
        'user_id': userId,
        'default_flex_minutes': minutes,
      }, onConflict: 'user_id');
      return;
    }

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
    SecretKey? dek,
  ) async {
    try {
      final resp = await _client
          .from('user_settings')
          .select('*')
          .eq('user_id', userId)
          .limit(1);
      final rows = resp as List<dynamic>;
      if (rows.isEmpty) return {};
      final row = rows.first as Map<String, dynamic>;
      final encrypted = row['encrypted_data'] as String?;

      // Fallback: if no encrypted data or no DEK, read plaintext columns directly
      if (encrypted == null || encrypted.isEmpty || dek == null) {
        final result = <String, dynamic>{};
        if (row['default_flex_minutes'] != null) {
          result['default_flex_minutes'] = row['default_flex_minutes'];
        }
        if (row['default_expected_minutes'] != null) {
          result['default_expected_minutes'] = row['default_expected_minutes'];
        }
        if (row['reduced_expected_minutes'] != null) {
          result['reduced_expected_minutes'] = row['reduced_expected_minutes'];
        }
        if (row['reduced_start_week'] != null) {
          result['reduced_start_week'] = row['reduced_start_week'];
        }
        if (row['reduced_end_week'] != null) {
          result['reduced_end_week'] = row['reduced_end_week'];
        }
        return result;
      }

      final plaintext = await CryptoService.decrypt(encrypted, dek);
      return jsonDecode(plaintext) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
