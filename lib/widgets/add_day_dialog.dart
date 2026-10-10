import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/travel_preset.dart';
import '../services/preferences_service.dart';
import '../utils/format.dart';
import 'commute_summary.dart';

/// Result returned by [AddDayDialog] when the user confirms.
class AddDayResult {
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int expectedMinutes;
  final int lunchMinutes;
  final int flexMinutes;
  final int morningOverheadMinutes;
  final int morningProductiveCommuteMinutes;
  final int eveningOverheadMinutes;
  final int eveningProductiveCommuteMinutes;
  final String? note;
  final String? presetId;

  AddDayResult({
    required this.date,
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
  });
}

/// Dialog for logging a day that is not today (a past day), shared by the
/// Overview and History tabs.
///
/// The preset shown initially is [initialPresetId] if it matches one of
/// [travelPresets], otherwise the first preset.
class AddDayDialog extends StatefulWidget {
  final DateTime initialDate;
  final int expectedMinutes;
  final List<TravelPreset> travelPresets;
  final String? initialPresetId;

  const AddDayDialog({
    super.key,
    required this.initialDate,
    required this.expectedMinutes,
    required this.travelPresets,
    this.initialPresetId,
  });

  @override
  State<AddDayDialog> createState() => _AddDayDialogState();
}

class _AddDayDialogState extends State<AddDayDialog> {
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TravelPreset _selectedPreset;
  int _lunch = 0;
  String _note = '';

  int get _expected => widget.expectedMinutes;
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
    _selectedPreset = _initialPreset();
  }

  TravelPreset _initialPreset() {
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
      title: Text(context.t('Add a past day')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t('Date'), style: theme.textTheme.titleSmall),
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
                      Text(context.t('Start time'), style: theme.textTheme.titleSmall),
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
                      Text(context.t('End time'), style: theme.textTheme.titleSmall),
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
            Text(context.t('Expected work'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                context.t('{time} per day', {'time': formatMins(widget.expectedMinutes)}),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(context.t('Travel preset'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField(
              initialValue: _selectedPreset,
              items: widget.travelPresets.map<DropdownMenuItem>((p) {
                return DropdownMenuItem(value: p, child: Text(context.t('{name} (+{time})', {'name': p.name, 'time': formatMins(p.defaultOverheadMinutes)})));
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedPreset = v); },
            ),
            const SizedBox(height: 8),
            CommuteSummary(
              morningOverhead: _morningOverhead,
              morningProductive: _morningProductive,
              eveningOverhead: _eveningOverhead,
              eveningProductive: _eveningProductive,
            ),
            const SizedBox(height: 16),
            Text(context.t('Lunch break'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _lunch.toDouble(),
                    min: 0,
                    max: PreferencesService.maxLunchMinutes.toDouble(),
                    divisions: PreferencesService()
                        .sliderDivisions(0, PreferencesService.maxLunchMinutes.toDouble()),
                    label: context.t('{minutes} min', {'minutes': _lunch}),
                    onChanged: (v) => setState(() => _lunch = v.round()),
                  ),
                ),
                Text(context.t('{minutes} min', {'minutes': _lunch}), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(context.t('Note'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            TextField(
              maxLines: 2,
              decoration: InputDecoration(hintText: context.t('Optional note...')),
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
                  Text(context.t('Overtime'), style: theme.textTheme.titleSmall),
                  Text(
                    _overtime == 0
                        ? context.t('✓ exactly on target')
                        : '${_overtime > 0 ? '+' : ''}$_overtime min',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _overtime > 0 ? theme.colorScheme.error : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('Cancel'))),
        FilledButton(
          onPressed: () => Navigator.pop(context, AddDayResult(
            date: _date,
            startTime: _startTime,
            endTime: _endTime,
            expectedMinutes: _expected,
            lunchMinutes: _lunch,
            flexMinutes: 0,
            morningOverheadMinutes: _morningOverhead,
            morningProductiveCommuteMinutes: _morningProductive,
            eveningOverheadMinutes: _eveningOverhead,
            eveningProductiveCommuteMinutes: _eveningProductive,
            note: _note.isEmpty ? null : _note,
            presetId: _selectedPreset.id,
          )),
          child: Text(context.t('Add')),
        ),
      ],
    );
  }
}
