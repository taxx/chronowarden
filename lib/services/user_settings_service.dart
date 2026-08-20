import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Reads and writes per-user settings from the [user_settings] table.
/// Each user has exactly one row (unique constraint on user_id).
class UserSettingsService {
  SupabaseClient get _client => SupabaseService.instance.client;

  String? get _userId {
    final session = _client.auth.currentSession;
    return session?.user.id;
  }

  Future<int> getDefaultFlexMinutes() async {
    final userId = _userId;
    if (userId == null) return 0;
    final resp = await _client
        .from('user_settings')
        .select('default_flex_minutes')
        .eq('user_id', userId)
        .limit(1);
    final rows = resp as List<dynamic>;
    if (rows.isEmpty) return 0;
    return (rows.first as Map<String, dynamic>)['default_flex_minutes'] as int;
  }

  Future<void> setDefaultFlexMinutes(int minutes) async {
    final userId = _userId;
    if (userId == null) return;
    // Upsert: insert if not exists, update if exists
    await _client.from('user_settings').upsert({
      'user_id': userId,
      'default_flex_minutes': minutes,
    }, onConflict: 'user_id');
  }
}
