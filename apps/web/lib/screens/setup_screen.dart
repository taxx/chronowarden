import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Shown when the API cannot be reached (backend restarting, wrong URL, …).
///
/// The database schema is provisioned automatically by the API on startup, so
/// there is nothing for the user to copy or paste anymore — this screen just
/// explains the situation and offers a retry.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _retry() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final hasUsers = await AuthService().checkDatabaseState();

    if (!mounted) return;
    setState(() => _loading = false);

    if (hasUsers == null) {
      setState(() => _error = context.t('The server is still unavailable.'));
      return;
    }

    // Already signed in: refreshing AppState makes main.dart swap this screen
    // out for the main shell once the tables are ready.
    if (AuthService().isAuthenticated) {
      await AppState().refresh();
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => hasUsers
            ? const LoginScreen()
            : const SignupScreen(isFirstAdmin: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  context.t('Cannot reach the server'),
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  context.t(
                    'ChronoWarden could not reach its backend. It may still be '
                    'starting up. Check that the API and database containers are '
                    'running, then try again.',
                  ),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _loading ? null : _retry,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(context.t('Try again')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
