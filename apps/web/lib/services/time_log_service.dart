import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../models/time_log.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'crypto_service.dart';

/// Data service for time logs with envelope encryption.
///
/// All data is encrypted with the user's DEK before storage and decrypted
/// after retrieval. Only `date` remains plaintext for server-side filtering;
/// the API scopes every request to the authenticated user.
class TimeLogService {
  ApiClient get _api => ApiClient();

  String? get _userId => AuthService().profile?.id;

  SecretKey? get _dek => AuthService().dek;

  // -----------------------------------------------------------------
  // Query methods
  // -----------------------------------------------------------------

  Future<List<TimeLog>> all() async {
    if (_userId == null) return [];

    final resp = await _api.get('/time-logs') as List<dynamic>;
    final results = <TimeLog>[];
    final dek = _dek;
    for (final r in resp) {
      final timeLog = await _decryptTimeLog(r as Map<String, dynamic>, dek);
      if (timeLog != null) results.add(timeLog);
    }
    return results;
  }

  Future<TimeLog?> today() async {
    if (_userId == null) return null;
    return _byDate(_dateStr(DateTime.now()));
  }

  Future<TimeLog?> activeToday() async {
    final log = await today();
    if (log == null) return null;
    return log.endTime == null ? log : null;
  }

  Future<TimeLog?> _byDate(String date) async {
    final resp = await _api.get('/time-logs', query: {'date': date}) as List<dynamic>;
    if (resp.isEmpty) return null;
    final first = resp.first as Map<String, dynamic>;
    return _decryptTimeLog(first, _dek);
  }

  // -----------------------------------------------------------------
  // Mutation methods
  // -----------------------------------------------------------------

  Future<TimeLog> insert(TimeLog log) async {
    if (_userId == null) throw Exception('Not authenticated');
    final dek = _dek;
    if (dek == null) throw Exception('Encryption key not loaded');

    final json = log.toJson();
    json.remove('id');
    json.remove('created_at');
    json.remove('encrypted_data');
    json.remove('user_id');

    final ciphertext = await CryptoService.encrypt(jsonEncode(json), dek);
    final row = await _api.post('/time-logs', {
      'date': log.date,
      'encrypted_data': ciphertext,
    }) as Map<String, dynamic>;

    final decrypted = await _decryptTimeLog(row, dek);
    return decrypted ?? (throw Exception('Failed to decrypt inserted row'));
  }

  /// Merge [fields] into the encrypted payload of the log with [id].
  Future<void> update(String id, Map<String, dynamic> fields) async {
    final dek = _dek;
    if (_userId == null || dek == null) return;

    fields.remove('user_id');
    fields.remove('id');
    fields.remove('date');
    fields.remove('encrypted_data');
    if (fields.isEmpty) return;

    final row = await _api.get('/time-logs/$id') as Map<String, dynamic>;
    final existingEncrypted = row['encrypted_data'] as String?;
    if (existingEncrypted == null || existingEncrypted.isEmpty) return;

    final existingJson =
        jsonDecode(await CryptoService.decrypt(existingEncrypted, dek)) as Map<String, dynamic>;
    existingJson.addAll(fields);

    final ciphertext = await CryptoService.encrypt(jsonEncode(existingJson), dek);
    await _api.patch('/time-logs/$id', {'encrypted_data': ciphertext});
  }

  Future<void> delete(String id) async {
    await _api.delete('/time-logs/$id');
  }

  // -----------------------------------------------------------------
  // Encryption helpers
  // -----------------------------------------------------------------

  /// Decrypt an encrypted time_log row into a [TimeLog] model.
  Future<TimeLog?> _decryptTimeLog(
    Map<String, dynamic> row,
    SecretKey? dek,
  ) async {
    final encrypted = row['encrypted_data'] as String?;
    if (encrypted == null || encrypted.isEmpty || dek == null) return null;

    try {
      final json = jsonDecode(await CryptoService.decrypt(encrypted, dek)) as Map<String, dynamic>;
      json['id'] = row['id'];
      json['user_id'] = row['user_id'];
      json['date'] = row['date'];
      json['created_at'] = row['created_at'];
      return TimeLog.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  // -----------------------------------------------------------------
  // Date helpers
  // -----------------------------------------------------------------

  String _dateStr(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
