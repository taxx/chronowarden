import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/paste_button.dart';
import '../widgets/recovery_phrase_card.dart';
import 'about_encryption_screen.dart';
import 'login_screen.dart';
import 'pending_screen.dart';

/// Sign-up screen with encryption passphrase setup.
///
/// [isFirstAdmin] → skip invite token, create admin directly.
/// All new users set up encryption at signup time.
class SignupScreen extends StatefulWidget {
  final bool isFirstAdmin;

  const SignupScreen({super.key, this.isFirstAdmin = false});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _encCtrl = TextEditingController();
  final _encConfirmCtrl = TextEditingController();
  bool _loading = false;
  bool _validatingToken = false;
  bool? _tokenValid;
  bool _obscurePass = true;
  final bool _obscureEnc = true;
  final _auth = AuthService();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _tokenCtrl.dispose();
    _encCtrl.dispose();
    _encConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _validateToken() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) {
      setState(() => _tokenValid = null);
      return;
    }
    setState(() => _validatingToken = true);
    _tokenValid = await _auth.validateInviteToken(token);
    setState(() => _validatingToken = false);
  }

  Future<void> _signUp() async {
    if (_emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty ||
        _nameCtrl.text.isEmpty) {
      return;
    }

    // Validate encryption passphrase
    if (_encCtrl.text.length < 8) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Encryption passphrase must be at least 8 characters'),
        ),
      );
      return;
    }
    if (_encCtrl.text != _encConfirmCtrl.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Encryption passphrases do not match')),
      );
      return;
    }

    if (!widget.isFirstAdmin && _tokenValid == false && _tokenCtrl.text.isNotEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or expired invite token')),
      );
      return;
    }

    setState(() => _loading = true);
    await _auth.signUp(
      email: _emailCtrl.text,
      password: _passCtrl.text,
      fullName: _nameCtrl.text,
      encryptionPassphrase: _encCtrl.text,
      inviteToken: _tokenCtrl.text.trim().isEmpty ? null : _tokenCtrl.text.trim(),
      isFirstAdmin: widget.isFirstAdmin,
    );
    if (mounted) {
      setState(() => _loading = false);
      _handlePostSignUp();
    }
  }

  void _handlePostSignUp() {
    if (!_auth.isAuthenticated) return;
    final profile = _auth.profile;
    if (profile == null) return;

    if (!profile.isApproved) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PendingScreen()),
      );
      return;
    }

    // Approved user: show recovery phrase if one was generated
    final phrase = _auth.pendingRecoveryPhrase;
    if (phrase != null && phrase.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _RecoveryOnboardingScreen(phrase: phrase),
        ),
      );
    }
  }

  void _showEncryptionInfoDialog(BuildContext ctx) {
    showDialog<void>(
      context: ctx,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: Theme.of(dialogContext).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'How we store & protect your data',
                        style: Theme.of(dialogContext).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: const EncryptionInfoContent(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final err = _auth.error;
    final showToken = !widget.isFirstAdmin;
    final encOk = _encCtrl.text.length >= 8;
    final encMatch =
        encOk && _encCtrl.text == _encConfirmCtrl.text;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstAdmin ? 'Create Admin' : 'Create Account'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isFirstAdmin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'You are the first user. This account will have '
                      'admin privileges.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // --- Name ---
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),

                // --- Email ---
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // --- Password ---
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Password (min 6 characters)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // --- Encryption passphrase ---
                TextField(
                  controller: _encCtrl,
                  obscureText: _obscureEnc,
                  decoration: InputDecoration(
                    labelText: 'Encryption passphrase',
                    hintText: 'At least 8 characters',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.shield_outlined),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PasteButton(controller: _encCtrl),
                        if (encOk)
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                      ],
                    ),
                    helperText: '🔐 This passphrase encrypts ALL your data. '
                        'If lost, your data is gone forever.',
                    helperStyle: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade800,
                    ),
                    helperMaxLines: 2,
                  ),
                ),
                const SizedBox(height: 12),

                // --- Confirm encryption passphrase ---
                TextField(
                  controller: _encConfirmCtrl,
                  obscureText: _obscureEnc,
                  decoration: InputDecoration(
                    labelText: 'Confirm encryption passphrase',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.shield_outlined),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PasteButton(controller: _encConfirmCtrl),
                        if (encMatch)
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                      ],
                    ),
                  ),
                ),

                // --- Invite token ---
                if (showToken) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tokenCtrl,
                          decoration: InputDecoration(
                            labelText: 'Invite token (optional)',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(
                                Icons.confirmation_number_outlined),
                            suffixIcon: _validatingToken
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : (_tokenValid == true
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Icon(Icons.check_circle,
                                            color: Colors.green),
                                      )
                                    : (_tokenValid == false
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Icon(Icons.cancel,
                                                color: Colors.red),
                                          )
                                        : IconButton(
                                            icon: const Icon(
                                                Icons.verified_outlined),
                                            onPressed: _validateToken,
                                          ))),
                            helperText: 'Without a token your account will '
                                'need admin approval',
                            helperStyle: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // --- Error ---
                if (err != null) ...[
                  const SizedBox(height: 12),
                  Text(err,
                      style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 20),

                // --- Sign up button ---
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _signUp,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(widget.isFirstAdmin
                            ? Icons.admin_panel_settings
                            : Icons.app_registration),
                    label: Text(widget.isFirstAdmin
                        ? 'Create Admin Account'
                        : 'Create Account'),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Sign in link ---
                TextButton(
                  onPressed: widget.isFirstAdmin
                      ? () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        )
                      : () => Navigator.of(context).maybePop(),
                  child: Text(widget.isFirstAdmin
                      ? 'Already signed up before? Sign in'
                      : 'Already have an account? Sign in'),
                ),

                // --- Encryption info ---
                const SizedBox(height: 16),
                Text(
                  '🔐 Your data will be encrypted with AES-256-GCM. '
                  'No one — not even the admin — can read it.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () => _showEncryptionInfoDialog(context),
                  child: Text(
                    'How we store & protect your data',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One-time recovery phrase onboarding shown after signup for approved users.
class _RecoveryOnboardingScreen extends StatelessWidget {
  final String phrase;
  const _RecoveryOnboardingScreen({required this.phrase});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Icon(Icons.key, color: Colors.amber, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Your Recovery Phrase',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This is the only way to recover your encrypted data if '
                    'you forget your encryption passphrase. Write it down '
                    'and keep it in a safe place.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  RecoveryPhraseCard(phrase: phrase),
                  const SizedBox(height: 24),
                  const RecoveryWarningCard(
                    message: 'If you lose both your passphrase AND this '
                        'recovery phrase, your data is gone forever. '
                        'No one — not even the app administrator — '
                        'can recover it.',
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {
                      AuthService().clearPendingRecoveryPhrase();
                      Navigator.of(context).popUntil(
                          (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue to App'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
