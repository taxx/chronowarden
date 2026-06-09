import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// Bottom-nav shell: Home | History.  Settings is in the app-bar overflow.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _state = AppState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChronoWarden'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _state,
        builder: (context, _) {
          return IndexedStack(
            index: _currentIndex,
            children: [
              _HomeTab(),
              HistoryScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today tab
// ---------------------------------------------------------------------------

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with SingleTickerProviderStateMixin {
  late Timer _ticker;
  final _state = AppState();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () => _state.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(theme),
            const SizedBox(height: 24),
            _buildTodayCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme) {
    final minutes = _state.timeBankMinutes;
    final isPositive = minutes >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isPositive ? Icons.savings : Icons.warning_amber_rounded,
              color: isPositive ? theme.colorScheme.primary : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time Bank', style: theme.textTheme.titleSmall),
                  Text(
                    _formatBankMinutes(minutes),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: isPositive ? null : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCard(ThemeData theme) {
    final todayLog = _state.todayLog;
    if (todayLog == null) return _buildNotStarted(theme);
    if (todayLog.endTime == null) return _buildActive(theme, todayLog);
    return _buildCompleted(theme, todayLog);
  }

  Widget _buildNotStarted(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.logout, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Today has not started', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to start tracking your day.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showStartDayDialog(context),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Day'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActive(ThemeData theme, dynamic log) {
    final elapsed = log.elapsed;
    final leaveTime = log.leaveTime;
    final now = DateTime.now();
    final remaining = leaveTime.difference(now);
    final isPast = remaining.isNegative;

    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              isPast ? "You're free to go!" : 'Day is active',
              style: theme.textTheme.titleLarge?.copyWith(
                color: isPast ? Colors.green : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDuration(elapsed),
              style: theme.textTheme.displayMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Leave time', style: theme.textTheme.titleSmall),
                  Text(
                    '${leaveTime.hour.toString().padLeft(2, '0')}:${leaveTime.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Remaining', style: theme.textTheme.titleSmall),
                  Text(
                    isPast ? '—' : _formatDuration(remaining),
                    style: theme.textTheme.titleMedium,
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 24),
            _statRow(theme, 'Expected', '${log.expectedMinutes} min work'),
            _statRow(theme, 'Overhead', '${log.overheadMinutes} min buffer'),
            _statRow(theme, 'Total', '${log.expectedMinutes + log.overheadMinutes} min'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showStopDayDialog(context),
                icon: const Icon(Icons.stop),
                label: const Text('Stop Day'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleted(ThemeData theme, dynamic log) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              log.overtimeMinutes >= 0 ? Icons.check_circle_rounded : Icons.savings_rounded,
              size: 48,
              color: log.overtimeMinutes >= 0 ? theme.colorScheme.primary : Colors.green,
            ),
            const SizedBox(height: 12),
            Text('Day completed', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            _statRow(theme, 'Started', log.startTime),
            _statRow(theme, 'Ended', log.endTime ?? '—'),
            _statRow(
              theme,
              'Overtime',
              log.overtimeMinutes >= 0
                  ? '+${log.overtimeMinutes} min'
                  : '${log.overtimeMinutes} min',
            ),
            if (log.lunchMinutes != null && log.lunchMinutes > 0)
              _statRow(theme, 'Lunch', '${log.lunchMinutes} min'),
            if (log.note?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Note: ${log.note}', style: theme.textTheme.bodyMedium),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showEditDayDialog(context, log),
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatBankMinutes(int minutes) {
    final sign = minutes >= 0 ? '+' : '';
    final h = minutes.abs() ~/ 60;
    final m = minutes.abs() % 60;
    if (h == 0) return '$sign$m min';
    return '$sign${h}h ${m}m';
  }

  // -- Start day dialog ------------------------------------------------

  Future<void> _showStartDayDialog(BuildContext ctx) async {
    final state = _state;
    if (state.workPeriods.isEmpty || state.travelPresets.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Add at least one work period and one travel preset in Settings.')),
      );
      return;
    }

    final result = await showDialog<_StartDayResult>(
      context: ctx,
      builder: (_) => _StartDayDialog(
        expectedMinutes: state.activePeriod?.expectedMinutes ?? 480,
        overheadMinutes: state.travelPresets.first.defaultOverheadMinutes,
        workPeriods: state.workPeriods,
        travelPresets: state.travelPresets,
      ),
    );

    if (result != null) {
      final startStr = '${result.time.hour.toString().padLeft(2, '0')}:${result.time.minute.toString().padLeft(2, '0')}:00';
      await state.startDay(
        startTime: startStr,
        expectedMinutes: result.expectedMinutes,
        overheadMinutes: result.overheadMinutes,
      );
    }
  }

  Future<void> _showStopDayDialog(BuildContext ctx) async {
    final result = await showDialog<_StopDayResult>(
      context: ctx,
      builder: (_) => _StopDayDialog(),
    );

    if (result != null) {
      final endStr = '${result.time.hour.toString().padLeft(2, '0')}:${result.time.minute.toString().padLeft(2, '0')}:00';
      await _state.stopDay(endStr, lunchMinutes: result.lunchMinutes);
    }
  }

  Future<void> _showEditDayDialog(BuildContext ctx, dynamic log) async {
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
        lunchMinutes: result.lunchMinutes,
        note: result.note,
      );
      await state.editDay(editedLog);
    }
  }
}

class _StartDayResult {
  final TimeOfDay time;
  final int expectedMinutes;
  final int overheadMinutes;
  _StartDayResult(this.time, this.expectedMinutes, this.overheadMinutes);
}

class _StopDayResult {
  final TimeOfDay time;
  final int lunchMinutes;
  _StopDayResult(this.time, this.lunchMinutes);
}

// ---------------------------------------------------------------------------
// Start day dialog
// ---------------------------------------------------------------------------

class _StartDayDialog extends StatefulWidget {
  final int expectedMinutes;
  final int overheadMinutes;
  final List<dynamic> workPeriods;
  final List<dynamic> travelPresets;

  const _StartDayDialog({
    required this.expectedMinutes,
    required this.overheadMinutes,
    required this.workPeriods,
    required this.travelPresets,
  });

  @override
  State<_StartDayDialog> createState() => _StartDayDialogState();
}

class _StartDayDialogState extends State<_StartDayDialog> {
  late TimeOfDay _startTime;
  late int _expected;
  late int _overhead;

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.now();
    _expected = widget.expectedMinutes;
    _overhead = widget.overheadMinutes;
  }

  DateTime get _leaveTime {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);
    return start.add(Duration(minutes: _expected + _overhead));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Start Day'),
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
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('Projected leave time', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                  const SizedBox(height: 4),
                  Text(
                    '${_leaveTime.hour.toString().padLeft(2, '0')}:${_leaveTime.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.headlineLarge?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.bold),
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
          onPressed: () => Navigator.pop(context, _StartDayResult(_startTime, _expected, _overhead)),
          child: const Text('Start'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stop day dialog
// ---------------------------------------------------------------------------

class _StopDayDialog extends StatefulWidget {
  const _StopDayDialog();

  @override
  State<_StopDayDialog> createState() => _StopDayDialogState();
}

class _StopDayDialogState extends State<_StopDayDialog> {
  late TimeOfDay _time;
  int _lunchMinutes = 0;

  @override
  void initState() {
    super.initState();
    _time = TimeOfDay.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Stop Day'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('End time', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () async {
              final picked = await showTimePicker(context: context, initialTime: _time);
              if (picked != null) setState(() => _time = picked);
            },
            icon: const Icon(Icons.access_time),
            label: Text('${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
          ),
          const SizedBox(height: 16),
          Text('Lunch break', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _lunchMinutes.toDouble(),
                  min: 0,
                  max: 240,
                  divisions: 48,
                  label: '$_lunchMinutes min',
                  onChanged: (v) => setState(() => _lunchMinutes = v.round()),
                ),
              ),
              Text('$_lunchMinutes min', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _StopDayResult(_time, _lunchMinutes)),
          child: const Text('Stop'),
        ),
      ],
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
  final int lunchMinutes;
  final String? note;
  _EditDayResult({
    required this.startTime,
    required this.endTime,
    required this.expectedMinutes,
    required this.overheadMinutes,
    required this.lunchMinutes,
    this.note,
  });
}

// ---------------------------------------------------------------------------
// Edit day dialog
// ---------------------------------------------------------------------------

class _EditDayDialog extends StatefulWidget {
  final dynamic log;
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
  late int _lunch;
  late String _note;

  @override
  void initState() {
    super.initState();
    _startTime = _timeOfDayFromStr(widget.log.startTime);
    _endTime = widget.log.endTime != null ? _timeOfDayFromStr(widget.log.endTime!) : null;
    _expected = widget.log.expectedMinutes;
    _overhead = widget.log.overheadMinutes;
    _lunch = widget.log.lunchMinutes ?? 0;
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
            overheadMinutes: _overhead,
            lunchMinutes: _lunch,
            note: _note.isEmpty ? null : _note,
          )),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
