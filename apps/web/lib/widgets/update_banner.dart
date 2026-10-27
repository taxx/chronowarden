import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// Banner shown when a newer build has been deployed.
///
/// Offers a one-tap reload (the only reliable way to pick up new web assets)
/// plus a dismiss that suppresses the prompt until the *next* deploy.
class UpdateBanner extends StatelessWidget {
  final String message;
  final VoidCallback onReload;
  final VoidCallback onDismiss;

  const UpdateBanner({
    super.key,
    required this.message,
    required this.onReload,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(
              Icons.system_update_alt_rounded,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onReload,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimaryContainer,
              ),
              child: Text(context.t('Reload')),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: context.t('Dismiss'),
              onPressed: onDismiss,
              color: theme.colorScheme.onPrimaryContainer,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
