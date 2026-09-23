import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Theme-aware panel that displays a 24-word recovery phrase.
///
/// Both the panel background and its foreground colour come from the active
/// [ColorScheme] (`tertiaryContainer` / `onTertiaryContainer`), so the phrase
/// and surrounding copy stay legible in light **and** dark mode. The previous
/// implementation hardcoded `Colors.amber.shade50` while taking the text colour
/// from the theme, which rendered near-white text on a pale background in dark
/// mode.
class RecoveryPhraseCard extends StatelessWidget {
  final String phrase;

  /// Header title. Pass `null` to render just the phrase box and copy button
  /// (e.g. inside a dialog that already has its own title).
  final String? title;
  final String? description;
  final IconData? icon;

  const RecoveryPhraseCard({
    super.key,
    required this.phrase,
    this.title = 'Recovery Phrase',
    this.description,
    this.icon = Icons.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.tertiary),
      ),
      child: Column(
        children: [
          if (title != null) ...[
            if (icon != null) ...[
              Icon(icon, color: scheme.onTertiaryContainer, size: 32),
              const SizedBox(height: 8),
            ],
            Text(
              title!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onTertiaryContainer,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onTertiaryContainer,
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: SelectableText(
              phrase,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.5,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phrase));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recovery phrase copied')),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}

/// Theme-aware "data loss" warning panel.
///
/// Uses the [ColorScheme] error roles so the warning is legible in both
/// light and dark mode instead of hardcoded `Colors.red.shade50`.
class RecoveryWarningCard extends StatelessWidget {
  final String message;

  const RecoveryWarningCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning, color: scheme.onErrorContainer, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
