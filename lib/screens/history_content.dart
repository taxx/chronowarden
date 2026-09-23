import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/time_log.dart';
import '../services/preferences_service.dart';
import '../utils/format.dart';
import '../widgets/add_day_dialog.dart';
import '../widgets/edit_day_dialog.dart';
import '../widgets/import_dialog.dart';
import '../widgets/log_card.dart';

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
                          child: LogCard(
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
      builder: (_) => ImportDialog(controller: controller),
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

