import 'package:flutter/material.dart';

import '../app_info.dart';
import '../screens/about_screen.dart';
import '../screens/changelog_screen.dart';
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
                    'About & Open Source',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${AppInfo.name} is free software under the ${AppInfo.licenseName}. '
              'Self-host it, read the code, or report an issue on GitHub.',
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
                label: const Text('About ChronoWarden'),
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
                label: const Text("What's New"),
              ),
            ),
            const SizedBox(height: 8),
            ExternalLinkButton(
              label: 'View source on GitHub',
              url: AppInfo.repoUrl,
              icon: Icons.code,
            ),
            const SizedBox(height: 8),
            ExternalLinkButton(
              label: 'Report an issue',
              url: AppInfo.issuesUrl,
              icon: Icons.bug_report_outlined,
            ),
          ],
        ),
      ),
    );
  }
}
