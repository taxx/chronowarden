import 'dart:convert';

import 'api_client.dart';

/// Full portable backup & restore.
///
/// The bundle contains the encryption envelope (wrapped DEK + KDF parameters +
/// recovery hash) alongside the ciphertext rows, so a backup taken on one
/// instance can be restored on another and unlocked with the *same* encryption
/// passphrase. The API only ever handles ciphertext.
class BackupService {
  BackupService._();
  static final BackupService _instance = BackupService._();
  factory BackupService() => _instance;

  ApiClient get _api => ApiClient();

  /// Fetch the full bundle for the signed-in user.
  Future<Map<String, dynamic>> export() async {
    final resp = await _api.get('/export');
    if (resp is! Map<String, dynamic>) {
      throw Exception('Unexpected export response');
    }
    return resp;
  }

  /// Restore a bundle JSON string, replacing this account's data.
  ///
  /// Callers should follow up with [AuthService.onBackupRestored] so the user
  /// is prompted for the passphrase that matches the restored envelope.
  Future<Map<String, dynamic>> restore(String bundleJson) async {
    dynamic decoded;
    try {
      decoded = jsonDecode(bundleJson);
    } catch (_) {
      throw const FormatException('Backup is not valid JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup is not a ChronoWarden backup');
    }
    final resp = await _api.post('/import', decoded);
    return resp is Map<String, dynamic> ? resp : <String, dynamic>{};
  }
}
