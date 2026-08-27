import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/travel_preset.dart';
import 'auth_service.dart';
import 'crypto_service.dart';
import 'supabase_service.dart';

/// Data service for travel presets with envelope encryption.
class TravelPresetService {
  SupabaseClient get _client => SupabaseService.instance.client;

  String? get _userId {
    final session = _client.auth.currentSession;
    return session?.user.id;
  }

  SecretKey? get _dek => AuthService().dek;

  Future<List<TravelPreset>> all() async {
    final userId = _userId;
    if (userId == null) return [];

    final resp = await _client
        .from('travel_presets')
        .select()
        .eq('user_id', userId)
        .order('name');
    final rows = resp as List<dynamic>;
    final results = <TravelPreset>[];
    final dek = _dek;
    for (final r in rows) {
      final map = r as Map<String, dynamic>;
      final preset = await _decryptPreset(map, dek);
      if (preset != null) results.add(preset);
    }
    return results;
  }

  Future<TravelPreset> insert(TravelPreset preset) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final dek = _dek;
    final json = preset.toJson();
    json.remove('id');
    json.remove('created_at');
    json.remove('encrypted_data');
    json['user_id'] = userId;

    if (dek != null) {
      // Post-migration: encrypt and store
      final plaintext = jsonEncode(json);
      final ciphertext = await CryptoService.encrypt(plaintext, dek);
      // Include legacy columns to satisfy NOT NULL constraints
      final row = await _client.from('travel_presets').insert({
        'user_id': userId,
        'name': preset.name,
        'encrypted_data': ciphertext,
        // Legacy columns (will be dropped later)
        'default_overhead_minutes': preset.defaultOverheadMinutes,
        'productive_commute_minutes': preset.productiveCommuteMinutes,
        'morning_overhead_minutes': preset.morningOverheadMinutes,
        'morning_productive_commute_minutes': preset.morningProductiveCommuteMinutes,
        'evening_overhead_minutes': preset.eveningOverheadMinutes,
        'evening_productive_commute_minutes': preset.eveningProductiveCommuteMinutes,
      }).select().single();
      final decrypted = await _decryptPreset(Map<String, dynamic>.from(row), dek);
      return decrypted ?? preset;
    } else {
      // Pre-migration: store in plaintext columns directly
      json['name'] = preset.name;
      json['morning_overhead_minutes'] = preset.morningOverheadMinutes;
      json['morning_productive_commute_minutes'] = preset.morningProductiveCommuteMinutes;
      json['evening_overhead_minutes'] = preset.eveningOverheadMinutes;
      json['evening_productive_commute_minutes'] = preset.eveningProductiveCommuteMinutes;
      final row = await _client.from('travel_presets').insert(json).select().single();
      return TravelPreset.fromJson(Map<String, dynamic>.from(row));
    }
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    final userId = _userId;
    if (userId == null) return;

    fields.remove('id');
    fields.remove('user_id');
    fields.remove('created_at');
    fields.remove('encrypted_data');
    final name = fields.remove('name') as String?;

    if (fields.isEmpty) return;

    final dek = _dek;
    if (dek != null) {
      // Post-migration: encrypt changed fields
      final plaintext = jsonEncode(fields);
      final ciphertext = await CryptoService.encrypt(plaintext, dek);
      final updateFields = <String, dynamic>{
        'encrypted_data': ciphertext,
      };
      if (name != null) updateFields['name'] = name;
      await _client.from('travel_presets').update(updateFields).eq('id', id).eq('user_id', userId);
    } else {
      // Pre-migration: update plaintext columns directly
      if (name != null) fields['name'] = name;
      await _client.from('travel_presets').update(fields).eq('id', id).eq('user_id', userId);
    }
  }

  Future<void> delete(String id) async {
    final userId = _userId ?? '';
    await _client.from('travel_presets').delete().eq('id', id).eq('user_id', userId);
  }

  // -----------------------------------------------------------------
  // Encryption helpers
  // -----------------------------------------------------------------

  Future<TravelPreset?> _decryptPreset(
    Map<String, dynamic> row,
    SecretKey? dek,
  ) async {
    final encrypted = row['encrypted_data'] as String?;

    // Pre-migration: no encrypted data yet — fall back to plaintext columns
    if (encrypted == null || encrypted.isEmpty) {
      return TravelPreset.fromJson(row);
    }

    // Post-migration but no DEK loaded — user must enter passphrase
    if (dek == null) return null;

    // Normal path: decrypt
    try {
      final plaintext = await CryptoService.decrypt(encrypted, dek);
      final json = jsonDecode(plaintext) as Map<String, dynamic>;

      // Merge with plaintext envelope fields
      json['id'] = row['id'];
      json['user_id'] = row['user_id'];
      json['name'] = row['name'];
      json['created_at'] = row['created_at'];

      return TravelPreset.fromJson(json);
    } catch (_) {
      // Decryption failed — don't fall back to plaintext
      return null;
    }
  }
}
