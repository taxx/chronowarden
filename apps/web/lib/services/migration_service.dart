import 'dart:convert';

import '../models/time_log.dart';
import '../models/travel_preset.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'crypto_service.dart';

/// Handles the one-time migration from plaintext data to encrypted envelopes.
///
/// Detected by [AuthService.needsMigration] — when a user has no encrypted_dek
/// in their settings, they must go through migration before using the app.
///
/// (Legacy path: the plaintext columns no longer exist on the server, so for
/// current installations this is effectively retired.)
class MigrationService {
  ApiClient get _api => ApiClient();

  String? get _userId => AuthService().profile?.id;

  /// Run the full migration: create envelope + encrypt all existing data.
  Future<String> migrate(String passphrase) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final totalSteps = await _countTotalSteps();
    var completed = 0;

    // --- Phase 1: Create encryption envelope ---
    final salt = CryptoService.generateSalt();
    final masterKey = await CryptoService.deriveMasterKey(passphrase, salt);
    final dek = await CryptoService.generateDek();
    final wrappedB64 = await CryptoService.wrapDekBase64(dek, masterKey);
    final recoveryPhrase = await CryptoService.dekToMnemonic(dek);
    final recoveryHash = CryptoService.hashRecoveryPhrase(recoveryPhrase);

    await _api.patch('/settings', {
      'encrypted_dek': wrappedB64,
      'kek_salt': base64.encode(salt),
      'kek_iterations': CryptoService.kekIterations,
      'recovery_hash': recoveryHash,
    });
    completed++;
    _notifyProgress(completed, totalSteps);

    // --- Phase 2: Encrypt all time_logs ---
    for (final log in await _fetchAllTimeLogs()) {
      if (log.id == null) continue;
      final json = log.toJson();
      json.remove('encrypted_data');
      json.remove('id');
      json.remove('user_id');
      json.remove('created_at');
      final ciphertext = await CryptoService.encrypt(jsonEncode(json), dek);
      await _api.patch('/time-logs/${log.id}', {'encrypted_data': ciphertext});
      completed++;
      _notifyProgress(completed, totalSteps);
    }

    // --- Phase 3: Encrypt all travel_presets ---
    for (final preset in await _fetchAllPresets()) {
      if (preset.id == null) continue;
      final json = preset.toJson();
      json.remove('encrypted_data');
      json.remove('id');
      json.remove('user_id');
      json.remove('created_at');
      final ciphertext = await CryptoService.encrypt(jsonEncode(json), dek);
      await _api.patch('/travel-presets/${preset.id}', {'encrypted_data': ciphertext});
      completed++;
      _notifyProgress(completed, totalSteps);
    }

    await AuthService().setDekAfterMigration(dek);
    return recoveryPhrase;
  }

  /// Check if the current user needs migration.
  Future<bool> needsMigration() async {
    if (_userId == null) return false;
    try {
      final resp = await _api.get('/settings');
      if (resp is! Map<String, dynamic>) return true;
      final dek = resp['encrypted_dek'] as String?;
      return dek == null || dek.isEmpty;
    } catch (_) {
      return true;
    }
  }

  // -----------------------------------------------------------------
  // Progress tracking
  // -----------------------------------------------------------------

  void Function(double progress)? _progressCallback;

  void _notifyProgress(int completed, int total) {
    _progressCallback?.call(completed / total);
  }

  void setProgressCallback(void Function(double p)? callback) {
    _progressCallback = callback;
  }

  // -----------------------------------------------------------------
  // Data fetching helpers
  // -----------------------------------------------------------------

  Future<int> _countTotalSteps() async {
    var count = 1; // envelope creation
    count += (await _fetchAllTimeLogs()).length;
    count += (await _fetchAllPresets()).length;
    return count;
  }

  Future<List<TimeLog>> _fetchAllTimeLogs() async {
    try {
      final resp = await _api.get('/time-logs') as List<dynamic>;
      return resp
          .map((r) => TimeLog.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<TravelPreset>> _fetchAllPresets() async {
    try {
      final resp = await _api.get('/travel-presets') as List<dynamic>;
      return resp
          .map((r) => TravelPreset.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
