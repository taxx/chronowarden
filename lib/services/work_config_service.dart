import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/work_config.dart';
import 'supabase_service.dart';

/// Reads and writes the per-user work-time configuration.
///
/// Data lives in columns of the [user_settings] table (one row per user).
class WorkConfigService {
  SupabaseClient get _client => SupabaseService.instance.client;

  String? get _userId {
    final session = _client.auth.currentSession;
    return session?.user.id;
  }

  /// Fetch the current work config, or `null` if no row exists yet.
  Future<WorkConfig?> get() async {
    final userId = _userId;
    if (userId == null) return null;
    final resp = await _client
        .from('user_settings')
        .select(
          'default_expected_minutes, reduced_expected_minutes, '
          'reduced_start_week, reduced_end_week',
        )
        .eq('user_id', userId)
        .limit(1);
    final rows = resp as List<dynamic>;
    if (rows.isEmpty) return null;
    final row = rows.first as Map<String, dynamic>;
    return WorkConfig(
      userId: userId,
      defaultExpectedMinutes:
          (row['default_expected_minutes'] as int?) ?? 480,
      reducedExpectedMinutes: row['reduced_expected_minutes'] as int?,
      reducedStartWeek: row['reduced_start_week'] as int?,
      reducedEndWeek: row['reduced_end_week'] as int?,
    );
  }

  /// Save (upsert) a work config for the current user.
  Future<void> save(WorkConfig config) async {
    final userId = _userId;
    if (userId == null) return;
    await _client.from('user_settings').upsert({
      'user_id': userId,
      'default_expected_minutes': config.defaultExpectedMinutes,
      'reduced_expected_minutes': config.reducedExpectedMinutes,
      'reduced_start_week': config.reducedStartWeek,
      'reduced_end_week': config.reducedEndWeek,
    }, onConflict: 'user_id');
  }
}
