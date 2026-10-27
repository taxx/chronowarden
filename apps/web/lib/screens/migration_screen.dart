import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/migration_service.dart';
import '../widgets/recovery_phrase_card.dart';

/// One-time encryption setup screen for existing users.
///
/// Shown when [AuthService.needsMigration] is true — the user has
/// plaintext data that needs to be encrypted.
class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _migrationSvc = MigrationService();

  bool _loading = false;
  bool _done = false;
  String? _error;
  String? _recoveryPhrase;
  double _progress = 0;

  bool get _passwordsMatch =>
      _passCtrl.text.isNotEmpty && _passCtrl.text == _confirmCtrl.text;

  bool get _strongEnough => _passCtrl.text.length >= 8;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _startMigration() async {
    if (!_passwordsMatch) {
      setState(() => _error = context.t('Passphrases do not match'));
      return;
    }
    if (!_strongEnough) {
      setState(() => _error = context.t('Passphrase must be at least 8 characters'));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _progress = 0;
    });

    _migrationSvc.setProgressCallback((p) {
      if (mounted) setState(() => _progress = p);
    });

    try {
      final phrase = await _migrationSvc.migrate(_passCtrl.text);
      setState(() {
        _done = true;
        _recoveryPhrase = phrase;
        _loading = false;
        _progress = 1;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_done && _recoveryPhrase != null) {
      return _buildRecoveryStep(theme);
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Warning banner ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.tertiary),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: theme.colorScheme.onTertiaryContainer,
                            size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.t('Important Security Update'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onTertiaryContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.t(
                                  'Your data is currently stored without encryption. '
                                  'To protect your privacy, we need to encrypt all your '
                                  'existing records. This is a one-time process.',
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Explanation ---
                  Text(
                    context.t('Set Your Encryption Passphrase'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _explanationText(context, theme),
                  const SizedBox(height: 24),

                  // --- Passphrase fields ---
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: context.t('Encryption passphrase'),
                      hintText: context.t('At least 8 characters'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: _passCtrl.text.length >= 8
                          ? const Icon(Icons.check_circle,
                              color: Colors.green, size: 20)
                          : null,
                    ),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: context.t('Confirm passphrase'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: _passwordsMatch && _passCtrl.text.isNotEmpty
                          ? const Icon(Icons.check_circle,
                              color: Colors.green, size: 20)
                          : null,
                    ),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 8),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  const SizedBox(height: 24),

                  // --- Progress bar ---
                  if (_loading) ...[
                    LinearProgressIndicator(value: _progress),
                    const SizedBox(height: 8),
                    Text(
                      context.t('Encrypting your data ({percent}%)...',
                          {'percent': (_progress * 100).toInt()}),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // --- Start button ---
                  FilledButton.icon(
                    onPressed: _loading ? null : _startMigration,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.shield),
                    label: Text(_loading
                        ? context.t('Encrypting...')
                        : context.t('Start Encryption')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecoveryStep(ThemeData theme) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    context.t('Encryption Complete!'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.t(
                      'Your data is now encrypted and cannot be read by anyone '
                      'except you.',
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // --- Recovery phrase ---
                  RecoveryPhraseCard(
                    phrase: _recoveryPhrase!,
                    description: context.t(
                      'Write this down and keep it in a safe place. '
                      'If you forget your passphrase, this is the only '
                      'way to recover your data.',
                    ),
                  ),

                  // --- Warning ---
                  const SizedBox(height: 24),
                  RecoveryWarningCard(
                    message: context.t(
                      'If you lose both your passphrase AND this '
                      'recovery phrase, your data is gone forever. '
                      'No one — not even the app administrator — '
                      'can recover it.',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Done button ---
                  // AuthService already has the DEK set by MigrationService,
                  // which called setDekAfterMigration → notifyListeners().
                  // The parent widget (main.dart) will already show MainShell
                  // because needsMigration is now false.
                  // This button is a no-op — the rebuild already happened.
                  FilledButton.icon(
                    onPressed: () {
                      // Just a visual cue — parent already rebuilt.
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(context.t('Continue to App')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _explanationText(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _explainRow(context, '🔐',
            context.t('Your passphrase creates a Master Key that protects your Data '
                'Encryption Key. Your data is encrypted with AES-256-GCM.')),
        const SizedBox(height: 8),
        _explainRow(context, '🔑',
            context.t('A random Data Encryption Key (DEK) is generated and stored '
                'encrypted on the server. The DEK never leaves your device '
                'in plaintext.')),
        const SizedBox(height: 8),
        _explainRow(context, '🔄',
            context.t('On other devices, enter the same passphrase to unlock the '
                'same DEK — your data is accessible everywhere.')),
        const SizedBox(height: 8),
        _explainRow(context, '⚠️',
            context.t('No one — not even the app administrator — can read your '
                'encrypted data. If you forget your passphrase, your data '
                'is unrecoverable unless you have the recovery phrase.')),
      ],
    );
  }

  Widget _explainRow(BuildContext context, String icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}


