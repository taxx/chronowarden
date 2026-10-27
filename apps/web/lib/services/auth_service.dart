import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import 'api_client.dart';
import 'crypto_service.dart';

/// Handles sign-in, sign-up, sign-out, and session state.
///
/// Backed by the self-hosted API (see [ApiClient]); the public surface is
/// unchanged so screens don't care which backend is behind it.
///
/// Also manages the envelope encryption lifecycle:
///   - Holds the unwrapped DEK in memory during the session
///   - Caches the DEK in localStorage for page-refresh survival
///   - Detects when a user needs to migrate (no encrypted_dek)
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  ApiClient get _api => ApiClient();

  UserProfile? _profile;
  SecretKey? _dek; // unwrapped DEK, held in memory for the session
  bool _isAuthenticated = false;
  bool _isInitializing = true;
  bool _needsMigration = false;
  bool _needsPassphrase = false;
  bool _hasEnvelope = false;
  String? _pendingRecoveryPhrase; // shown once after signup, then cleared
  String? _error;

  UserProfile? get profile => _profile;
  SecretKey? get dek => _dek;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitializing => _isInitializing;
  bool get needsMigration => _needsMigration;
  bool get needsPassphrase => _needsPassphrase;
  bool get hasEnvelope => _hasEnvelope;
  String? get pendingRecoveryPhrase => _pendingRecoveryPhrase;
  String? get error => _error;

  // -----------------------------------------------------------------
  // Init — tries the cached token first
  // -----------------------------------------------------------------

  /// Restores a cached session, loads the profile, and detects whether the
  /// encryption envelope still needs a passphrase (or a migration).
  Future<void> init() async {
    try {
      await _api.init();
      final cachedDek = await CryptoService.loadDekFromLocal();
      if (cachedDek != null) {
        _dek = cachedDek;
      }

      if (_api.isAuthenticated) {
        try {
          final resp = await _api.get('/me') as Map<String, dynamic>;
          _profile = UserProfile.fromJson(resp);
          _isAuthenticated = true;

          if (_dek == null && _profile != null) {
            final envelope = await _fetchSettings();
            final wrapped = envelope?['encrypted_dek'] as String?;
            if (wrapped != null && wrapped.isNotEmpty) {
              _hasEnvelope = true;
              _needsPassphrase = true;
            } else {
              _needsMigration = true;
            }
          }
        } on ApiException catch (e) {
          // Stale/invalid token — drop it.
          if (e.status == 401) {
            _api.setToken(null);
            _isAuthenticated = false;
          } else {
            _error = e.message;
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // -----------------------------------------------------------------
  // Sign in
  // -----------------------------------------------------------------

  /// Sign in with email/password + encryption passphrase.
  ///
  /// The [encryptionPassphrase] derives the Master Key (KEK), which unwraps
  /// the DEK from user settings. The DEK is then held in memory and cached.
  Future<void> signIn({
    required String email,
    required String password,
    required String encryptionPassphrase,
  }) async {
    _error = null;
    _needsMigration = false;
    notifyListeners();
    try {
      await _login(email, password);
      await _loadOrDetectEnvelope(encryptionPassphrase);
    } catch (e) {
      _error = _messageOf(e);
    }
    notifyListeners();
  }

  /// Sign in WITHOUT the encryption passphrase — for users who haven't set up
  /// encryption yet. Detects whether migration or unlock is required.
  Future<void> signInWithoutEncryption({
    required String email,
    required String password,
  }) async {
    _error = null;
    _needsMigration = false;
    _needsPassphrase = false;
    _hasEnvelope = false;
    notifyListeners();
    try {
      await _login(email, password);

      final envelope = await _fetchSettings();
      final wrapped = envelope?['encrypted_dek'] as String?;
      if (wrapped == null || wrapped.isEmpty) {
        _needsMigration = true;
      } else {
        _hasEnvelope = true;
        _needsPassphrase = true;
      }
    } catch (e) {
      _error = _messageOf(e);
    }
    notifyListeners();
  }

  Future<void> _login(String email, String password) async {
    final resp = await _api.post('/auth/login', {
      'email': email.trim().toLowerCase(),
      'password': password,
    }) as Map<String, dynamic>;

    _api.setToken(resp['token'] as String?);
    _profile = UserProfile.fromJson(resp['user'] as Map<String, dynamic>);
    _isAuthenticated = true;
  }

  // -----------------------------------------------------------------
  // Sign up
  // -----------------------------------------------------------------

  /// Sign up with encryption setup.
  ///
  /// [isFirstAdmin] creates the initial administrator (only while the database
  /// is empty). Otherwise an [inviteToken] is required — invites are bound to
  /// the email address and grant access immediately.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String encryptionPassphrase,
    String? inviteToken,
    bool isFirstAdmin = false,
  }) async {
    _error = null;
    notifyListeners();
    try {
      if (!isFirstAdmin && (inviteToken == null || inviteToken.isEmpty)) {
        throw const ApiException(400, 'INVITE_REQUIRED', 'An invitation is required to register');
      }

      final resp = isFirstAdmin
          ? await _api.post('/auth/setup', {
              'email': email.trim().toLowerCase(),
              'password': password,
              'fullName': fullName,
            })
          : await _api.post('/auth/register', {
              'email': email.trim().toLowerCase(),
              'password': password,
              'fullName': fullName,
              'inviteToken': inviteToken!.trim(),
            }) as Map<String, dynamic>;

      final map = resp as Map<String, dynamic>;
      _api.setToken(map['token'] as String?);
      _profile = UserProfile.fromJson(map['user'] as Map<String, dynamic>);
      _isAuthenticated = true;

      // Create the encryption envelope for the new user.
      _pendingRecoveryPhrase = await _createEnvelope(encryptionPassphrase);
    } catch (e) {
      _error = _messageOf(e);
    }
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // Sign out
  // -----------------------------------------------------------------

  /// Clear the pending recovery phrase after it's been shown to the user.
  void clearPendingRecoveryPhrase() {
    _pendingRecoveryPhrase = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // Best effort — the local session is cleared regardless.
    }
    CryptoService.clearLocalCache();
    _api.setToken(null);
    _dek = null;
    _needsMigration = false;
    _pendingRecoveryPhrase = null;
    _isAuthenticated = false;
    _profile = null;
    _error = null;
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // Migration support
  // -----------------------------------------------------------------

  /// Set the DEK after a successful migration (called by MigrationService).
  Future<void> setDekAfterMigration(SecretKey dek) async {
    _dek = dek;
    _needsMigration = false;
    CryptoService.cacheDekLocally(dek);
    notifyListeners();
  }

  /// Recover from a mnemonic phrase (forgot passphrase).
  Future<void> recoverWithMnemonic(String phrase) async {
    _dek = await CryptoService.mnemonicToDek(phrase);
    final envelope = await _fetchSettings();
    final expectedHash = envelope?['recovery_hash'] as String?;
    if (expectedHash != null) {
      final actualHash = CryptoService.hashRecoveryPhrase(phrase);
      if (actualHash != expectedHash) {
        _dek = null;
        throw Exception('Recovery phrase is incorrect');
      }
    }
    CryptoService.cacheDekLocally(_dek!);
    _needsMigration = false;
    _needsPassphrase = false;
    notifyListeners();
  }

  /// Unlock encryption with a passphrase (user already logged in, has an
  /// envelope, but hasn't entered their passphrase yet).
  Future<void> unlockEncryption(String encryptionPassphrase) async {
    final envelope = await _fetchSettings();
    final salt = envelope?['kek_salt'] as String?;
    final wrappedB64 = envelope?['encrypted_dek'] as String?;
    if (salt == null || wrappedB64 == null || wrappedB64.isEmpty) {
      throw Exception('No encryption envelope found');
    }

    final saltBytes = _saltFromBase64(salt);
    final masterKey = await CryptoService.deriveMasterKey(encryptionPassphrase, saltBytes);
    _dek = await CryptoService.unwrapDekBase64(wrappedB64, masterKey);
    _needsPassphrase = false;
    CryptoService.cacheDekLocally(_dek!);
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // Recovery phrase → new encryption passphrase
  // -----------------------------------------------------------------

  /// Recover the DEK from a mnemonic phrase and set a new encryption passphrase.
  Future<void> recoverAndSetNewPassphrase(
    String recoveryPhrase,
    String newPassphrase,
  ) async {
    final envelope = await _fetchSettings();
    final expectedHash = envelope?['recovery_hash'] as String?;
    if (expectedHash != null) {
      final actualHash = CryptoService.hashRecoveryPhrase(recoveryPhrase);
      if (actualHash != expectedHash) {
        throw Exception('Recovery phrase is incorrect');
      }
    }

    _dek = await CryptoService.mnemonicToDek(recoveryPhrase);
    final wrapResult = await CryptoService.wrapDekWithPassphrase(_dek!, newPassphrase);

    await _api.patch('/settings', {
      'encrypted_dek': wrapResult['wrapped_b64'],
      'kek_salt': wrapResult['salt_b64'],
      'kek_iterations': wrapResult['iterations'],
    });

    CryptoService.cacheDekLocally(_dek!);
    _needsPassphrase = false;
    _needsMigration = false;
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // Database state checks
  // -----------------------------------------------------------------

  /// Returns `true` when the database has no users yet (first-admin setup).
  /// Returns `null` when the backend cannot be reached.
  Future<bool?> checkDatabaseState() async {
    try {
      final resp = await _api.get('/state') as Map<String, dynamic>;
      return (resp['has_users'] as bool? ?? true) ? false : true;
    } catch (_) {
      return null;
    }
  }

  /// Validates an invite token. Returns the invited email when valid.
  Future<String?> validateInvite(String token) async {
    try {
      final resp = await _api.post('/invites/validate', {
        'token': token.trim(),
      }) as Map<String, dynamic>;
      if (resp['valid'] == true) return resp['email'] as String?;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Backwards-compatible boolean form used by the signup screen.
  Future<bool> validateInviteToken(String token) async =>
      (await validateInvite(token)) != null;

  Future<void> refreshProfile() async {
    try {
      final resp = await _api.get('/me') as Map<String, dynamic>;
      _profile = UserProfile.fromJson(resp);
      notifyListeners();
    } catch (_) {}
  }

  /// Change the account password (requires the current one).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.patch('/me/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // -----------------------------------------------------------------
  // Encryption envelope helpers
  // -----------------------------------------------------------------

  /// Read the user's settings row (envelope + encrypted payload), or null.
  Future<Map<String, dynamic>?> _fetchSettings() async {
    try {
      final resp = await _api.get('/settings');
      if (resp is Map<String, dynamic>) return resp;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Unwrap the cached DEK from the stored envelope, or flag a migration.
  Future<void> _loadOrDetectEnvelope(String passphrase) async {
    final envelope = await _fetchSettings();
    final salt = envelope?['kek_salt'] as String?;
    final wrappedB64 = envelope?['encrypted_dek'] as String?;

    if (salt == null || wrappedB64 == null || wrappedB64.isEmpty) {
      _needsMigration = true;
      _hasEnvelope = false;
      return;
    }

    _hasEnvelope = true;
    final saltBytes = _saltFromBase64(salt);
    final masterKey = await CryptoService.deriveMasterKey(passphrase, saltBytes);
    _dek = await CryptoService.unwrapDekBase64(wrappedB64, masterKey);
    CryptoService.cacheDekLocally(_dek!);
  }

  /// Create a fresh encryption envelope for a new user.
  /// Returns the recovery phrase that should be shown to the user once.
  Future<String> _createEnvelope(String passphrase) async {
    final salt = CryptoService.generateSalt();
    final masterKey = await CryptoService.deriveMasterKey(passphrase, salt);
    final dek = await CryptoService.generateDek();
    final wrappedB64 = await CryptoService.wrapDekBase64(dek, masterKey);
    final recoveryPhrase = await CryptoService.dekToMnemonic(dek);
    final recoveryHash = CryptoService.hashRecoveryPhrase(recoveryPhrase);

    await _api.patch('/settings', {
      'encrypted_dek': wrappedB64,
      'kek_salt': _saltToBase64(salt),
      'kek_iterations': CryptoService.kekIterations,
      'recovery_hash': recoveryHash,
    });

    _dek = dek;
    CryptoService.cacheDekLocally(dek);
    return recoveryPhrase;
  }

  String _messageOf(Object e) => e is ApiException ? e.message : e.toString();

  // -----------------------------------------------------------------
  // Encoding helpers
  // -----------------------------------------------------------------

  static String _saltToBase64(Uint8List salt) => base64.encode(salt);

  static Uint8List _saltFromBase64(String b64) => Uint8List.fromList(base64.decode(b64));
}
