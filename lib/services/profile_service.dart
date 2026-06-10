import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/invite.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

/// Admin operations: list users, approve/reject, delete, manage invites.
class ProfileService {
  ProfileService._();
  static final ProfileService _instance = ProfileService._();
  factory ProfileService() => _instance;

  SupabaseClient get _client => SupabaseService.instance.client;

  // -- profiles --

  Future<List<UserProfile>> allUsers() async {
    final resp = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    final rows = resp as List<dynamic>;
    return rows.map((r) => UserProfile.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Approve a pending user.
  Future<void> approveUser(String userId) async {
    await _client.from('profiles').update({'status': 'approved'}).eq('id', userId);
  }

  /// Reject a pending user.
  Future<void> rejectUser(String userId) async {
    await _client.from('profiles').update({'status': 'rejected'}).eq('id', userId);
  }

  /// Delete a user from the auth system.
  /// Falls back to rejecting the profile if admin API isn't available
  /// (anon key can't call auth.admin directly).
  Future<void> deleteUser(String userId) async {
    try {
      await _client.auth.admin.deleteUser(userId);
    } catch (_) {
      // Fallback: reject the profile (effectively disables the account).
      // The auth.user row remains but can't log in (status = rejected).
      await _client.from('profiles').update({'status': 'rejected'}).eq('id', userId);
      throw Exception('User account disabled (contact Supabase admin to fully delete)');
    }
  }

  // -- invites --

  Future<List<Invite>> allInvites() async {
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
    await _client.from('invites').delete().eq('id', inviteId);
  }

  String _generateToken() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    // Simple pseudo-random token — sufficient for ≤5 users.
    final seed = DateTime.now().millisecondsSinceEpoch;
    final r = <int>[];
    for (var i = 0; i < 6; i++) {
      r.add(((seed * (i + 1) * 31) ^ (seed >> (i + 2))) % chars.length);
    }
    return r.map((i) => chars[i]).join();
  }
}
