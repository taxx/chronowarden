import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/locale_service.dart';

/// Settings card for choosing the app language.
///
/// The selection is cached locally and mirrored to the encrypted user
/// settings, so it follows the user across devices.
class LanguageSetting extends StatelessWidget {
  const LanguageSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = LocaleService();

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.translate, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.t('Language'),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.t('Choose the language used across the app.'),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: service.languageCode,
                isExpanded: true,
                items: const [
                  // Language names stay in their own language.
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'sv', child: Text('Svenska')),
                ],
                onChanged: (code) {
                  if (code != null) service.setLanguage(code);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
