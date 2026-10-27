import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../models/travel_preset.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'crypto_service.dart';

/// Data service for travel presets with envelope encryption.
class TravelPresetService {
  ApiClient get _api => ApiClient();

  String? get _userId => AuthService().profile?.id;

  SecretKey? get _dek => AuthService().dek;

  Future<List<TravelPreset>> all() async {
    if (_userId == null) return [];

    final resp = await _api.get('/travel-presets') as List<dynamic>;
    final results = <TravelPreset>[];
    final dek = _dek;
    for (final r in resp) {
      final preset = await _decryptPreset(r as Map<String, dynamic>, dek);
      if (preset != null) results.add(preset);
    }
    return results;
  }

  Future<TravelPreset> insert(TravelPreset preset) async {
    if (_userId == null) throw Exception('Not authenticated');
    final dek = _dek;
    if (dek == null) throw Exception('Encryption key not loaded');

    final json = preset.toJson();
    json.remove('id');
    json.remove('created_at');
    json.remove('encrypted_data');
    json.remove('user_id');

    final ciphertext = await CryptoService.encrypt(jsonEncode(json), dek);
    final row = await _api.post('/travel-presets', {
      'name': preset.name,
      'encrypted_data': ciphertext,
    }) as Map<String, dynamic>;

    final decrypted = await _decryptPreset(row, dek);
    return decrypted ?? (throw Exception('Failed to decrypt inserted row'));
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    final dek = _dek;
    if (_userId == null || dek == null) return;

    fields.remove('id');
    fields.remove('user_id');
    fields.remove('created_at');
    fields.remove('encrypted_data');
    final name = fields.remove('name') as String?;
    if (fields.isEmpty && name == null) return;

    final row = await _api.get('/travel-presets/$id') as Map<String, dynamic>;
    final existingEncrypted = row['encrypted_data'] as String?;
    if (existingEncrypted == null || existingEncrypted.isEmpty) return;

    final existingJson =
        jsonDecode(await CryptoService.decrypt(existingEncrypted, dek)) as Map<String, dynamic>;
    existingJson.addAll(fields);

    final ciphertext = await CryptoService.encrypt(jsonEncode(existingJson), dek);
    final update = <String, dynamic>{'encrypted_data': ciphertext};
    if (name != null) update['name'] = name;
    await _api.patch('/travel-presets/$id', update);
  }

  Future<void> delete(String id) async {
    await _api.delete('/travel-presets/$id');
  }

  // -----------------------------------------------------------------
  // Encryption helpers
  // -----------------------------------------------------------------

  Future<TravelPreset?> _decryptPreset(
    Map<String, dynamic> row,
    SecretKey? dek,
  ) async {
    final encrypted = row['encrypted_data'] as String?;
    if (encrypted == null || encrypted.isEmpty || dek == null) return null;

    try {
      final json = jsonDecode(await CryptoService.decrypt(encrypted, dek)) as Map<String, dynamic>;
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
