import 'dart:math';

import '../models/invite.dart';
import '../models/user_profile.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Admin operations: list users, approve/reject, delete, manage invites.
///
/// Every method includes an application-level admin check for defence in
/// depth; the API also enforces admin rights on every admin route.
class ProfileService {
  ProfileService._();
  static final ProfileService _instance = ProfileService._();
  factory ProfileService() => _instance;

  ApiClient get _api => ApiClient();

  bool get _isAdmin => AuthService().profile?.isAdmin == true;

  void _requireAdmin() {
    if (!_isAdmin) {
      throw Exception('Admin privileges required');
    }
  }

  // -- profiles --

  Future<List<UserProfile>> allUsers() async {
    _requireAdmin();
    final resp = await _api.get('/admin/users') as List<dynamic>;
    return resp
        .map((r) => UserProfile.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveUser(String userId) async {
    _requireAdmin();
    await _api.patch('/admin/users/$userId', {'status': 'approved'});
  }

  Future<void> rejectUser(String userId) async {
    _requireAdmin();
    await _api.patch('/admin/users/$userId', {'status': 'rejected'});
  }

  /// Permanently deletes a user. Sessions, settings, logs and presets cascade.
  Future<void> deleteUser(String userId) async {
    _requireAdmin();
    await _api.delete('/admin/users/$userId');
  }

  // -- invites --

  Future<List<Invite>> allInvites() async {
    _requireAdmin();
    final resp = await _api.get('/admin/invites') as List<dynamic>;
    return resp
        .map((r) => Invite.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Create (or refresh) an invite bound to [email].
  ///
  /// Returns the invite including the raw [Invite.token], which is shown to the
  /// admin exactly once so it can be shared out-of-band.
  Future<Invite> createInvite({
    required String email,
    DateTime? expiresAt,
  }) async {
    _requireAdmin();
    final ttlDays = expiresAt == null
        ? 14
        : max(1, expiresAt.difference(DateTime.now()).inDays);

    final resp = await _api.post('/admin/invites', {
      'email': email.trim().toLowerCase(),
      'ttlDays': ttlDays,
    }) as Map<String, dynamic>;
    return Invite.fromJson(resp);
  }

  Future<void> deleteInvite(String inviteId) async {
    _requireAdmin();
    await _api.delete('/admin/invites/$inviteId');
  }
}
