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

    if (dek == null) throw Exception('Encryption key not loaded');

    final plaintext = jsonEncode(json);
    final ciphertext = await CryptoService.encrypt(plaintext, dek);
    final row = await _client.from('travel_presets').insert({
      'user_id': userId,
      'name': preset.name,
      'encrypted_data': ciphertext,
    }).select().single();
    final decrypted = await _decryptPreset(Map<String, dynamic>.from(row), dek);
    return decrypted ?? (throw Exception('Failed to decrypt inserted row'));
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    final userId = _userId;
    final dek = _dek;
    if (userId == null || dek == null) return;

    fields.remove('id');
    fields.remove('user_id');
    fields.remove('created_at');
    fields.remove('encrypted_data');
    final name = fields.remove('name') as String?;

    if (fields.isEmpty && name == null) return;

    // Read existing encrypted data, merge changes, re-encrypt full payload
    final row = await _client
        .from('travel_presets')
        .select('encrypted_data')
        .eq('id', id)
        .eq('user_id', userId)
        .limit(1)
        .single();

    final existingEncrypted = Map<String, dynamic>.from(row)['encrypted_data'] as String?;
    if (existingEncrypted == null || existingEncrypted.isEmpty) return;

    final existingPlaintext = await CryptoService.decrypt(existingEncrypted, dek);
    final existingJson = jsonDecode(existingPlaintext) as Map<String, dynamic>;
    existingJson.addAll(fields);

    final merged = jsonEncode(existingJson);
    final ciphertext = await CryptoService.encrypt(merged, dek);
    final updateFields = <String, dynamic>{
      'encrypted_data': ciphertext,
    };
    if (name != null) updateFields['name'] = name;
    await _client.from('travel_presets').update(updateFields).eq('id', id).eq('user_id', userId);
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

    // No encrypted data or no DEK loaded — can't decrypt
    if (encrypted == null || encrypted.isEmpty || dek == null) return null;

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
      return null;
    }
  }
}
