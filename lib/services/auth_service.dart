import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/invite.dart';
import '../models/user_profile.dart';
import 'crypto_service.dart';
import 'supabase_service.dart';

/// Handles sign-in, sign-up, sign-out, and session state.
///
/// Also manages the envelope encryption lifecycle:
///   - Holds the unwrapped DEK in memory during the session
///   - Caches DEK in sessionStorage for page-refresh survival
///   - Detects when a user needs to migrate (no encrypted_dek)
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  SupabaseClient get _client => SupabaseService.instance.client;

  UserProfile? _profile;
  SecretKey? _dek;          // unwrapped DEK, held in memory for the session
  bool _isAuthenticated = false;
  bool _isInitializing = true;
  bool _needsMigration = false;
  String? _error;

  UserProfile? get profile => _profile;
  SecretKey? get dek => _dek;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitializing => _isInitializing;
  bool get needsMigration => _needsMigration;
  String? get error => _error;

  // -----------------------------------------------------------------
  // Init — tries sessionStorage cache first
  // -----------------------------------------------------------------

  /// Check for an existing session and load (or create) the profile.
  ///
  /// On page refresh, tries the sessionStorage cache first so the user
  /// doesn't need to re-enter their encryption passphrase.
  Future<void> init() async {
    try {
      // Try sessionStorage cache first
      final cachedDek = await CryptoService.loadDekFromSession();
      if (cachedDek != null) {
        _dek = cachedDek;
      }

      final session = _client.auth.currentSession;
      if (session != null) {
        _isAuthenticated = true;
        _profile = await _fetchProfile(session.user.id);
        if (_profile == null) {
          await _ensureProfile(session.user);
          _profile = await _fetchProfile(session.user.id);
          if (_profile == null) {
            await _client.auth.signOut();
            _isAuthenticated = false;
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
  /// The [encryptionPassphrase] is used to derive the Master Key (KEK),
  /// which unwraps the DEK from user_settings. The DEK is then held in
  /// memory and cached in sessionStorage.
  Future<void> signIn({
    required String email,
    required String password,
    required String encryptionPassphrase,
  }) async {
    _error = null;
    _needsMigration = false;
    notifyListeners();
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      if (response.user == null) throw Exception('Sign in failed');
      _isAuthenticated = true;
      _profile = await _fetchProfile(response.user!.id);
      if (_profile == null) {
        await _ensureProfile(response.user!);
        _profile = await _fetchProfile(response.user!.id);
      }

      // Load or detect missing encryption envelope
      await _loadOrDetectEnvelope(encryptionPassphrase, response.user!.id);
    } on AuthException catch (e) {
      _error = _userFriendlyError(e);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  /// Sign in WITHOUT encryption passphrase — for users who haven't set up
  /// encryption yet. Detects if migration is needed and sets the flag.
  Future<void> signInWithoutEncryption({
    required String email,
    required String password,
  }) async {
    _error = null;
    _needsMigration = false;
    notifyListeners();
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      if (response.user == null) throw Exception('Sign in failed');
      _isAuthenticated = true;
      _profile = await _fetchProfile(response.user!.id);
      if (_profile == null) {
        await _ensureProfile(response.user!);
        _profile = await _fetchProfile(response.user!.id);
      }

      // Detect if user has an encryption envelope
      final userId = response.user!.id;
      final salt = await _fetchSalt(userId);
      final wrappedB64 = await _fetchEncryptedDek(userId);
      if (salt == null || wrappedB64 == null || wrappedB64.isEmpty) {
        _needsMigration = true;
      }
    } on AuthException catch (e) {
      _error = _userFriendlyError(e);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // Sign up
  // -----------------------------------------------------------------

  /// Sign up a new user with encryption setup.
  ///
  /// Generates a DEK, wraps it with the Master Key (derived from
  /// [encryptionPassphrase]), and stores the envelope in user_settings.
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
      final response = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {
          'full_name': fullName,
          'role': isFirstAdmin ? 'admin' : 'user',
          'status': (isFirstAdmin || inviteToken != null) ? 'approved' : 'pending',
        },
      );

      if (response.user != null) {
        _isAuthenticated = true;
        await Future.delayed(const Duration(milliseconds: 500));
        _profile = await _fetchProfile(response.user!.id);
        if (_profile == null) {
          await _ensureProfile(response.user!);
          _profile = await _fetchProfile(response.user!.id);
        }

        // Create encryption envelope for the new user
        await _createEnvelope(encryptionPassphrase, response.user!.id);
      }

      if (inviteToken != null && response.user != null) {
        await _markInviteUsed(inviteToken.trim().toLowerCase());
      }
    } on AuthException catch (e) {
      _error = _userFriendlyError(e);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // Sign out
  // -----------------------------------------------------------------

  Future<void> signOut() async {
    CryptoService.clearSessionCache();
    _dek = null;
    _needsMigration = false;
    await _client.auth.signOut();
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
    CryptoService.cacheDekInSession(dek);
    notifyListeners();
  }

  /// Recover from a mnemonic phrase (forgot passphrase).
  Future<void> recoverWithMnemonic(String phrase) async {
    _dek = await CryptoService.mnemonicToDek(phrase);
    // Verify against stored recovery_hash
    final userId = _profile?.id;
    if (userId != null) {
      final expectedHash = await _fetchRecoveryHash(userId);
      if (expectedHash != null) {
        final actualHash = CryptoService.hashRecoveryPhrase(phrase);
        if (actualHash != expectedHash) {
          _dek = null;
          throw Exception('Recovery phrase is incorrect');
        }
      }
    }
    CryptoService.cacheDekInSession(_dek!);
    _needsMigration = false;
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // Database state checks (unchanged)
  // -----------------------------------------------------------------

  Future<bool?> checkDatabaseState() async {
    try {
      final hasProfiles = await _client.rpc('has_profiles');
      if (hasProfiles) return false;
      return true;
    } catch (_) {
      return null;
    }
  }

  Future<bool> validateInviteToken(String token) async {
    try {
      final resp = await _client
          .from('invites')
          .select()
          .eq('token', token.trim().toLowerCase())
          .eq('used', false)
          .limit(1);
      final invites = resp as List;
      if (invites.isEmpty) return false;
      final invite = Invite.fromJson(invites.first as Map<String, dynamic>);
      return invite.isActive;
    } catch (_) {
      return false;
    }
  }

  Future<void> refreshProfile() async {
    final session = _client.auth.currentSession;
    if (session != null) {
      _profile = await _fetchProfile(session.user.id);
      notifyListeners();
    }
  }

  // -----------------------------------------------------------------
  // Encryption envelope helpers
  // -----------------------------------------------------------------

  /// Check if user_settings has an encrypted_dek.
  /// If yes, unwrap it and cache the DEK.
  /// If no, set [_needsMigration] = true.
  Future<void> _loadOrDetectEnvelope(String passphrase, String userId) async {
    final salt = await _fetchSalt(userId);
    final wrappedB64 = await _fetchEncryptedDek(userId);

    if (salt == null || wrappedB64 == null || wrappedB64.isEmpty) {
      // No envelope exists — user needs to migrate
      _needsMigration = true;
      return;
    }

    // Derive Master Key and unwrap DEK
    final saltBytes = _saltFromBase64(salt);
    final masterKey = await CryptoService.deriveMasterKey(passphrase, saltBytes);
    _dek = await CryptoService.unwrapDekBase64(wrappedB64, masterKey);

    // Cache in sessionStorage for page-refresh survival
    CryptoService.cacheDekInSession(_dek!);
  }

  /// Create a fresh encryption envelope for a new user.
  Future<void> _createEnvelope(String passphrase, String userId) async {
    final salt = CryptoService.generateSalt();
    final masterKey = await CryptoService.deriveMasterKey(passphrase, salt);
    final dek = await CryptoService.generateDek();
    final wrappedB64 = await CryptoService.wrapDekBase64(dek, masterKey);
    final recoveryPhrase = await CryptoService.dekToMnemonic(dek);
    final recoveryHash = CryptoService.hashRecoveryPhrase(recoveryPhrase);

    // Store envelope in user_settings
    await _client.from('user_settings').upsert({
      'user_id': userId,
      'encrypted_dek': wrappedB64,
      'kek_salt': _saltToBase64(salt),
      'kek_iterations': CryptoService.kekIterations,
      'recovery_hash': recoveryHash,
    }, onConflict: 'user_id');

    _dek = dek;
    CryptoService.cacheDekInSession(dek);
  }

  /// Fetch the salt from user_settings (base64 string or null).
  Future<String?> _fetchSalt(String userId) async {
    try {
      final resp = await _client
          .from('user_settings')
          .select('kek_salt')
          .eq('user_id', userId)
          .limit(1);
      final rows = resp as List<dynamic>;
      if (rows.isEmpty) return null;
      return (rows.first as Map<String, dynamic>)['kek_salt'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Fetch the encrypted DEK from user_settings (base64 string or null).
  Future<String?> _fetchEncryptedDek(String userId) async {
    try {
      final resp = await _client
          .from('user_settings')
          .select('encrypted_dek')
          .eq('user_id', userId)
          .limit(1);
      final rows = resp as List<dynamic>;
      if (rows.isEmpty) return null;
      return (rows.first as Map<String, dynamic>)['encrypted_dek'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Fetch the recovery hash from user_settings.
  Future<String?> _fetchRecoveryHash(String userId) async {
    try {
      final resp = await _client
          .from('user_settings')
          .select('recovery_hash')
          .eq('user_id', userId)
          .limit(1);
      final rows = resp as List<dynamic>;
      if (rows.isEmpty) return null;
      return (rows.first as Map<String, dynamic>)['recovery_hash'] as String?;
    } catch (_) {
      return null;
    }
  }

  // -----------------------------------------------------------------
  // Profile helpers (unchanged)
  // -----------------------------------------------------------------

  Future<UserProfile?> _fetchProfile(String userId) async {
    try {
      final resp = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserProfile.fromJson(resp);
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureProfile(User user) async {
    try {
      final fullName = user.userMetadata?['full_name'] as String?;
      final storedRole = user.userMetadata?['role'] as String?;
      final storedStatus = user.userMetadata?['status'] as String?;

      bool isFirstUser = false;
      try {
        final hasProfiles = await _client.rpc('has_profiles');
        isFirstUser = !hasProfiles;
      } catch (_) {
        isFirstUser = true;
      }

      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'full_name': fullName,
        'role': isFirstUser || storedRole == 'admin' ? 'admin' : 'user',
        'status': (isFirstUser || storedStatus == 'approved') ? 'approved' : 'pending',
      }, onConflict: 'id');
    } catch (_) {}
  }

  Future<void> _markInviteUsed(String token) async {
    try {
      await _client
          .from('invites')
          .update({'used': true})
          .eq('token', token);
    } catch (_) {}
  }

  String _userFriendlyError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) return 'Invalid email or password';
    if (msg.contains('user already registered')) return 'An account with this email already exists';
    if (msg.contains('email not confirmed')) return 'Please confirm your email address';
    return e.message;
  }

  // -----------------------------------------------------------------
  // Encoding helpers
  // -----------------------------------------------------------------

  static String _saltToBase64(Uint8List salt) =>
      base64.encode(salt);

  static Uint8List _saltFromBase64(String b64) =>
      Uint8List.fromList(base64.decode(b64));
}
