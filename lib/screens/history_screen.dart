import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/time_log.dart';

/// Lists all past logs and shows the cumulative time-bank balance.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _state = AppState();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final theme = Theme.of(context);
        final logs = _state.allLogs;
        final balance = _state.timeBankMinutes;

        return RefreshIndicator(
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
                                Text('Time Bank Balance', style: theme.textTheme.titleSmall),
                                Text(
                                  _formatBalance(balance),
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
                    (ctx, i) => _LogCard(
                      log: logs[i],
                      onEdit: () => _showEditDayDialog(context, logs[i]),
                    ),
                    childCount: logs.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatBalance(int minutes) {
    final sign = minutes >= 0 ? '+' : '';
    final h = minutes.abs() ~/ 60;
    final m = minutes.abs() % 60;
    if (h == 0) return '$sign$m min';
    return '$sign${h}h ${m}m';
  }

  Future<void> _showEditDayDialog(BuildContext ctx, TimeLog log) async {
    final state = _state;
    if (state.workPeriods.isEmpty || state.travelPresets.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Settings not loaded yet. Try again.')),
      );
      return;
    }

    final result = await showDialog<_EditDayResult>(
      context: ctx,
      builder: (_) => _EditDayDialog(
        log: log,
        workPeriods: state.workPeriods,
        travelPresets: state.travelPresets,
      ),
    );

    if (result != null) {
      final startStr = '${result.startTime.hour.toString().padLeft(2, '0')}:${result.startTime.minute.toString().padLeft(2, '0')}:00';
      final endStr = result.endTime != null
          ? '${result.endTime!.hour.toString().padLeft(2, '0')}:${result.endTime!.minute.toString().padLeft(2, '0')}:00'
          : null;
      final editedLog = log.copyWith(
        startTime: startStr,
        endTime: endStr,
        expectedMinutes: result.expectedMinutes,
        overheadMinutes: result.overheadMinutes,
        note: result.note,
      );
      await state.editDay(editedLog);
    }
  }
}

class _LogCard extends StatelessWidget {
  final dynamic log;
  final VoidCallback onEdit;

  const _LogCard({required this.log, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = log.endTime != null;
    final overtime = log.overtimeMinutes;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isCompleted
                ? (overtime >= 0 ? theme.colorScheme.primaryContainer : Colors.green.shade100)
                : theme.colorScheme.secondaryContainer,
            child: Icon(
              isCompleted ? Icons.check : Icons.pending,
              size: 20,
              color: isCompleted
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSecondaryContainer,
            ),
          ),
          title: Text(log.date),
          subtitle: Text(
            '${log.startTime}${log.endTime != null ? ' → ${log.endTime}' : ' → …'}  ·  ${log.expectedMinutes} min work + ${log.overheadMinutes} min overhead',
            style: theme.textTheme.bodySmall,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCompleted ? (overtime == 0 ? '✓' : '$overtime min') : 'active',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? (overtime >= 0 ? theme.colorScheme.primary : Colors.green)
                      : theme.colorScheme.secondary,
                ),
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

class _EditDayResult {
  final TimeOfDay startTime;
  final TimeOfDay? endTime;
  final int expectedMinutes;
  final int overheadMinutes;
  final String? note;
  _EditDayResult({
    required this.startTime,
    required this.endTime,
    required this.expectedMinutes,
    required this.overheadMinutes,
    this.note,
  });
}

// ---------------------------------------------------------------------------
// Edit day dialog
// ---------------------------------------------------------------------------

class _EditDayDialog extends StatefulWidget {
  final TimeLog log;
  final List<dynamic> workPeriods;
  final List<dynamic> travelPresets;

  const _EditDayDialog({
    required this.log,
    required this.workPeriods,
    required this.travelPresets,
  });

  @override
  State<_EditDayDialog> createState() => _EditDayDialogState();
}

class _EditDayDialogState extends State<_EditDayDialog> {
  late TimeOfDay _startTime;
  TimeOfDay? _endTime;
  late int _expected;
  late int _overhead;
  late String _note;

  @override
  void initState() {
    super.initState();
    _startTime = _timeOfDayFromStr(widget.log.startTime);
    _endTime = widget.log.endTime != null ? _timeOfDayFromStr(widget.log.endTime!) : null;
    _expected = widget.log.expectedMinutes;
    _overhead = widget.log.overheadMinutes;
    _note = widget.log.note ?? '';
  }

  TimeOfDay _timeOfDayFromStr(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Edit Day'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Start time', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(context: context, initialTime: _startTime);
                if (picked != null) setState(() => _startTime = picked);
              },
              icon: const Icon(Icons.access_time),
              label: Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}'),
            ),
            const SizedBox(height: 16),
            Text('End time', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(context: context, initialTime: _endTime ?? TimeOfDay.now());
                if (picked != null) setState(() => _endTime = picked);
              },
              icon: const Icon(Icons.access_time),
              label: Text(_endTime != null
                  ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                  : '— not set —'),
            ),
            const SizedBox(height: 16),
            Text('Work period', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              initialValue: _expected,
              items: widget.workPeriods.map<DropdownMenuItem<int>>((p) {
                return DropdownMenuItem(
                  value: (p.expectedMinutes) as int,
                  child: Text('${p.name} (${p.expectedMinutes} min)'),
                );
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _expected = v); },
            ),
            const SizedBox(height: 16),
            Text('Travel preset', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              initialValue: _overhead,
              items: widget.travelPresets.map<DropdownMenuItem<int>>((p) {
                return DropdownMenuItem(
                  value: (p.defaultOverheadMinutes) as int,
                  child: Text('${p.name} (+${p.defaultOverheadMinutes} min)'),
                );
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _overhead = v); },
            ),
            const SizedBox(height: 16),
            Text('Note', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            TextField(
              controller: TextEditingController(text: _note),
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Optional note...'),
              onChanged: (v) => _note = v,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _EditDayResult(
            startTime: _startTime,
            endTime: _endTime,
            expectedMinutes: _expected,
            overheadMinutes: _overhead,
            note: _note.isEmpty ? null : _note,
          )),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
