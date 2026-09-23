import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/time_log.dart';
import '../services/preferences_service.dart';
import '../utils/format.dart';
import '../widgets/add_day_dialog.dart';
import '../widgets/edit_day_dialog.dart';

/// History content widget — lists past logs with cumulative time-bank balance.
/// No Scaffold wrapper — meant for use inside MainShell.
class HistoryContent extends StatefulWidget {
  const HistoryContent({super.key});

  @override
  State<HistoryContent> createState() => _HistoryContentState();
}

class _HistoryContentState extends State<HistoryContent> {
  final _state = AppState();
  final _prefs = PreferencesService();

  @override
  void initState() {
    super.initState();
    _prefs.init();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_state, _prefs.showWeekends]),
      builder: (context, _) {
        final theme = Theme.of(context);
        final showWeekends = _prefs.showWeekends.value;
        final logs = showWeekends
            ? _state.allLogs
            : _state.allLogs.where((l) {
                final date = DateTime.parse(l.date);
                return date.weekday <= 5; // Monday–Friday
              }).toList();
        final balance = _state.timeBankMinutes;

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => _state.refresh(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                balance >= 0 ? Icons.savings : Icons.warning_amber_rounded,
                                color: balance >= 0 ? theme.colorScheme.primary : Colors.orange,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Time Bank', style: theme.textTheme.titleSmall),
                                    Text(
                                      formatSignedMinutes(balance),
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: balance >= 0 ? null : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (logs.isEmpty)
                    const SliverFillRemaining(child: Center(child: Text('No logs yet')))
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Dismissible(
                          key: Key('log_${logs[i].id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white, size: 28),
                          ),
                          confirmDismiss: (direction) => _confirmDelete(context, logs[i].date),
                          onDismissed: (direction) => _state.deleteDay(logs[i].id!),
                          child: _LogCard(
                            log: logs[i],
                            onEdit: () => _showEditDayDialog(context, logs[i]),
                            onDelete: () => _confirmDelete(context, logs[i].date)
                                .then((ok) => ok == true ? _state.deleteDay(logs[i].id!) : null),
                          ),
                        ),
                        childCount: logs.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    onPressed: () => _showAddDayDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Day'),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    onPressed: () => _showImportDialog(context),
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('Import'),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // -- Delete confirmation -------------------------------------------

  Future<bool?> _confirmDelete(BuildContext ctx, String date) {
    return showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete day'),
        content: Text('Permanently delete the entry for $date? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // -- Add day dialog ------------------------------------------------

  Future<void> _showAddDayDialog(BuildContext ctx) async {
    final state = _state;
    if (state.travelPresets.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Add at least one travel preset in Settings.')),
      );
      return;
    }

    final expected = state.expectedMinutesForDate(DateTime.now().subtract(const Duration(days: 1)));

    final result = await showDialog<AddDayResult>(
      context: ctx,
      builder: (_) => AddDayDialog(
        initialDate: DateTime.now().subtract(const Duration(days: 1)),
        expectedMinutes: expected,
        travelPresets: state.travelPresets,
      ),
    );

    if (result != null) {
      final dateStr = '${result.date.year}-${result.date.month.toString().padLeft(2, '0')}-${result.date.day.toString().padLeft(2, '0')}';
      final startStr = '${result.startTime.hour.toString().padLeft(2, '0')}:${result.startTime.minute.toString().padLeft(2, '0')}:00';
      final endStr = '${result.endTime.hour.toString().padLeft(2, '0')}:${result.endTime.minute.toString().padLeft(2, '0')}:00';

      await state.addDay(
        date: dateStr,
        startTime: startStr,
        endTime: endStr,
        expectedMinutes: result.expectedMinutes,
        lunchMinutes: result.lunchMinutes,
        morningOverheadMinutes: result.morningOverheadMinutes,
        morningProductiveCommuteMinutes: result.morningProductiveCommuteMinutes,
        eveningOverheadMinutes: result.eveningOverheadMinutes,
        eveningProductiveCommuteMinutes: result.eveningProductiveCommuteMinutes,
        note: result.note,
      );
    }
  }

  // -- Import dialog ------------------------------------------------

  Future<void> _showImportDialog(BuildContext ctx) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => _ImportDialog(controller: controller),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      final state = _state;
      final importResult = await state.importDaysFromCsv(controller.text);

      if (!ctx.mounted) return;

      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${importResult.imported.length} day(s)'
            '${importResult.skipped > 0 ? ', ${importResult.skipped} skipped (duplicates)' : ''}'
            '${importResult.hasErrors ? ', ${importResult.errors.length} error(s)' : ''}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      if (importResult.hasErrors) {
        showDialog(
          context: ctx,
          builder: (_) => AlertDialog(
            title: const Text('Import Errors'),
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
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  Future<void> _showEditDayDialog(BuildContext ctx, TimeLog log) async {
    final state = _state;
    if (state.travelPresets.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Settings not loaded yet. Try again.')),
      );
      return;
    }

    final expected = state.expectedMinutesForDate(DateTime.parse(log.date));

    final result = await showDialog<EditDayResult>(
      context: ctx,
      builder: (_) => EditDayDialog(
        log: log,
        expectedMinutes: expected,
        travelPresets: state.travelPresets,
      ),
    );

    if (result != null) {
      if (result.isDelete) {
        await state.deleteDay(log.id!);
      } else {
        final startStr = '${result.startTime.hour.toString().padLeft(2, '0')}:${result.startTime.minute.toString().padLeft(2, '0')}:00';
        final endStr = result.endTime != null
            ? '${result.endTime!.hour.toString().padLeft(2, '0')}:${result.endTime!.minute.toString().padLeft(2, '0')}:00'
            : null;
        final editedLog = log.copyWith(
          startTime: startStr,
          endTime: endStr,
          expectedMinutes: result.expectedMinutes,
          lunchMinutes: result.lunchMinutes,
          morningOverheadMinutes: result.morningOverheadMinutes,
          morningProductiveCommuteMinutes: result.morningProductiveCommuteMinutes,
          eveningOverheadMinutes: result.eveningOverheadMinutes,
          eveningProductiveCommuteMinutes: result.eveningProductiveCommuteMinutes,
          note: result.note,
        );
        await state.editDay(editedLog);
      }
    }
  }
}

class _LogCard extends StatelessWidget {
  final dynamic log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LogCard({required this.log, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = log.endTime != null;
    final overtime = log.overtimeMinutes;
    final hasNote = log.note?.isNotEmpty == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isCompleted
                ? (overtime > 0
                    ? theme.colorScheme.errorContainer
                    : overtime < 0
                        ? Colors.green.shade100
                        : theme.colorScheme.tertiaryContainer)
                : theme.colorScheme.secondaryContainer,
            child: Icon(
              isCompleted ? Icons.check : Icons.pending,
              size: 20,
              color: isCompleted
                  ? (overtime > 0
                      ? theme.colorScheme.onErrorContainer
                      : overtime < 0
                          ? Colors.green.shade700
                          : theme.colorScheme.onTertiaryContainer)
                  : theme.colorScheme.onSecondaryContainer,
            ),
          ),
          title: Row(
            children: [
              Text(log.date),
              if (hasNote)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.note_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${log.startTime}${log.endTime != null ? ' → ${log.endTime}' : ' → …'}  ·  ${formatMins(log.expectedMinutes)} work + ${formatMins(log.overheadMinutes)} overhead${log.lunchMinutes > 0 ? ' · ${formatMins(log.lunchMinutes)} lunch' : ''}',
                style: theme.textTheme.bodySmall,
              ),
              if (hasNote)
                Text('📝 ${log.note}', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                )),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCompleted ? (overtime == 0 ? '✓' : formatMins(overtime)) : 'active',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? (overtime > 0
                          ? theme.colorScheme.error
                          : overtime < 0
                              ? Colors.green.shade700
                              : theme.colorScheme.primary)
                      : theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade700),
              ),
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 18, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit day result

// ---------------------------------------------------------------------------
// Import dialog
// ---------------------------------------------------------------------------

class _ImportDialog extends StatefulWidget {
  final TextEditingController controller;

  const _ImportDialog({required this.controller});

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
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
