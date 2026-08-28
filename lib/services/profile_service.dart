import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/invite.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

/// Admin operations: list users, approve/reject, delete, manage invites.
///
/// Every method includes an application-level admin check for defense-in-depth.
/// Even if RLS policies were accidentally disabled, these guards prevent
/// non-admin users from calling admin operations.
class ProfileService {
  ProfileService._();
  static final ProfileService _instance = ProfileService._();
  factory ProfileService() => _instance;

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Returns true if the current user is an approved admin.
  bool get _isAdmin => AuthService().profile?.isAdmin == true;

  /// Throws if the current user is not an admin.
  void _requireAdmin() {
    if (!_isAdmin) {
      throw Exception('Admin privileges required');
    }
  }

  // -- profiles --

  Future<List<UserProfile>> allUsers() async {
    _requireAdmin();
    final resp = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    final rows = resp as List<dynamic>;
    return rows.map((r) => UserProfile.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Approve a pending user.
  Future<void> approveUser(String userId) async {
    _requireAdmin();
    await _client.from('profiles').update({'status': 'approved'}).eq('id', userId);
  }

  /// Reject a pending user.
  Future<void> rejectUser(String userId) async {
    _requireAdmin();
    await _client.from('profiles').update({'status': 'rejected'}).eq('id', userId);
  }

  /// Delete a user from the auth system.
  ///
  /// Falls back to rejecting the profile if admin API isn't available
  /// (anon key can't call auth.admin directly). When that happens, the
  /// auth.user row remains but the account is disabled (status = rejected).
  /// Full cleanup requires a Supabase dashboard admin to remove the orphaned
  /// auth user.
  Future<void> deleteUser(String userId) async {
    _requireAdmin();
    try {
      await _client.auth.admin.deleteUser(userId);
    } catch (_) {
      // Fallback: reject the profile — the auth.user row persists but
      // the account is disabled and cannot log in.
      await _client.from('profiles').update({'status': 'rejected'}).eq('id', userId);
      throw Exception(
        'Profile disabled. The auth account still exists in Supabase Auth — '
        'a Supabase dashboard admin must delete the orphaned user manually.',
      );
    }
  }

  // -- invites --

  Future<List<Invite>> allInvites() async {
    _requireAdmin();
    final resp = await _client
        .from('invites')
        .select()
        .order('created_at', ascending: false);
    final rows = resp as List<dynamic>;
    return rows.map((r) => Invite.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Create a new invite token. Returns the generated token.
  Future<String> createInvite({
    String? email,
    DateTime? expiresAt,
  }) async {
    _requireAdmin();
    final token = _generateToken();
    final json = {
      'token': token,
      'email': email,
      'expires_at': expiresAt?.toIso8601String(),
    };
    await _client.from('invites').insert(json);
    return token;
  }

  /// Delete an invite.
  Future<void> deleteInvite(String inviteId) async {
    _requireAdmin();
    await _client.from('invites').delete().eq('id', inviteId);
  }

  String _generateToken() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final r = Random.secure();
    return List.generate(12, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
