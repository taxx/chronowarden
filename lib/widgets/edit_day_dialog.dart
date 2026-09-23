import 'package:flutter/material.dart';

import '../models/time_log.dart';
import '../services/preferences_service.dart';

int _sliderDivisions(double min, double max) {
  final interval = PreferencesService().sliderInterval.value;
  return ((max - min) / interval).round();
}

String _fmtMins(int minutes) {
  final abs = minutes.abs();
  final h = abs ~/ 60;
  final m = abs % 60;
  if (h == 0) return '$m min';
  return '${h}h ${m}m';
}

// ---------------------------------------------------------------------------
// EditDayResult — unified result class
// ---------------------------------------------------------------------------

class EditDayResult {
  final TimeOfDay startTime;
  final TimeOfDay? endTime;
  final int expectedMinutes;
  final int lunchMinutes;
  final int flexMinutes;
  final int morningOverheadMinutes;
  final int morningProductiveCommuteMinutes;
  final int eveningOverheadMinutes;
  final int eveningProductiveCommuteMinutes;
  final String? note;
  final String? presetId;
  final bool isDelete;

  EditDayResult({
    required this.startTime,
    required this.endTime,
    required this.expectedMinutes,
    required this.lunchMinutes,
    this.flexMinutes = 0,
    required this.morningOverheadMinutes,
    required this.morningProductiveCommuteMinutes,
    required this.eveningOverheadMinutes,
    required this.eveningProductiveCommuteMinutes,
    this.note,
    this.presetId,
    this.isDelete = false,
  });
}

// ---------------------------------------------------------------------------
// EditDayDialog — shared dialog used by My Day, Overview, and History
// ---------------------------------------------------------------------------

class EditDayDialog extends StatefulWidget {
  final TimeLog log;
  final int expectedMinutes;
  final List<dynamic> travelPresets;

  const EditDayDialog({
    super.key,
    required this.log,
    required this.expectedMinutes,
    required this.travelPresets,
  });

  @override
  State<EditDayDialog> createState() => _EditDayDialogState();
}

class _EditDayDialogState extends State<EditDayDialog> {
  late TimeOfDay _startTime;
  TimeOfDay? _endTime;
  late dynamic _selectedPreset;
  late int _lunch;
  late String _note;

  int get _expected => widget.expectedMinutes;
  int get _morningOverhead => _selectedPreset.morningOverheadMinutes;
  int get _morningProductive => _selectedPreset.morningProductiveCommuteMinutes;
  int get _eveningOverhead => _selectedPreset.eveningOverheadMinutes;
  int get _eveningProductive => _selectedPreset.eveningProductiveCommuteMinutes;

  /// Minutes between start and end (total elapsed), 0 if end not set.
  int get _actualMinutes {
    if (_endTime == null) return 0;
    final start = _startTime.hour * 60 + _startTime.minute;
    final end = _endTime!.hour * 60 + _endTime!.minute;
    // Handle crossing midnight
    if (end < start) return (end + 24 * 60) - start;
    return end - start;
  }

  /// Net work minutes = elapsed - lunch.
  int get _netWorkMinutes => _actualMinutes - _lunch;

  /// Over/under: actual net work minus expected work including overhead.
  /// Matches TimeLog.calculateOvertimeMinutes() logic.
  int get _overUnderMinutes => _netWorkMinutes - (_expected + _morningOverhead + _eveningOverhead);

  @override
  void initState() {
    super.initState();
    _startTime = _timeOfDayFromStr(widget.log.startTime);
    _endTime = widget.log.endTime != null
        ? _timeOfDayFromStr(widget.log.endTime!)
        : null;
    _selectedPreset = _matchPreset(widget.travelPresets, widget.log);
    _lunch = widget.log.lunchMinutes;
    _note = widget.log.note ?? '';
  }

  TimeOfDay _timeOfDayFromStr(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static dynamic _matchPreset(List<dynamic> presets, TimeLog log) {
    for (final p in presets) {
      if (p.morningOverheadMinutes == log.morningOverheadMinutes &&
          p.morningProductiveCommuteMinutes ==
              log.morningProductiveCommuteMinutes &&
          p.eveningOverheadMinutes == log.eveningOverheadMinutes &&
          p.eveningProductiveCommuteMinutes ==
              log.eveningProductiveCommuteMinutes) {
        return p;
      }
    }
    return presets.first;
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
                final picked = await showTimePicker(
                    context: context, initialTime: _startTime);
                if (picked != null) setState(() => _startTime = picked);
              },
              icon: const Icon(Icons.access_time),
              label: Text(
                '${_startTime.hour.toString().padLeft(2, '0')}:'
                '${_startTime.minute.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 16),
            Text('End time', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _endTime ?? TimeOfDay.now(),
                );
                if (picked != null) setState(() => _endTime = picked);
              },
              icon: const Icon(Icons.access_time),
              label: Text(
                _endTime != null
                    ? '${_endTime!.hour.toString().padLeft(2, '0')}:'
                        '${_endTime!.minute.toString().padLeft(2, '0')}'
                    : '— not set —',
              ),
            ),
            const SizedBox(height: 16),
            Text('Travel preset', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField(
              initialValue: _selectedPreset,
              items: widget.travelPresets.map<DropdownMenuItem>((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(
                    '${p.name} (+${_fmtMins(p.defaultOverheadMinutes)})',
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedPreset = v);
              },
            ),
            const SizedBox(height: 8),
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
                    divisions: _sliderDivisions(0, 240),
                    label: '$_lunch min',
                    onChanged: (v) => setState(() => _lunch = v.round()),
                  ),
                ),
                Text(
                  '$_lunch min',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Time breakdown ──
            Text('Time breakdown', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            _statRow(theme, 'Actual work', _fmtMins(_netWorkMinutes)),
            _statRow(theme, 'Expected work', _fmtMins(_expected)),
            _statRow(
              theme,
              'Over/under',
              _overUnderMinutes > 0
                  ? '+${_fmtMins(_overUnderMinutes)}'
                  : _fmtMins(_overUnderMinutes),
              valueColor: _overUnderMinutes > 0
                  ? theme.colorScheme.error
                  : Colors.green.shade700,
            ),
            if (_endTime != null && _actualMinutes > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '$_actualMinutes min total · $_lunch min lunch · '
                  '$_netWorkMinutes min net',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text('Note', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            TextField(
              controller: TextEditingController(text: _note),
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Optional note...',
              ),
              onChanged: (v) => _note = v,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.log.id != null)
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              EditDayResult(
                startTime: _startTime,
                endTime: _endTime,
                expectedMinutes: _expected,
                lunchMinutes: _lunch,
                morningOverheadMinutes: _morningOverhead,
                morningProductiveCommuteMinutes: _morningProductive,
                eveningOverheadMinutes: _eveningOverhead,
                eveningProductiveCommuteMinutes: _eveningProductive,
                note: _note.isEmpty ? null : _note,
                isDelete: true,
              ),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            EditDayResult(
              startTime: _startTime,
              endTime: _endTime,
              expectedMinutes: _expected,
              lunchMinutes: _lunch,
              morningOverheadMinutes: _morningOverhead,
              morningProductiveCommuteMinutes: _morningProductive,
              eveningOverheadMinutes: _eveningOverhead,
              eveningProductiveCommuteMinutes: _eveningProductive,
              note: _note.isEmpty ? null : _note,
            ),
          ),
          child: const Text('Save'),
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
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commute breakdown',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Morning: $_morningOverhead min walk, '
            '$_morningProductive min train work',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Evening: $_eveningOverhead min walk, '
            '$_eveningProductive min train work',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Total: $totalCommute min commute',
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _statRow(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
