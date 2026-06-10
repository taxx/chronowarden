import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/travel_preset.dart';
import 'supabase_service.dart';

class TravelPresetService {
  SupabaseClient get _client => SupabaseService.instance.client;

  String? get _userId {
    final session = _client.auth.currentSession;
    return session?.user.id;
  }

  Future<List<TravelPreset>> all() async {
    final userId = _userId;
    if (userId == null) return [];
    final resp = await _client
        .from('travel_presets')
        .select()
        .eq('user_id', userId)
        .order('name');
    final rows = resp as List<dynamic>;
    return rows.map((r) => TravelPreset.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<TravelPreset> insert(TravelPreset preset) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');
    final json = preset.toJson();
    json.remove('id');
    json.remove('created_at');
    json['user_id'] = userId;
    final row = await _client.from('travel_presets').insert(json).select().single();
    return TravelPreset.fromJson(row);
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    final userId = _userId ?? '';
    fields.remove('id');
    fields.remove('user_id');
    fields.remove('created_at');
    await _client.from('travel_presets').update(fields).eq('id', id).eq('user_id', userId);
  }

  Future<void> delete(String id) async {
    final userId = _userId ?? '';
    await _client.from('travel_presets').delete().eq('id', id).eq('user_id', userId);
  }
}
