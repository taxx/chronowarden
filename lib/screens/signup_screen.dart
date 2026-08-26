import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

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
    if (mounted) setState(() => _loading = false);
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
                    suffixIcon: encOk
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 20)
                        : null,
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
                    suffixIcon: encMatch
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 20)
                        : null,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
