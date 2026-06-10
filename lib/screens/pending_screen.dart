import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Shown when the user's account is pending admin approval.
class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  final _auth = AuthService();
  bool _checking = false;

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    await _auth.refreshProfile();
    setState(() => _checking = false);
  }

  Future<void> _signOut() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = _auth.profile;

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: _checking ? null : _checkStatus,
            child: _checking
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Check status'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_bottom, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                'Account Pending Approval',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Your account has been created but needs to be approved by an administrator.\n\n'
                'Please contact your admin or check back later.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              if (profile?.email != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Signed in as: ${profile!.email}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
