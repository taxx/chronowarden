import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/work_period_setting.dart';
import 'supabase_service.dart';

class WorkPeriodService {
  SupabaseClient get _client => SupabaseService.instance.client;

  String? get _userId {
    final session = _client.auth.currentSession;
    return session?.user.id;
  }

  Future<List<WorkPeriodSetting>> all() async {
    final userId = _userId;
    if (userId == null) return [];
    final resp = await _client
        .from('work_period_settings')
        .select()
        .eq('user_id', userId)
        .order('start_date');
    final rows = resp as List<dynamic>;
    return rows.map((r) => WorkPeriodSetting.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<WorkPeriodSetting?> activeOn(DateTime date) async {
    final periods = await all();
    for (final p in periods) {
      if (p.isActiveOn(date)) return p;
    }
    return null;
  }

  Future<WorkPeriodSetting> insert(WorkPeriodSetting period) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');
    final json = period.toJson();
    json.remove('id');
    json.remove('created_at');
    json['user_id'] = userId;
    final row = await _client.from('work_period_settings').insert(json).select().single();
    return WorkPeriodSetting.fromJson(row);
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    final userId = _userId ?? '';
    fields.remove('id');
    fields.remove('user_id');
    fields.remove('created_at');
    await _client.from('work_period_settings').update(fields).eq('id', id).eq('user_id', userId);
  }

  Future<void> delete(String id) async {
    final userId = _userId ?? '';
    await _client.from('work_period_settings').delete().eq('id', id).eq('user_id', userId);
  }
}
