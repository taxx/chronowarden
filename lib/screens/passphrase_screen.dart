import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/paste_button.dart';

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
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Your data is encrypted with AES-256-GCM. '
                    'No one — not even the admin — can read it without '
                    'your passphrase.',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onErrorContainer,
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
          decoration: InputDecoration(
            labelText: 'Enter your 24-word recovery phrase',
            border: const OutlineInputBorder(),
            suffixIcon: PasteButton(controller: ctrl),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // First verify the recovery phrase
              final phrase = ctrl.text.trim();
              if (phrase.isEmpty) return;

              // Close the recovery dialog
              if (ctx.mounted) Navigator.pop(ctx, false);

              // Now show the new passphrase dialog
              if (!mounted) return;
              await _showSetNewPassphraseDialog(context, phrase);
            },
            child: const Text('Recover'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSetNewPassphraseDialog(
    BuildContext ctx,
    String recoveryPhrase,
  ) async {
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureNew = true;
    String? error;

    await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Set New Passphrase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your recovery phrase is valid. Now set a new encryption '
                'passphrase to protect your data.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPassCtrl,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'New encryption passphrase',
                  hintText: 'At least 8 characters',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.shield_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'Confirm new passphrase',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.shield_outlined),
                  suffixIcon: newPassCtrl.text == confirmCtrl.text &&
                          newPassCtrl.text.length >= 8
                      ? const Icon(Icons.check_circle,
                          color: Colors.green, size: 20)
                      : null,
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final newPass = newPassCtrl.text;
                final confirm = confirmCtrl.text;

                if (newPass.length < 8) {
                  setDialogState(() =>
                      error = 'Passphrase must be at least 8 characters');
                  return;
                }
                if (newPass != confirm) {
                  setDialogState(() => error = 'Passphrases do not match');
                  return;
                }

                try {
                  await _auth.recoverAndSetNewPassphrase(
                    recoveryPhrase,
                    newPass,
                  );
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                } catch (e) {
                  setDialogState(() => error = e.toString());
                }
              },
              child: const Text('Set Passphrase'),
            ),
          ],
        ),
      ),
    );
  }
}
