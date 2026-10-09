import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_info.dart';
import '../widgets/external_link.dart';
import 'about_encryption_screen.dart';
import 'changelog_screen.dart';

/// Everything a user might want to know about the project: what it is,
/// that it is open source, where to report issues, and how to self-host.
///
/// Reachable from Settings → About & Open Source, and linked from the
/// login screen footer.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About ChronoWarden')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Identity -------------------------------------------
                  Center(
                    child: Column(
                      children: [
                        SvgPicture.asset('chronowarden.svg', height: 72),
                        const SizedBox(height: 12),
                        Text(
                          AppInfo.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppInfo.tagline,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version ${AppInfo.version}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- What's new ----------------------------------------
                  _sectionTitle(theme, "What's New"),
                  _paragraph(
                    theme,
                    'Every change to ${AppInfo.name} is tracked in the git '
                    'history — the changelog below is generated straight from '
                    'those commits.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangelogScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.new_releases_outlined, size: 18),
                      label: const Text('View changelog'),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Open source ----------------------------------------
                  _sectionTitle(theme, 'Open Source'),
                  _paragraph(
                    theme,
                    'ChronoWarden is free and open-source software, released '
                    'under the ${AppInfo.licenseName}. You are free to use, '
                    'study, modify, and redistribute it — including for your '
                    'own self-hosted instance.',
                  ),
                  const SizedBox(height: 12),
                  ExternalLinkButton(
                    label: 'View source on GitHub',
                    url: AppInfo.repoUrl,
                    icon: Icons.code,
                  ),
                  const SizedBox(height: 8),
                  ExternalLinkButton(
                    label: 'Read the ${AppInfo.licenseName}',
                    url: AppInfo.licenseUrl,
                    icon: Icons.gavel_outlined,
                  ),
                  const SizedBox(height: 8),
                  ExternalLinkButton(
                    label: 'Report an issue or request a feature',
                    url: AppInfo.issuesUrl,
                    icon: Icons.bug_report_outlined,
                  ),
                  const SizedBox(height: 32),

                  // --- Self-hosting --------------------------------------
                  _sectionTitle(theme, 'Host It Yourself'),
                  _paragraph(
                    theme,
                    'ChronoWarden is designed to be self-hosted. The whole '
                    'stack — Flutter web app, nginx container, Supabase '
                    'schema, and the SL transit proxy — lives in the '
                    'repository. Bring your own Supabase project and secrets, '
                    'then build with Docker Compose.',
                  ),
                  const SizedBox(height: 12),
                  ExternalLinkButton(
                    label: 'Self-hosting guide (README)',
                    url: AppInfo.readmeUrl,
                    icon: Icons.menu_book_outlined,
                  ),
                  const SizedBox(height: 32),

                  // --- Hosted instance -----------------------------------
                  _sectionTitle(theme, 'The Hosted Instance'),
                  _paragraph(
                    theme,
                    '${AppInfo.name} also runs as a convenience instance at '
                    '${AppInfo.hostedUrl}. It is maintained on a best-effort '
                    'basis: there are no guarantees of availability, '
                    'uptime, or data retention.',
                  ),
                  _callout(
                    theme,
                    Icons.warning_amber_rounded,
                    'Your data is encrypted with your own passphrase, so the '
                    'host cannot read it. But if you lose your passphrase and '
                    'recovery phrase, nobody can restore your data — and a '
                    'self-hosted instance (or your own backups) is the safest '
                    'long-term home for it.',
                  ),
                  const SizedBox(height: 32),

                  // --- Privacy -------------------------------------------
                  _sectionTitle(theme, 'Privacy & Encryption'),
                  _paragraph(
                    theme,
                    'ChronoWarden uses zero-knowledge envelope encryption. '
                    'Your time logs, presets, and settings are encrypted on '
                    'your device before they reach any server.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutEncryptionScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.shield_outlined, size: 18),
                      label: const Text('How encryption works'),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Center(
                    child: Text(
                      'Made with Flutter & Supabase ❤️',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _paragraph(ThemeData theme, String text) {
    return Text(text, style: theme.textTheme.bodyMedium);
  }

  Widget _callout(ThemeData theme, IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
