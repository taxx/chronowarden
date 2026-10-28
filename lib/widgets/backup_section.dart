import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/backup_service.dart';
import '../utils/web_download.dart';

/// Download a full, portable backup of all the user's encrypted data.
///
/// Restoring it happens on the target instance (Settings → Backup & Restore),
/// which is how users move from this hosted instance to their own self-hosted
/// ChronoWarden.
class BackupSection extends StatefulWidget {
  const BackupSection({super.key});

  @override
  State<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<BackupSection> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final bundle = await BackupService().exportBundle();
      final dateStr = DateTime.now().toIso8601String().split('T').first;
      downloadTextFile(
        const JsonEncoder.withIndent('  ').convert(bundle),
        'chronowarden_backup_$dateStr.json',
        'application/json',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('Backup downloaded')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
                Icon(Icons.cloud_sync_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(context.t('Full backup'), style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.t(
                'Download a complete, encrypted backup of all your data (time logs, '
                'presets and settings). Keep it safe — it is the key to moving your '
                'data to another ChronoWarden instance.',
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _export,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: Text(context.t('Download backup')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
