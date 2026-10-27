import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/user_profile.dart';
import '../models/invite.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

/// Admin user management screen.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _profileSvc = ProfileService();
  final _auth = AuthService();

  List<UserProfile> _users = [];
  List<Invite> _invites = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final users = await _profileSvc.allUsers();
      final invites = await _profileSvc.allInvites();
      setState(() {
        _users = users;
        _invites = invites;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _approve(String id) async {
    await _profileSvc.approveUser(id);
    await _load();
    if (mounted) _snack('User approved');
  }

  Future<void> _reject(String id) async {
    await _profileSvc.rejectUser(id);
    await _load();
    if (mounted) _snack(context.t('User rejected'));
  }

  Future<void> _deleteUser(String id, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.t('Delete user')),
        content: Text(context.t(
          'Permanently delete "{email}" and all their data? This cannot be undone.',
          {'email': email},
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.t('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: Text(context.t('Delete'))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _profileSvc.deleteUser(id);
        await _load();
        if (mounted) _snack(context.t('User deleted'));
      } catch (e) {
        if (mounted) {
          final msg = e.toString();
          final longMsg = msg.contains('Supabase dashboard admin')
              ? SnackBar(
                  content: Text(msg),
                  duration: const Duration(seconds: 8),
                  action: SnackBarAction(
                    label: context.t('Dismiss'),
                    onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  ),
                )
              : SnackBar(content: Text(msg));
          ScaffoldMessenger.of(context).showSnackBar(longMsg);
        }
      }
    }
  }

  Future<void> _createInvite() async {
    final emailCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.t('Create Invite')),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: context.t('Email (optional — for reference)'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.t('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.t('Create'))),
        ],
      ),
    );
    if (result == true) {
      try {
        final token = await _profileSvc.createInvite(email: emailCtrl.text.isEmpty ? null : emailCtrl.text);
        await _load();
        if (mounted) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(context.t('Invite Token Created')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t('Share this token with the new user:')),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      token,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: token));
                    Navigator.pop(context);
                    _snack(context.t('Token copied to clipboard'));
                  },
                  child: Text(context.t('Copy')),
                ),
                FilledButton(onPressed: () => Navigator.pop(context), child: Text(context.t('Done'))),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('Error: {error}', {'error': e}))));
        }
      }
    }
  }

  Future<void> _deleteInvite(String id) async {
    await _profileSvc.deleteInvite(id);
    await _load();
  }

  void _snack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(text: context.t('Users')),
            Tab(text: context.t('Invites')),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildUsersTab(theme),
              _buildInvitesTab(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab(ThemeData theme) {
    if (_users.isEmpty) {
      return Center(child: Text(context.t('No users yet')));
    }

    final isAdmin = _auth.profile;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _users.length,
      itemBuilder: (ctx, i) {
        final user = _users[i];
        // Don't show self-delete for the last admin.
        final isSelf = user.id == isAdmin?.id;
        final isLastAdmin = isSelf && _users.where((u) => u.isAdmin).length <= 1;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: user.isApproved
                  ? theme.colorScheme.primaryContainer
                  : (user.isPending ? Colors.amber.shade100 : theme.colorScheme.errorContainer),
              child: Icon(
                user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                size: 20,
                color: user.isApproved
                    ? theme.colorScheme.primary
                    : (user.isPending ? Colors.amber.shade800 : theme.colorScheme.onErrorContainer),
              ),
            ),
            title: Text(user.fullName ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email, style: theme.textTheme.bodySmall),
                Row(
                  children: [
                    _statusChip(theme, user.status),
                    if (user.isAdmin) ...[
                      const SizedBox(width: 6),
                      _statusChip(theme, context.t('admin'), color: Colors.deepPurple),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user.isPending) ...[
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    onPressed: () => _approve(user.id),
                    tooltip: context.t('Approve'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    onPressed: () => _reject(user.id),
                    tooltip: context.t('Reject'),
                  ),
                ],
                if (!isLastAdmin)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                    onPressed: () => _deleteUser(user.id, user.email),
                    tooltip: context.t('Delete'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvitesTab(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _createInvite,
            icon: const Icon(Icons.add),
            label: Text(context.t('Create Invite')),
          ),
        ),
        if (_invites.isEmpty)
          Expanded(child: Center(child: Text(context.t('No invites yet')))),
        if (_invites.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _invites.length,
              itemBuilder: (ctx, i) {
                final inv = _invites[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      inv.isActive ? Icons.confirmation_number : Icons.confirmation_number_outlined,
                      color: inv.isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      inv.token,
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
                    subtitle: inv.email != null ? Text(inv.email!) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (inv.isActive)
                          Text(
                            inv.isExpired ? context.t('Expired') : (inv.used ? context.t('Used') : context.t('Active')),
                            style: TextStyle(
                              fontSize: 12,
                              color: inv.isExpired ? Colors.red : (inv.used ? theme.colorScheme.onSurfaceVariant : Colors.green),
                            ),
                          ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade700, size: 20),
                          onPressed: () => _deleteInvite(inv.id!),
                          tooltip: context.t('Delete'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _statusChip(ThemeData theme, String status, {Color? color}) {
    final colors = {
      'approved': Colors.green,
      'pending': Colors.amber,
      'rejected': Colors.red,
      'admin': Colors.deepPurple,
    };
    final c = color ?? colors[status] ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        context.t(status),
        style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600),
      ),
    );
  }
}
