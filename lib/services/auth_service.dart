import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/invite.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

/// Handles sign-in, sign-up, sign-out, and session state.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  SupabaseClient get _client => SupabaseService.instance.client;

  UserProfile? _profile;
  bool _isAuthenticated = false;
  bool _isInitializing = true;
  String? _error;

  UserProfile? get profile => _profile;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitializing => _isInitializing;
  String? get error => _error;

  /// Check for an existing session and load (or create) the profile.
  Future<void> init() async {
    try {
      final session = _client.auth.currentSession;
      if (session != null) {
        _isAuthenticated = true;
        _profile = await _fetchProfile(session.user.id);
        if (_profile == null) {
          // Profile row missing (e.g. user signed up before tables were created).
          // Create a default profile and try again.
          await _ensureProfile(session.user);
          _profile = await _fetchProfile(session.user.id);
          if (_profile == null) {
            // Tables likely don't exist yet → sign out and let setup handle it.
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

  /// Create (or upsert) a profile row for a user that doesn't have one yet.
  /// If no profiles exist at all (first user after schema creation), make them admin.
  Future<void> _ensureProfile(User user) async {
    try {
      final fullName = user.userMetadata?['full_name'] as String?;
      final storedRole = user.userMetadata?['role'] as String?;
      final storedStatus = user.userMetadata?['status'] as String?;

      // If profiles table is empty, this is the first real user → admin.
      bool isFirstUser = false;
      try {
        final hasProfiles = await _client.rpc('has_profiles');
        isFirstUser = !hasProfiles;
      } catch (_) {
        isFirstUser = true;
      }

      // Use upsert so we don't fail if the trigger already created it.
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'full_name': fullName,
        'role': isFirstUser || storedRole == 'admin' ? 'admin' : 'user',
        'status': (isFirstUser || storedStatus == 'approved') ? 'approved' : 'pending',
      }, onConflict: 'id');
    } catch (_) {
      // Non-critical — caller will handle missing profile.
    }
  }

  /// Sign in with email/password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _error = null;
    notifyListeners();
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      if (response.user == null) throw Exception('Sign in failed');
      _isAuthenticated = true;
      _profile = await _fetchProfile(response.user!.id);
      // Auto-create profile if missing (e.g. user signed up before tables existed).
      if (_profile == null) {
        await _ensureProfile(response.user!);
        _profile = await _fetchProfile(response.user!.id);
      }
    } on AuthException catch (e) {
      _error = _userFriendlyError(e);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  /// Sign up a new user. If [inviteToken] is valid → auto-approved.
  /// If [isFirstAdmin] → always admin + approved (empty DB bootstrap).
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
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
        // Wait briefly for the DB trigger to create the profile, then fetch.
        await Future.delayed(const Duration(milliseconds: 500));
        _profile = await _fetchProfile(response.user!.id);
        // Fallback if trigger didn't fire in time.
        if (_profile == null) {
          await _ensureProfile(response.user!);
          _profile = await _fetchProfile(response.user!.id);
        }
      }

      // Mark invite as used if provided.
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

  /// Sign out.
  Future<void> signOut() async {
    await _client.auth.signOut();
    _isAuthenticated = false;
    _profile = null;
    _error = null;
    notifyListeners();
  }

  /// Check database state for routing decisions.
  /// - `null`  = tables don't exist yet (show SetupScreen)
  /// - `true`  = tables exist but no profiles (show first-admin SignupScreen)
  /// - `false` = tables exist and have users (show LoginScreen)
  Future<bool?> checkDatabaseState() async {
    try {
      // Use RPC (SECURITY DEFINER) to bypass RLS — unauthenticated clients
      // can't query profiles directly due to row-level security.
      final hasProfiles = await _client.rpc('has_profiles');
      if (hasProfiles) return false;
      return true; // empty profiles = first-admin signup
    } catch (_) {
      // Function/table doesn't exist yet — show setup screen.
      return null;
    }
  }

  /// Validate an invite token. Returns true if the token exists, is unused, and not expired.
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

  /// Fetch the current profile after status changes (e.g. admin approval).
  Future<void> refreshProfile() async {
    final session = _client.auth.currentSession;
    if (session != null) {
      _profile = await _fetchProfile(session.user.id);
      notifyListeners();
    }
  }

  // -- private helpers --

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

  Future<void> _markInviteUsed(String token) async {
    try {
      await _client
          .from('invites')
          .update({'used': true})
          .eq('token', token);
    } catch (_) {
      // Non-critical — invite still works once.
    }
  }

  String _userFriendlyError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) return 'Invalid email or password';
    if (msg.contains('user already registered')) return 'An account with this email already exists';
    if (msg.contains('email not confirmed')) return 'Please confirm your email address';
    return e.message;
  }
}
