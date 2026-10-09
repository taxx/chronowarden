import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// In-app alert banner
// ---------------------------------------------------------------------------

/// A colored banner shown at the top of a screen when an alert fires.
///
/// Supports an optional snooze action ("remind me later") alongside the
/// default dismiss (close) button.
class AlertBanner extends StatelessWidget {
  final String message;

  /// Fully dismiss the alert for the rest of the day.
  final VoidCallback onDismiss;

  /// Snooze the alert for a while. When null, no snooze button is shown.
  final VoidCallback? onSnooze;

  /// Label for the snooze button, e.g. "Snooze 10m".
  final String? snoozeLabel;

  /// Forces the urgent (error) color scheme. Falls back to detecting the
  /// emergency emoji for backwards compatibility.
  final bool? isUrgent;

  const AlertBanner({
    super.key,
    required this.message,
    required this.onDismiss,
    this.onSnooze,
    this.snoozeLabel,
    this.isUrgent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urgent = isUrgent ?? message.contains('🚨');
    final bg = urgent
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.tertiaryContainer;
    final fg = urgent
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onTertiaryContainer;
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(
              urgent ? Icons.warning_rounded : Icons.info_outlined,
              color: fg,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
            if (onSnooze != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onSnooze,
                style: TextButton.styleFrom(foregroundColor: fg),
                child: Text(snoozeLabel ?? 'Snooze'),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Dismiss for today',
              onPressed: onDismiss,
              color: fg,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
