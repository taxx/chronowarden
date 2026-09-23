import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// CSV import dialog
// ---------------------------------------------------------------------------

class ImportDialog extends StatefulWidget {
  final TextEditingController controller;

  const ImportDialog({
    super.key,
    required this.controller,
  });

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  bool _showFormat = true;

  static const _formatGuide = '''CSV format — one row per day, header required.

Columns (comma-separated):
date,start_time,end_time,expected_minutes,overhead_minutes,lunch_minutes,note

Rules:
  • date         — YYYY-MM-DD
  • start_time   — HH:MM:SS (24-hour)
  • end_time     — HH:MM:SS or leave empty
  • expected_min — integer minutes (e.g. 480 for 8h)
  • overhead_min — integer minutes (e.g. 60)
  • lunch_min    — integer minutes (optional, default 0)
  • note         — text (use quotes if it contains commas)

Example:
date,start_time,end_time,expected_minutes,overhead_minutes,lunch_minutes,note
2026-01-15,08:00:00,16:30:00,480,60,30,Office day
2026-01-16,09:00:00,,480,45,0,
''';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Import Days from CSV'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format guide — collapsible
            InkWell(
              onTap: () => setState(() => _showFormat = !_showFormat),
              child: Row(
                children: [
                  Icon(
                    _showFormat ? Icons.expand_more : Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text('CSV Format Guide', style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  )),
                ],
              ),
            ),
            if (_showFormat)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor, width: 0.5),
                  ),
                  child: Text(
                    _formatGuide,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text('Paste your CSV data below', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            TextField(
              controller: widget.controller,
              maxLines: 10,
              minLines: 6,
              decoration: InputDecoration(
                hintText: 'date,start_time,end_time,expected_minutes,overhead_minutes,lunch_minutes,note',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 13),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final text = widget.controller.text.trim();
            if (text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paste some CSV data first')),
              );
              return;
            }
            Navigator.pop(context, true);
          },
          child: const Text('Import'),
        ),
      ],
    );
  }
}
