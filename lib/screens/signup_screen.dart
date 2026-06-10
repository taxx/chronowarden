import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

/// Sign-up screen with optional invite token.
/// [isFirstAdmin] → skip invite token, create admin directly.
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
  bool _loading = false;
  bool _validatingToken = false;
  bool? _tokenValid;
  final _auth = AuthService();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _tokenCtrl.dispose();
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
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty || _nameCtrl.text.isEmpty) return;

    // If not first admin and no valid token, warn but allow pending signup.
    if (!widget.isFirstAdmin && _tokenValid == false && _tokenCtrl.text.isNotEmpty) {
      if (!mounted) return;
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

    return Scaffold(
      appBar: AppBar(title: Text(widget.isFirstAdmin ? 'Create Admin' : 'Create Account')),
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
                      'You are the first user. This account will have admin privileges.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
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
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password (min 6 characters)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
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
                            prefixIcon: const Icon(Icons.confirmation_number_outlined),
                            suffixIcon: _validatingToken
                                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                                : (_tokenValid == true
                                    ? const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.check_circle, color: Colors.green))
                                    : (_tokenValid == false
                                        ? const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.cancel, color: Colors.red))
                                        : IconButton(
                                            icon: const Icon(Icons.verified_outlined),
                                            onPressed: _validateToken,
                                          ))),
                            helperText: 'Without a token your account will need admin approval',
                            helperStyle: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (err != null) ...[
                  const SizedBox(height: 12),
                  Text(err, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _signUp,
                    icon: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(widget.isFirstAdmin ? Icons.admin_panel_settings : Icons.app_registration),
                    label: Text(widget.isFirstAdmin ? 'Create Admin Account' : 'Create Account'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: widget.isFirstAdmin
                      // First-admin screen: navigate to login.
                      // We push LoginScreen on top because the root widget
                      // routes here based on DB state — popping won't re-evaluate.
                      ? () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          )
                      : () => Navigator.of(context).maybePop(),
                  child: Text(widget.isFirstAdmin
                      ? 'Already signed up before? Sign in'
                      : 'Already have an account? Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
