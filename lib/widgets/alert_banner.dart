import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// In-app alert banner
// ---------------------------------------------------------------------------

/// A colored banner shown at the top of a screen when an alert fires.
class AlertBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const AlertBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrgent = message.contains('🚨');
    return Card(
      color: isUrgent ? theme.colorScheme.errorContainer : theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              isUrgent ? Icons.warning_rounded : Icons.info_outlined,
              color: isUrgent ? theme.colorScheme.onErrorContainer : theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

