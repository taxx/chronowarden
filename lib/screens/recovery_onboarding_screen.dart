import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/recovery_phrase_card.dart';

/// One-time recovery phrase onboarding shown after signup for approved users.
class RecoveryOnboardingScreen extends StatelessWidget {
  final String phrase;
  const RecoveryOnboardingScreen({
    super.key,
    required this.phrase,
  });

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

