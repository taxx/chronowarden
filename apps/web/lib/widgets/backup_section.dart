import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../utils/web_download.dart';

/// Full backup & restore of the user's encrypted data.
///
/// Lets users move between instances (e.g. from a hosted deployment to their
/// own self-hosted one) without losing anything: the bundle carries the
/// encryption envelope too, so the same passphrase unlocks it on the new
/// instance.
class BackupSection extends StatefulWidget {
  const BackupSection({super.key});

  @override
  State<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<BackupSection> {
  bool _busy = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final bundle = await BackupService().export();
      final dateStr = DateTime.now().toIso8601String().split('T').first;
      downloadTextFile(
        const JsonEncoder.withIndent('  ').convert(bundle),
        'chronowarden_backup_$dateStr.json',
        'application/json',
      );
      if (!mounted) return;
      _snack(context.t('Backup downloaded'));
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t('Restore backup')),
        content: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ctx.t(
                  'Restoring replaces all data in this account. Use the encryption '
                  'passphrase from the backup.',
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(ctx.t('Paste your backup JSON below.'), style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: '{"format":"chronowarden-backup", ...}',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.t('Restore'))),
        ],
      ),
    );

    if (confirmed != true || controller.text.trim().isEmpty) return;

    setState(() => _busy = true);
    try {
      await BackupService().restore(controller.text.trim());
      // Force the passphrase screen: the restored envelope needs the backup's
      // passphrase, not this account's current one.
      await AuthService().onBackupRestored();
      if (!mounted) return;
      _snack(context.t('Backup restored. Enter the backup’s encryption passphrase.'));
    } catch (e) {
      _snack(e.toString());
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
                  child: Text(context.t('Backup & Restore'), style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.t(
                'Download a complete, encrypted backup you can restore on any '
                'ChronoWarden instance — for example when moving from a hosted '
                'instance to your own.',
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _export,
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: Text(context.t('Download backup')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _restore,
                    icon: const Icon(Icons.upload_outlined, size: 18),
                    label: Text(context.t('Restore backup')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
