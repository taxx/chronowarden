import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/time_log.dart';
import '../services/preferences_service.dart';

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

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddDayDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Day'),
          ),
          body: RefreshIndicator(
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
    if (state.workPeriods.isEmpty || state.travelPresets.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Add at least one work period and one travel preset in Settings.')),
      );
      return;
    }

    final prefs = PreferencesService();
    final lastPeriodId = await prefs.getLastWorkPeriodId();
    final lastPresetId = await prefs.getLastTravelPresetId();

    final result = await showDialog<_AddDayResult>(
      context: ctx,
      builder: (_) => _AddDayDialog(
        initialDate: DateTime.now().subtract(const Duration(days: 1)),
        expectedMinutes: state.activePeriod?.expectedMinutes ?? 480,
        workPeriods: state.workPeriods,
        travelPresets: state.travelPresets,
        initialPeriodId: lastPeriodId,
        initialPresetId: lastPresetId,
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
      await prefs.setLastWorkPeriodId(result.periodId);
      await prefs.setLastTravelPresetId(result.presetId);
    }
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
            '${log.startTime}${log.endTime != null ? ' → ${log.endTime}' : ' → …'}  ·  ${log.expectedMinutes} min work + ${log.overheadMinutes} min overhead${log.lunchMinutes > 0 ? ' · ${log.lunchMinutes} min lunch' : ''}',
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

class _EditDayResult {
  final TimeOfDay startTime;
  final TimeOfDay? endTime;
  final int expectedMinutes;
  final int lunchMinutes;
  final int morningOverheadMinutes;
  final int morningProductiveCommuteMinutes;
  final int eveningOverheadMinutes;
  final int eveningProductiveCommuteMinutes;
  final String? note;
  _EditDayResult({
    required this.startTime,
    required this.endTime,
    required this.expectedMinutes,
    required this.lunchMinutes,
    required this.morningOverheadMinutes,
    required this.morningProductiveCommuteMinutes,
    required this.eveningOverheadMinutes,
    required this.eveningProductiveCommuteMinutes,
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
  late dynamic _selectedPeriod;
  late dynamic _selectedPreset;
  late int _lunch;
  late String _note;

  int get _expected => _selectedPeriod.expectedMinutes;
  int get _morningOverhead => _selectedPreset.morningOverheadMinutes;
  int get _morningProductive => _selectedPreset.morningProductiveCommuteMinutes;
  int get _eveningOverhead => _selectedPreset.eveningOverheadMinutes;
  int get _eveningProductive => _selectedPreset.eveningProductiveCommuteMinutes;

  @override
  void initState() {
    super.initState();
    _startTime = _timeOfDayFromStr(widget.log.startTime);
    _endTime = widget.log.endTime != null ? _timeOfDayFromStr(widget.log.endTime!) : null;
    _selectedPeriod = _matchPeriod(widget.workPeriods, widget.log.expectedMinutes);
    _selectedPreset = widget.travelPresets.first;
    _lunch = widget.log.lunchMinutes;
    _note = widget.log.note ?? '';
  }

  TimeOfDay _timeOfDayFromStr(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static dynamic _matchPeriod(List<dynamic> periods, int mins) {
    for (final p in periods) {
      if (p.expectedMinutes == mins) return p;
    }
    return periods.first;
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
            DropdownButtonFormField(
              initialValue: _selectedPeriod,
              items: widget.workPeriods.map<DropdownMenuItem>((p) {
                return DropdownMenuItem(value: p, child: Text('${p.name} (${p.expectedMinutes} min)'));
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedPeriod = v); },
            ),
            const SizedBox(height: 16),
            Text('Travel preset', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField(
              initialValue: _selectedPreset,
              items: widget.travelPresets.map<DropdownMenuItem>((p) {
                return DropdownMenuItem(value: p, child: Text('${p.name} (+${p.defaultOverheadMinutes} min)'));
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedPreset = v); },
            ),
            const SizedBox(height: 16),
            Text('Lunch break', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _lunch.toDouble(),
                    min: 0,
                    max: 240,
                    divisions: 48,
                    label: '$_lunch min',
                    onChanged: (v) => setState(() => _lunch = v.round()),
                  ),
                ),
                Text('$_lunch min', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
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
            lunchMinutes: _lunch,
            morningOverheadMinutes: _morningOverhead,
            morningProductiveCommuteMinutes: _morningProductive,
            eveningOverheadMinutes: _eveningOverhead,
            eveningProductiveCommuteMinutes: _eveningProductive,
            note: _note.isEmpty ? null : _note,
          )),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Add day result
// ---------------------------------------------------------------------------

class _AddDayResult {
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int expectedMinutes;
  final int lunchMinutes;
  final int morningOverheadMinutes;
  final int morningProductiveCommuteMinutes;
  final int eveningOverheadMinutes;
  final int eveningProductiveCommuteMinutes;
  final String? note;
  final String? periodId;
  final String? presetId;
  _AddDayResult({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.expectedMinutes,
    required this.lunchMinutes,
    required this.morningOverheadMinutes,
    required this.morningProductiveCommuteMinutes,
    required this.eveningOverheadMinutes,
    required this.eveningProductiveCommuteMinutes,
    this.note,
    this.periodId,
    this.presetId,
  });
}

// ---------------------------------------------------------------------------
// Add day dialog
// ---------------------------------------------------------------------------

class _AddDayDialog extends StatefulWidget {
  final DateTime initialDate;
  final int expectedMinutes;
  final List<dynamic> workPeriods;
  final List<dynamic> travelPresets;
  final String? initialPeriodId;
  final String? initialPresetId;

  const _AddDayDialog({
    required this.initialDate,
    required this.expectedMinutes,
    required this.workPeriods,
    required this.travelPresets,
    this.initialPeriodId,
    this.initialPresetId,
  });

  @override
  State<_AddDayDialog> createState() => _AddDayDialogState();
}

class _AddDayDialogState extends State<_AddDayDialog> {
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late dynamic _selectedPeriod;
  late dynamic _selectedPreset;
  int _lunch = 0;
  String _note = '';

  int get _expected => _selectedPeriod.expectedMinutes;
  int get _morningOverhead => _selectedPreset.morningOverheadMinutes;
  int get _morningProductive => _selectedPreset.morningProductiveCommuteMinutes;
  int get _eveningOverhead => _selectedPreset.eveningOverheadMinutes;
  int get _eveningProductive => _selectedPreset.eveningProductiveCommuteMinutes;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _startTime = const TimeOfDay(hour: 8, minute: 0);
    _endTime = const TimeOfDay(hour: 16, minute: 0);
    _selectedPeriod = _matchPeriod(widget.workPeriods, widget.expectedMinutes);
    _selectedPreset = widget.travelPresets.first;
  }

  static dynamic _matchPeriod(List<dynamic> periods, int mins) {
    for (final p in periods) {
      if (p.expectedMinutes == mins) return p;
    }
    return periods.first;
  }

  dynamic _initialPeriod(int expected) {
    if (widget.initialPeriodId != null) {
      for (final p in widget.workPeriods) {
        if (p.id == widget.initialPeriodId) return p;
      }
    }
    for (final p in widget.workPeriods) {
      if (p.expectedMinutes == expected) return p;
    }
    return widget.workPeriods.first;
  }

  dynamic _initialPreset() {
    if (widget.initialPresetId != null) {
      for (final p in widget.travelPresets) {
        if (p.id == widget.initialPresetId) return p;
      }
    }
    return widget.travelPresets.first;
  }


  int get _overtime {
    final actualMinutes = _endTime.hour * 60 + _endTime.minute -
        (_startTime.hour * 60 + _startTime.minute) -
        _lunch;
    return actualMinutes - _expected - (_morningOverhead + _eveningOverhead);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Add a past day'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start time', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      FilledButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: _startTime);
                          if (picked != null) setState(() => _startTime = picked);
                        },
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('End time', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      FilledButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: _endTime);
                          if (picked != null) setState(() => _endTime = picked);
                        },
                        icon: const Icon(Icons.stop, size: 18),
                        label: Text('${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Work period', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField(
              initialValue: _selectedPeriod,
              items: widget.workPeriods.map<DropdownMenuItem>((p) {
                return DropdownMenuItem(value: p, child: Text('${p.name} (${p.expectedMinutes} min)'));
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedPeriod = v); },
            ),
            const SizedBox(height: 16),
            Text('Travel preset', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField(
              initialValue: _selectedPreset,
              items: widget.travelPresets.map<DropdownMenuItem>((p) {
                return DropdownMenuItem(value: p, child: Text('${p.name} (+${p.defaultOverheadMinutes} min)'));
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedPreset = v); },
            ),
            _commuteSummary(theme),
            const SizedBox(height: 16),
            Text('Lunch break', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _lunch.toDouble(),
                    min: 0,
                    max: 240,
                    divisions: 48,
                    label: '$_lunch min',
                    onChanged: (v) => setState(() => _lunch = v.round()),
                  ),
                ),
                Text('$_lunch min', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Note', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            TextField(
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Optional note...'),
              onChanged: (v) => _note = v,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Overtime', style: theme.textTheme.titleSmall),
                  Text(
                    _overtime == 0 ? '✓ exactly on target' : '${_overtime > 0 ? '+' : ''}$_overtime min',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _overtime >= 0 ? theme.colorScheme.primary : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _AddDayResult(
            date: _date,
            startTime: _startTime,
            endTime: _endTime,
            expectedMinutes: _expected,
            lunchMinutes: _lunch,
            morningOverheadMinutes: _morningOverhead,
            morningProductiveCommuteMinutes: _morningProductive,
            eveningOverheadMinutes: _eveningOverhead,
            eveningProductiveCommuteMinutes: _eveningProductive,
            note: _note.isEmpty ? null : _note,
            periodId: _selectedPeriod?.id,
            presetId: _selectedPreset?.id,
          )),
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _commuteSummary(ThemeData theme) {
    final morningTotal = _morningOverhead + _morningProductive;
    final eveningTotal = _eveningOverhead + _eveningProductive;
    final totalCommute = morningTotal + eveningTotal;
    if (totalCommute == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Commute breakdown', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('Morning:  min walk,  min train work', style: theme.textTheme.bodySmall),
          Text('Evening:  min walk,  min train work', style: theme.textTheme.bodySmall),
          Text('Total:  min commute', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
