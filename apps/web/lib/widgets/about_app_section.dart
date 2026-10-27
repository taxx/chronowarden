import 'package:flutter/material.dart';

import '../app_info.dart';
import '../l10n/app_strings.dart';
import '../screens/about_screen.dart';
import '../screens/changelog_screen.dart';
import '../services/update_service.dart';
import 'external_link.dart';

/// Settings card linking to the open-source project: source code, issue
/// tracker, license, and the full About screen.
class AboutAppSection extends StatelessWidget {
  const AboutAppSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.t('About & Open Source'),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.t(
                '{app} is free software under the {license}. '
                'Self-host it, read the code, or report an issue on GitHub.',
                {'app': AppInfo.name, 'license': AppInfo.licenseName},
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
                icon: const Icon(Icons.info_outline, size: 18),
                label: Text(context.t('About ChronoWarden')),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangelogScreen()),
                ),
                icon: const Icon(Icons.new_releases_outlined, size: 18),
                label: Text(context.t("What's New")),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _checkForUpdates(context),
                icon: const Icon(Icons.system_update_alt_rounded, size: 18),
                label: Text(context.t('Check for updates')),
              ),
            ),
            const SizedBox(height: 8),
            ExternalLinkButton(
              label: context.t('View source on GitHub'),
              url: AppInfo.repoUrl,
              icon: Icons.code,
            ),
            const SizedBox(height: 8),
            ExternalLinkButton(
              label: context.t('Report an issue'),
              url: AppInfo.issuesUrl,
              icon: Icons.bug_report_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    final service = UpdateService();
    await service.check();
    if (!context.mounted) return;

    final server = service.serverBuild;
    final message = service.updateAvailable
        ? context.t('A new version is available — use the banner to reload.')
        : (server != null && server.isKnown
            ? context.t('You are on the latest version ({commit}).',
                {'commit': server.commit})
            : context.t('Update check unavailable.'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
