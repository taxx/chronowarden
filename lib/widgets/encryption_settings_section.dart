import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../screens/about_encryption_screen.dart';
import '../services/auth_service.dart';
import '../services/crypto_service.dart';
import 'recovery_phrase_card.dart';

// ---------------------------------------------------------------------------
// Encryption section
// ---------------------------------------------------------------------------

class EncryptionSection extends StatelessWidget {
  const EncryptionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AuthService();
    final hasDek = auth.dek != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasDek ? Icons.lock : Icons.lock_open,
                  color: hasDek ? Colors.green : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.t('Encryption'),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (hasDek)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.t('ACTIVE'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hasDek
                  ? context.t(
                      'Your data is encrypted with AES-256-GCM. '
                      'No one — not even the admin — can read it.',
                    )
                  : context.t(
                      'Encryption not yet set up. Your data is stored '
                      'in plaintext.',
                    ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AboutEncryptionScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outlined, size: 18),
                label: Text(context.t('How encryption works')),
              ),
            ),
            if (hasDek) ...[const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showRecoveryPhrase(context),
                icon: const Icon(Icons.key, size: 18),
                label: Text(context.t('Show recovery phrase')),
              ),
            ),],
          ],
        ),
      ),
    );
  }

  Future<void> _showRecoveryPhrase(BuildContext context) async {
    final theme = Theme.of(context);
    final auth = AuthService();
    if (auth.dek == null) return;

    final phrase = await CryptoService.dekToMnemonic(auth.dek!);
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.t('Recovery Phrase')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecoveryPhraseCard(phrase: phrase, title: null),
            const SizedBox(height: 16),
            Text(
              context.t(
                'If you forget your encryption passphrase, this 24-word '
                'phrase is the only way to recover your data. Store it '
                'somewhere safe.',
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            RecoveryWarningCard(
              message: context.t(
                'Without this phrase, lost data is gone forever. '
                'No one — not even the admin — can recover it.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t('Close')),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phrase));
              Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.t('Recovery phrase copied'))),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(context.t('Copy')),
          ),
        ],
      ),
    );
  }
}

