import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'supabase_service.dart';

/// Produces a full, portable backup of the signed-in user's data.
///
/// The bundle includes the encryption envelope (wrapped DEK + KDF parameters +
/// recovery hash) alongside the ciphertext rows, so it can be restored on a
/// self-hosted ChronoWarden instance and unlocked with the *same* encryption
/// passphrase. This instance only handles ciphertext.
class BackupService {
  BackupService._();
  static final BackupService _instance = BackupService._();
  factory BackupService() => _instance;

  SupabaseClient get _client => SupabaseService.instance.client;

  static const String format = 'chronowarden-backup';
  static const int version = 1;

  Future<Map<String, dynamic>> exportBundle() async {
    final userId = _client.auth.currentSession?.user.id;
    if (userId == null) throw Exception('Not authenticated');

    final settingsRows = await _client
        .from('user_settings')
        .select()
        .eq('user_id', userId)
        .limit(1);
    final settings =
        settingsRows.isEmpty ? null : settingsRows.first;

    final logs = await _client
        .from('time_logs')
        .select('date, encrypted_data')
        .eq('user_id', userId)
        .order('date');

    final presets = await _client
        .from('travel_presets')
        .select('name, encrypted_data')
        .eq('user_id', userId)
        .order('name');

    final profile = AuthService().profile;

    return {
      'format': format,
      'version': version,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'user': {
        'email': profile?.email,
        'full_name': profile?.fullName,
      },
      'envelope': settings == null
          ? null
          : {
              'encrypted_dek': settings['encrypted_dek'] ?? '',
              'kek_salt': settings['kek_salt'] ?? '',
              'kek_iterations': settings['kek_iterations'] ?? 310000,
              'recovery_hash': settings['recovery_hash'],
            },
      'settings': {
        'encrypted_data': settings?['encrypted_data'] ?? '',
      },
      'time_logs': (logs as List)
          .map((r) => {
                'date': (r as Map<String, dynamic>)['date'],
                'encrypted_data': r['encrypted_data'],
              })
          .toList(),
      'travel_presets': (presets as List)
          .map((r) => {
                'name': (r as Map<String, dynamic>)['name'],
                'encrypted_data': r['encrypted_data'],
              })
          .toList(),
    };
  }
}
