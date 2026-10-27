import 'package:flutter/material.dart';

import '../utils/external_link.dart';

/// A small underlined text link that opens [url] in the browser.
///
/// Intended for inline footers (e.g. the login screen) where a full button
/// would be too heavy.
class ExternalLinkText extends StatelessWidget {
  const ExternalLinkText({
    super.key,
    required this.label,
    required this.url,
    this.icon,
  });

  final String label;
  final String url;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => openExternalLink(context, url),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An outlined button that opens [url] in the browser.
///
/// Used for the primary actions on the About screen.
class ExternalLinkButton extends StatelessWidget {
  const ExternalLinkButton({
    super.key,
    required this.label,
    required this.url,
    required this.icon,
  });

  final String label;
  final String url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => openExternalLink(context, url),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}
