import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/time_log.dart';
import 'supabase_service.dart';

class TimeLogService {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<TimeLog>> all() async {
    final resp = await _client.from('time_logs').select().order('date', ascending: false);
    final rows = resp as List<dynamic>;
    return rows.map((r) => TimeLog.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<TimeLog?> today() async {
    final dateStr = _dateStr(DateTime.now());
    final resp = await _client.from('time_logs').select().eq('date', dateStr).limit(1);
    final rows = resp as List<dynamic>;
    return rows.isEmpty ? null : TimeLog.fromJson(rows.first as Map<String, dynamic>);
  }

  Future<TimeLog?> activeToday() async {
    final dateStr = _dateStr(DateTime.now());
    final resp = await _client.from('time_logs').select().eq('date', dateStr).limit(1);
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
    final json = log.toJson();
    json.remove('id');
    json.remove('created_at');
    // Don't send user_id — let DB default (auth.uid()) handle it.
    final row = await _client.from('time_logs').insert(json).select().single();
    return TimeLog.fromJson(row);
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    await _client.from('time_logs').update(fields).eq('id', id);
  }

  Future<int> totalOvertime() async {
    final logs = await all();
    return logs.fold<int>(0, (sum, l) => sum + l.overtimeMinutes);
  }

  String _dateStr(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
