import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_strings.dart';
import '../utils/csv_export.dart';

// ---------------------------------------------------------------------------
// Export section
// ---------------------------------------------------------------------------

class ExportSection extends StatelessWidget {
  const ExportSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(context.t('Export / Import'), style: theme.textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.t('Download all your time logs as CSV or import from a CSV file.'),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final csv = timeLogsToCsv(state.allLogs);
                      final dateStr = DateTime.now().toIso8601String().split('T').first;
                      downloadCsv(csv, 'chronowarden_export_$dateStr.csv');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.t('Exported {count} logs', {'count': state.allLogs.length})),
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: Text(context.t('Export CSV')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showImportDialog(context, state),
                    icon: const Icon(Icons.file_upload_outlined, size: 18),
                    label: Text(context.t('Import CSV')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImportDialog(BuildContext ctx, AppState state) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(ctx.t('Import CSV')),
        content: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ctx.t('Paste your CSV data below.'), style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: 'date,start_time,end_time,expected_minutes,overhead_minutes,lunch_minutes,productive_commute_minutes,note\n...',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.t('Import'))),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      final importResult = await state.importDaysFromCsv(controller.text);

      if (!ctx.mounted) return;

      final skipped = importResult.skipped > 0
          ? ctx.t(', {count} skipped (duplicates)', {'count': importResult.skipped})
          : '';
      final errors = importResult.hasErrors
          ? ctx.t(', {count} error(s)', {'count': importResult.errors.length})
          : '';
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            ctx.t('Imported {count} day(s)', {'count': importResult.imported.length}) +
                skipped +
                errors,
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      if (importResult.hasErrors) {
        showDialog(
          context: ctx,
          builder: (_) => AlertDialog(
            title: Text(ctx.t('Import Errors')),
            content: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: importResult.errors.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(e, style: const TextStyle(fontSize: 13)),
                )).toList(),
              ),
            ),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.t('OK'))),
            ],
          ),
        );
      }
    }
  }
}
