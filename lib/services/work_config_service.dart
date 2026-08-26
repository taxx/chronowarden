import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/work_config.dart';
import 'auth_service.dart';
import 'crypto_service.dart';
import 'supabase_service.dart';

/// Reads and writes the per-user work-time configuration.
///
/// Data lives inside the `encrypted_data` column of `user_settings`,
/// encrypted with the user's DEK.
class WorkConfigService {
  SupabaseClient get _client => SupabaseService.instance.client;

  String? get _userId {
    final session = _client.auth.currentSession;
    return session?.user.id;
  }

  SecretKey? get _dek => AuthService().dek;

  /// Fetch the current work config, or `null` if no row exists yet.
  Future<WorkConfig?> get() async {
    final userId = _userId;
    final dek = _dek;
    if (userId == null) return null;

    final resp = await _client
        .from('user_settings')
        .select('*')
        .eq('user_id', userId)
        .limit(1);
    final rows = resp as List<dynamic>;
    if (rows.isEmpty) return null;
    final row = rows.first as Map<String, dynamic>;
    final encrypted = row['encrypted_data'] as String?;

    // Fallback: if no encrypted data yet, read plaintext columns directly
    if (encrypted == null || encrypted.isEmpty || dek == null) {
      return WorkConfig.fromJson(row);
    }

    try {
      final plaintext = await CryptoService.decrypt(encrypted, dek);
      final json = jsonDecode(plaintext) as Map<String, dynamic>;
      json['user_id'] = userId;
      return WorkConfig.fromJson(json);
    } catch (_) {
      // Fallback on decryption failure: read plaintext
      return WorkConfig.fromJson(row);
    }
  }

  /// Save (upsert) a work config for the current user.
  ///
  /// Reads the existing encrypted_data, merges in the new config fields,
  /// re-encrypts, and stores.
  Future<void> save(WorkConfig config) async {
    final userId = _userId;
    final dek = _dek;
    if (userId == null) return;

    // Pre-migration: save directly to plaintext columns
    if (dek == null) {
      await _client.from('user_settings').upsert({
        'user_id': userId,
        'default_expected_minutes': config.defaultExpectedMinutes,
        'reduced_expected_minutes': config.reducedExpectedMinutes,
        'reduced_start_week': config.reducedStartWeek,
        'reduced_end_week': config.reducedEndWeek,
      }, onConflict: 'user_id');
      return;
    }

    // Post-migration: encrypt and store in encrypted_data
    final existing = await _readEncryptedSettings(userId, dek);
    existing.addAll(config.toJson());
    existing.remove('user_id');
    existing.remove('id');

    final plaintext = jsonEncode(existing);
    final ciphertext = await CryptoService.encrypt(plaintext, dek);

    await _client.from('user_settings').upsert({
      'user_id': userId,
      'encrypted_data': ciphertext,
    }, onConflict: 'user_id');
  }

  /// Read all encrypted settings from user_settings, decrypted.
  /// Falls back to plaintext columns if no encrypted data.
  Future<Map<String, dynamic>> _readEncryptedSettings(
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

      // Fallback: plaintext columns
      if (encrypted == null || encrypted.isEmpty || dek == null) {
        final result = <String, dynamic>{};
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
        if (row['default_flex_minutes'] != null) {
          result['default_flex_minutes'] = row['default_flex_minutes'];
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
