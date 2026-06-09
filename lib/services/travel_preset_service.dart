import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/travel_preset.dart';
import 'supabase_service.dart';

class TravelPresetService {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<TravelPreset>> all() async {
    final resp = await _client.from('travel_presets').select().order('name');
    final rows = resp as List<dynamic>;
    return rows.map((r) => TravelPreset.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<TravelPreset> insert(TravelPreset preset) async {
    final json = preset.toJson();
    json.remove('id');
    json.remove('user_id');
    json.remove('created_at');
    final row = await _client.from('travel_presets').insert(json).select().single();
    return TravelPreset.fromJson(row);
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    // Strip DB-managed columns — only keep editable fields.
    fields.remove('id');
    fields.remove('user_id');
    fields.remove('created_at');
    await _client.from('travel_presets').update(fields).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('travel_presets').delete().eq('id', id);
  }
}
