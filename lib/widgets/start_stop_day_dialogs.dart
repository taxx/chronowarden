import 'package:flutter/material.dart';

import '../models/travel_preset.dart';
import '../services/preferences_service.dart';
import '../utils/format.dart';
import 'commute_summary.dart';

// ---------------------------------------------------------------------------
// Start day / Stop day dialogs
// ---------------------------------------------------------------------------

class StartDayResult {
  final TimeOfDay time;
  final int expectedMinutes;
  final int lunchMinutes;
  final int flexMinutes;
  final int morningOverheadMinutes;
  final int morningProductiveCommuteMinutes;
  final int eveningOverheadMinutes;
  final int eveningProductiveCommuteMinutes;
  final String? presetId;
  final String? note;
  StartDayResult(
    this.time,
    this.expectedMinutes,
    this.lunchMinutes,
    this.flexMinutes,
    this.morningOverheadMinutes,
    this.morningProductiveCommuteMinutes,
    this.eveningOverheadMinutes,
    this.eveningProductiveCommuteMinutes, {
    this.presetId,
    this.note,
  });
}

class StopDayResult {
  final TimeOfDay time;
  final int lunchMinutes;
  StopDayResult(this.time, this.lunchMinutes);
}

// ---------------------------------------------------------------------------
// Start day dialog
// ---------------------------------------------------------------------------

class StartDayDialog extends StatefulWidget {
  final int expectedMinutes;
  final List<TravelPreset> travelPresets;
  final String? initialPresetId;
  final int initialFlexMinutes;
  final String? initialNote;

  const StartDayDialog({
    super.key,
    required this.expectedMinutes,
    required this.travelPresets,
    this.initialPresetId,
    this.initialFlexMinutes = 0,
    this.initialNote,
  });

  @override
  State<StartDayDialog> createState() => _StartDayDialogState();
}

class _StartDayDialogState extends State<StartDayDialog> {
  late TimeOfDay _startTime;
  late TravelPreset _selectedPreset;
  late TextEditingController _noteController;
  int _lunchMinutes = 30;
  int _flexMinutes = 0;

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.now();
    _selectedPreset = _initialPreset();
    _flexMinutes = widget.initialFlexMinutes;
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int get _expected => widget.expectedMinutes;
  int get _morningOverhead => _selectedPreset.morningOverheadMinutes;
  int get _morningProductive => _selectedPreset.morningProductiveCommuteMinutes;
  int get _eveningOverhead => _selectedPreset.eveningOverheadMinutes;
  int get _eveningProductive => _selectedPreset.eveningProductiveCommuteMinutes;

  TravelPreset _initialPreset() {
    // Try last-used preset first, then first
    if (widget.initialPresetId != null) {
      for (final p in widget.travelPresets) {
        if (p.id == widget.initialPresetId) return p;
      }
    }
    return widget.travelPresets.first;
  }

  /// When you're physically free to leave the office.
  /// Formula: start + expected + lunch + morningOverhead - eveningProductiveCommute
  /// Morning overhead is added because it happens after startTime
  /// (walking to office). Evening productive commute is subtracted
  /// because that work happens after leaving the office.
  DateTime get _leaveTime {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);
    return start.add(Duration(
      minutes: _expected +
          _lunchMinutes +
          _morningOverhead -
          _eveningProductive -
          _flexMinutes,
    ));
  }

  /// When you've done enough pure work (not counting lunch or overhead).
  DateTime get _netWorkTime {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);
    return start.add(Duration(
      minutes: _expected + _morningOverhead - _eveningProductive,
    ));
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
            Text('Expected work', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${formatMins(widget.expectedMinutes)} per day',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text('Travel preset', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField(
              initialValue: _selectedPreset,
              items: widget.travelPresets.map<DropdownMenuItem>((p) {
                return DropdownMenuItem(value: p, child: Text(p.name));
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
            Text('Lunch break', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _lunchMinutes.toDouble(),
                    min: 0,
                    max: PreferencesService.maxLunchMinutes.toDouble(),
                    divisions: PreferencesService()
                        .sliderDivisions(0, PreferencesService.maxLunchMinutes.toDouble()),
                    label: '$_lunchMinutes min',
                    onChanged: (v) => setState(() => _lunchMinutes = v.round()),
                  ),
                ),
                Text('$_lunchMinutes min', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Flex time (banked overtime)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _flexMinutes.toDouble(),
                    min: 0,
                    max: 240,
                    divisions: PreferencesService().sliderDivisions(0, 240),
                    label: '$_flexMinutes min',
                    onChanged: (v) => setState(() => _flexMinutes = v.round()),
                  ),
                ),
                Text('$_flexMinutes min', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Note', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            TextField(
              controller: _noteController,
              maxLines: 2,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Optional note...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
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
                  if (_lunchMinutes > 0 || _flexMinutes > 0) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'net work done at ${_netWorkTime.hour.toString().padLeft(2, '0')}:${_netWorkTime.minute.toString().padLeft(2, '0')}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (_lunchMinutes > 0)
                      Text('  minus $_lunchMinutes min lunch', style: theme.textTheme.bodySmall),
                    if (_flexMinutes > 0)
                      Text('  minus $_flexMinutes min flex', style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Expected end: ${_expectedEnd.hour.toString().padLeft(2, '0')}:${_expectedEnd.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodySmall,
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
          onPressed: () => Navigator.pop(context, StartDayResult(
            _startTime,
            _expected,
            _lunchMinutes,
            _flexMinutes,
            _morningOverhead,
            _morningProductive,
            _eveningOverhead,
            _eveningProductive,
            presetId: _selectedPreset.id,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          )),
          child: const Text('Start'),
        ),
      ],
    );
  }

  DateTime get _expectedEnd {
    final lt = _leaveTime;
    return lt.add(Duration(
      minutes: _eveningOverhead + _eveningProductive,
    ));
  }
}

// ---------------------------------------------------------------------------
// Stop day dialog
// ---------------------------------------------------------------------------

class StopDayDialog extends StatefulWidget {
  final int initialLunchMinutes;
  const StopDayDialog({super.key, this.initialLunchMinutes = 0});

  @override
  State<StopDayDialog> createState() => _StopDayDialogState();
}

class _StopDayDialogState extends State<StopDayDialog> {
  late TimeOfDay _time;
  late int _lunchMinutes;
  @override
  void initState() {
    super.initState();
    _time = TimeOfDay.now();
    _lunchMinutes = widget.initialLunchMinutes;
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
                  max: PreferencesService.maxLunchMinutes.toDouble(),
                  divisions: PreferencesService()
                      .sliderDivisions(0, PreferencesService.maxLunchMinutes.toDouble()),
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
          onPressed: () => Navigator.pop(context, StopDayResult(_time, _lunchMinutes)),
          child: const Text('Stop'),
        ),
      ],
    );
  }
}



// ---------------------------------------------------------------------------
// Transit departure row (used in My Day transit card)
// ---------------------------------------------------------------------------

