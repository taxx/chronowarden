import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Screen shown when a user has an encryption envelope but hasn't entered
/// their passphrase yet (e.g., logging in on a new device).
class PassphraseScreen extends StatefulWidget {
  const PassphraseScreen({super.key});

  @override
  State<PassphraseScreen> createState() => _PassphraseScreenState();
}

class _PassphraseScreenState extends State<PassphraseScreen> {
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  final _auth = AuthService();

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_passCtrl.text.isEmpty) return;
    setState(() => _loading = true);

    try {
      await _auth.unlockEncryption(_passCtrl.text);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  'Unlock Your Data',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your data is encrypted. Enter your encryption passphrase '
                  'to unlock it.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  onSubmitted: (_) => _unlock(),
                  decoration: InputDecoration(
                    labelText: 'Encryption passphrase',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.shield_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _unlock,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.lock_open),
                    label: const Text('Unlock'),
                  ),
                ),

                // --- Recovery option ---
                const SizedBox(height: 24),
                Text(
                  'Forgot your passphrase?',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showRecoveryDialog(context),
                  icon: const Icon(Icons.key, size: 18),
                  label: const Text('Use recovery phrase'),
                ),

                // --- Danger notice ---
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Your data is encrypted with AES-256-GCM. '
                    'No one — not even the admin — can read it without '
                    'your passphrase.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRecoveryDialog(BuildContext ctx) async {
    final ctrl = TextEditingController();
    await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Recovery Phrase'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Enter your 24-word recovery phrase',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await _auth.recoverWithMnemonic(ctrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Recover'),
          ),
        ],
      ),
    );
  }
}
