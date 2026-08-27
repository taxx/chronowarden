import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/paste_button.dart';
import 'migration_screen.dart';
import 'signup_screen.dart';

/// Email/password login screen with encryption passphrase.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _encCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureEnc = true;
  bool _showEncryption = false;
  final _auth = AuthService();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _encCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;

    setState(() => _loading = true);

    if (_showEncryption && _encCtrl.text.isNotEmpty) {
      // Normal flow: user has encryption set up
      await _auth.signIn(
        email: _emailCtrl.text,
        password: _passCtrl.text,
        encryptionPassphrase: _encCtrl.text,
      );
    } else {
      // Bootstrap / migration flow: user hasn't set up encryption yet
      await _auth.signInWithoutEncryption(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
    }

    if (mounted) {
      setState(() => _loading = false);
      _handlePostLogin();
    }
  }

  void _handlePostLogin() {
    if (_auth.isAuthenticated && _auth.needsMigration) {
      // User has no encryption envelope → show migration screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MigrationScreen()),
      );
    }
    // Otherwise, main.dart routing handles the redirect
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final err = _auth.error;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule,
                    size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text('ChronoWarden',
                    style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 32),

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
                    labelText: 'Password',
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

                // --- Encryption passphrase (optional toggle) ---
                if (_showEncryption) ...[
                  TextField(
                    controller: _encCtrl,
                    obscureText: _obscureEnc,
                    decoration: InputDecoration(
                      labelText: 'Encryption passphrase',
                      hintText: 'Enter to unlock your encrypted data',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.shield_outlined),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PasteButton(controller: _encCtrl),
                          IconButton(
                            icon: Icon(_obscureEnc
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _obscureEnc = !_obscureEnc),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  InkWell(
                    onTap: () => setState(() => _showEncryption = true),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            'I have an encryption passphrase',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // --- Error ---
                if (err != null) ...[
                  const SizedBox(height: 12),
                  Text(err,
                      style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 20),

                // --- Sign in button ---
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _login,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Sign up link ---
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  ),
                  child: const Text("Don't have an account? Sign up"),
                ),

                // --- Info about encryption ---
                const SizedBox(height: 16),
                Text(
                  '🔐 Your data is encrypted end-to-end. '
                  'Even the admin cannot read it.',
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
