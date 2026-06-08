import '../models/work_period_setting.dart';
import 'supabase_service.dart';

class WorkPeriodService {
  final _client = SupabaseService().client;

  Future<List<WorkPeriodSetting>> all() async {
    final resp = await _client.from('work_period_settings').select().order('start_date');
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
    final json = period.toJson();
    json.remove('id');
    json.remove('user_id');
    json.remove('created_at');
    final row = await _client.from('work_period_settings').insert(json).select().single();
    return WorkPeriodSetting.fromJson(row);
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    await _client.from('work_period_settings').update(fields).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('work_period_settings').delete().eq('id', id);
  }
}
