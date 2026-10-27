import 'dart:convert';

import '../models/time_log.dart';
import '../models/travel_preset.dart';
import 'auth_service.dart';
import 'crypto_service.dart';
import 'supabase_service.dart';

/// Handles the one-time migration from plaintext data to encrypted envelopes.
///
/// Detected by [AuthService.needsMigration] — when a user has no encrypted_dek
/// in user_settings, they must go through migration before using the app.
class MigrationService {
  final _client = SupabaseService.instance.client;

  String? get _userId {
    final session = _client.auth.currentSession;
    return session?.user.id;
  }

  /// Run the full migration: create envelope + encrypt all existing data.
  ///
  /// Returns the recovery mnemonic phrase that should be shown to the user once.
  Future<String> migrate(String passphrase) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final totalSteps = await _countTotalSteps(userId);
    var completed = 0;

    // --- Phase 1: Create encryption envelope ---

    final salt = CryptoService.generateSalt();
    final masterKey = await CryptoService.deriveMasterKey(passphrase, salt);
    final dek = await CryptoService.generateDek();
    final wrappedB64 = await CryptoService.wrapDekBase64(dek, masterKey);
    final recoveryPhrase = await CryptoService.dekToMnemonic(dek);
    final recoveryHash = CryptoService.hashRecoveryPhrase(recoveryPhrase);

    await _client.from('user_settings').upsert({
      'user_id': userId,
      'encrypted_dek': wrappedB64,
      'kek_salt': base64.encode(salt),
      'kek_iterations': CryptoService.kekIterations,
      'recovery_hash': recoveryHash,
    }, onConflict: 'user_id');

    completed++;
    _notifyProgress(completed, totalSteps);

    // --- Phase 2: Encrypt all time_logs ---

    final timeLogs = await _fetchAllTimeLogs(userId);
    for (final log in timeLogs) {
      final json = log.toJson();
      json.remove('encrypted_data');
      json.remove('id');
      json.remove('user_id');
      json.remove('created_at');
      final plaintext = jsonEncode(json);
      final ciphertext = await CryptoService.encrypt(plaintext, dek);
      await _client.from('time_logs').update({
        'encrypted_data': ciphertext,
      }).eq('id', log.id!).eq('user_id', userId);
      completed++;
      _notifyProgress(completed, totalSteps);
    }

    // --- Phase 3: Encrypt all travel_presets ---

    final presets = await _fetchAllPresets(userId);
    for (final preset in presets) {
      final json = preset.toJson();
      json.remove('encrypted_data');
      json.remove('id');
      json.remove('user_id');
      json.remove('created_at');
      final plaintext = jsonEncode(json);
      final ciphertext = await CryptoService.encrypt(plaintext, dek);
      await _client.from('travel_presets').update({
        'encrypted_data': ciphertext,
      }).eq('id', preset.id!).eq('user_id', userId);
      completed++;
      _notifyProgress(completed, totalSteps);
    }

    // --- Phase 4: Store DEK in AuthService ---

    await AuthService().setDekAfterMigration(dek);

    // Return the recovery phrase — show it to the user exactly once
    return recoveryPhrase;
  }

  /// Check if the current user needs migration.
  Future<bool> needsMigration() async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      final resp = await _client
          .from('user_settings')
          .select('encrypted_dek')
          .eq('user_id', userId)
          .limit(1);
      final rows = resp as List<dynamic>;
      if (rows.isEmpty) return true;
      final dek = (rows.first as Map<String, dynamic>)['encrypted_dek'] as String?;
      return dek == null || dek.isEmpty;
    } catch (_) {
      return true;
    }
  }

  // -----------------------------------------------------------------
  // Progress tracking
  // -----------------------------------------------------------------

  /// Callback for UI progress updates. Set via [onProgress].
  void Function(double progress)? _progressCallback;

  void _notifyProgress(int completed, int total) {
    _progressCallback?.call(completed / total);
  }

  /// Set a progress callback (called by the UI during migration).
  void setProgressCallback(void Function(double p)? callback) {
    _progressCallback = callback;
  }

  // -----------------------------------------------------------------
  // Data fetching helpers
  // -----------------------------------------------------------------

  Future<int> _countTotalSteps(String userId) async {
    var count = 1; // envelope creation
    count += await _countRows('time_logs', userId);
    count += await _countRows('travel_presets', userId);
    return count;
  }

  Future<int> _countRows(String table, String userId) async {
    try {
      final resp = await _client
          .from(table)
          .select('id')
          .eq('user_id', userId);
      return (resp as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<TimeLog>> _fetchAllTimeLogs(String userId) async {
    try {
      final resp = await _client
          .from('time_logs')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      final rows = resp as List<dynamic>;
      return rows
          .map((r) => TimeLog.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<TravelPreset>> _fetchAllPresets(String userId) async {
    try {
      final resp = await _client
          .from('travel_presets')
          .select()
          .eq('user_id', userId)
          .order('name');
      final rows = resp as List<dynamic>;
      return rows
          .map((r) => TravelPreset.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
