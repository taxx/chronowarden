import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/time_log.dart';
import 'supabase_service.dart';

class TimeLogService {
  SupabaseClient get _client => SupabaseService.instance.client;

  String? get _userId {
    final session = _client.auth.currentSession;
    return session?.user.id;
  }

  Future<List<TimeLog>> all() async {
    final userId = _userId;
    if (userId == null) return [];
    final resp = await _client
        .from('time_logs')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);
    final rows = resp as List<dynamic>;
    return rows.map((r) => TimeLog.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<TimeLog?> today() async {
    final userId = _userId;
    if (userId == null) return null;
    final dateStr = _dateStr(DateTime.now());
    final resp = await _client
        .from('time_logs')
        .select()
        .eq('date', dateStr)
        .eq('user_id', userId)
        .limit(1);
    final rows = resp as List<dynamic>;
    return rows.isEmpty ? null : TimeLog.fromJson(rows.first as Map<String, dynamic>);
  }

  Future<TimeLog?> activeToday() async {
    final userId = _userId;
    if (userId == null) return null;
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
        return TimeLog.fromJson(map);
      }
    }
    return null;
  }

  Future<TimeLog> insert(TimeLog log) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');
    final json = log.toJson();
    json.remove('id');
    json.remove('created_at');
    json['user_id'] = userId;
    final row = await _client.from('time_logs').insert(json).select().single();
    return TimeLog.fromJson(row);
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    final userId = _userId ?? '';
    fields.remove('user_id');
    fields.remove('id');
    await _client.from('time_logs').update(fields).eq('id', id).eq('user_id', userId);
  }

  Future<void> delete(String id) async {
    final userId = _userId ?? '';
    await _client.from('time_logs').delete().eq('id', id).eq('user_id', userId);
  }

  Future<int> totalOvertime() async {
    final logs = await all();
    return logs.fold<int>(0, (sum, l) => sum + l.overtimeMinutes);
  }

  String _dateStr(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
