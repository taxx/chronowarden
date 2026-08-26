import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/time_log.dart';
import 'auth_service.dart';
import 'crypto_service.dart';
import 'supabase_service.dart';

/// Data service for time logs with envelope encryption.
///
/// All data is encrypted with the user's DEK before storage and decrypted
/// after retrieval. Only `date` and `user_id` remain plaintext for
/// server-side filtering.
class TimeLogService {
  SupabaseClient get _client => SupabaseService.instance.client;

  String? get _userId {
    final session = _client.auth.currentSession;
    return session?.user.id;
  }

  SecretKey? get _dek => AuthService().dek;

  // -----------------------------------------------------------------
  // Query methods
  // -----------------------------------------------------------------

  Future<List<TimeLog>> all() async {
    final userId = _userId;
    final dek = _dek;
    if (userId == null || dek == null) return [];

    final resp = await _client
        .from('time_logs')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);
    final rows = resp as List<dynamic>;
    final results = <TimeLog>[];
    for (final r in rows) {
      final map = r as Map<String, dynamic>;
      final encrypted = map['encrypted_data'] as String?;
      if (encrypted == null || encrypted.isEmpty) continue;
      final timeLog = await _decryptTimeLog(map, dek);
      if (timeLog != null) results.add(timeLog);
    }
    return results;
  }

  Future<TimeLog?> today() async {
    final userId = _userId;
    final dek = _dek;
    if (userId == null || dek == null) return null;

    final dateStr = _dateStr(DateTime.now());
    final resp = await _client
        .from('time_logs')
        .select()
        .eq('date', dateStr)
        .eq('user_id', userId)
        .limit(1);
    final rows = resp as List<dynamic>;
    for (final r in rows) {
      final map = r as Map<String, dynamic>;
      final encrypted = map['encrypted_data'] as String?;
      if (encrypted == null || encrypted.isEmpty) continue;
      return await _decryptTimeLog(map, dek);
    }
    return null;
  }

  Future<TimeLog?> activeToday() async {
    final userId = _userId;
    final dek = _dek;
    if (userId == null || dek == null) return null;

    final dateStr = _dateStr(DateTime.now());
    final resp = await _client
        .from('time_logs')
        .select()
        .eq('date', dateStr)
        .eq('user_id', userId)
        .limit(1);
    final rows = resp as List<dynamic>;
    for (final r in rows) {
      final map = r as Map<String, dynamic>;
      if (map['end_time'] == null) {
        final encrypted = map['encrypted_data'] as String?;
        if (encrypted == null || encrypted.isEmpty) continue;
        return await _decryptTimeLog(map, dek);
      }
    }
    return null;
  }

  // -----------------------------------------------------------------
  // Mutation methods
  // -----------------------------------------------------------------

  Future<TimeLog> insert(TimeLog log) async {
    final userId = _userId;
    final dek = _dek;
    if (userId == null) throw Exception('Not authenticated');
    if (dek == null) throw Exception('Encryption key not loaded');

    final json = log.toJson();
    json.remove('id');
    json.remove('created_at');
    json.remove('encrypted_data');
    json['user_id'] = userId;

    // Encrypt the full model JSON
    final plaintext = jsonEncode(json);
    final ciphertext = await CryptoService.encrypt(plaintext, dek);

    // Store: encrypted_data + plaintext date/user_id for filtering
    final row = await _client.from('time_logs').insert({
      'user_id': userId,
      'date': log.date,
      'encrypted_data': ciphertext,
    }).select().single();

    final decrypted = await _decryptTimeLog(Map<String, dynamic>.from(row), dek);
    return decrypted ??
        TimeLog.fromJson({'date': log.date, 'start_time': log.startTime, 'expected_minutes': log.expectedMinutes, 'overtime_minutes': log.overtimeMinutes});
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    final userId = _userId;
    final dek = _dek;
    if (userId == null || dek == null) return;

    // Encrypt any changed fields
    fields.remove('user_id');
    fields.remove('id');
    fields.remove('date');
    fields.remove('encrypted_data');

    if (fields.isNotEmpty) {
      final plaintext = jsonEncode(fields);
      final ciphertext = await CryptoService.encrypt(plaintext, dek);
      await _client.from('time_logs').update({
        'encrypted_data': ciphertext,
      }).eq('id', id).eq('user_id', userId);
    }
  }

  Future<void> delete(String id) async {
    final userId = _userId ?? '';
    await _client.from('time_logs').delete().eq('id', id).eq('user_id', userId);
  }

  // -----------------------------------------------------------------
  // Aggregation
  // -----------------------------------------------------------------

  Future<int> totalOvertime() async {
    final logs = await all();
    return logs.fold<int>(0, (sum, l) => sum + l.overtimeMinutes);
  }

  // -----------------------------------------------------------------
  // Encryption helpers
  // -----------------------------------------------------------------

  /// Decrypt an encrypted time_log row into a [TimeLog] model.
  Future<TimeLog?> _decryptTimeLog(
    Map<String, dynamic> row,
    SecretKey dek,
  ) async {
    final encrypted = row['encrypted_data'] as String?;
    if (encrypted == null || encrypted.isEmpty) return null;

    try {
      final plaintext = await CryptoService.decrypt(encrypted, dek);
      final json = jsonDecode(plaintext) as Map<String, dynamic>;

      // Merge with plaintext envelope fields
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
