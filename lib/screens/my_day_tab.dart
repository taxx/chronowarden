import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/time_log.dart';
import '../models/departure_info.dart';
import '../models/transit_config.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../services/transit_service.dart';
import '../services/user_settings_service.dart';

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

/// The "My Day" content widget — shows today's time tracking.
/// This is a standalone widget (no Scaffold) meant for use inside MainShell.
class MyDayTab extends StatefulWidget {
  const MyDayTab({super.key});

  @override
  State<MyDayTab> createState() => _MyDayTabState();
}

class _MyDayTabState extends State<MyDayTab> with SingleTickerProviderStateMixin {
  late Timer _ticker;
  final _state = AppState();
  final _notifications = NotificationService();
  final _transit = TransitService();
  List<DepartureInfo>? _transitDeps;
  TransitConfig? _transitCfg;
  bool _transitCardShown = false;
  String? _alertMessage;

  @override
  void initState() {
    super.initState();
    _notifications.init(); // fire-and-forget; _enabled stays false until ready
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _checkNotification();
        setState(() {});
      }
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
            if (_alertMessage != null)
              _AlertBanner(message: _alertMessage!, onDismiss: () {
                setState(() => _alertMessage = null);
              }),
            _buildBalanceCard(theme),
            const SizedBox(height: 24),
            _buildTransitCard(theme),
            if (_transitCardShown) const SizedBox(height: 24),
            _buildTodayCard(theme),
          ],
        ),
      ),
    );
  }

  /// Check if we should fire a notification.
  /// Two-phase: wrap-up alert before leave, over-time alert after leave.
  void _checkNotification() {
    final log = _state.todayLog;
    if (log == null || log.endTime != null) return;
    if (!_notifications.enabled) return;

    final dateStr = log.date;
    if (_notifications.wasNotifiedToday(dateStr)) return;

    final now = DateTime.now();
    final leaveTime = log.leaveTime;
    final remaining = leaveTime.difference(now);
    final threshold = _notifications.thresholdMinutes;

    // Phase 1 — wrap-up alert (before leave time)
    if (!remaining.isNegative && remaining.inMinutes <= threshold) {
      final h = remaining.inHours;
      final m = remaining.inMinutes % 60;
      final timeStr = h > 0 ? '${h}h ${m}m' : '$m min';
      final msg = _notifications.alertMessage(
        'ChronoWarden ⏰',
        '⏰ $timeStr left — wrap up and head out!',
      );
      _alertMessage = msg;
      _notifications.markNotified(dateStr);
      return;
    }

    // Phase 2 — over-time alert (past leave time, day still active)
    if (remaining.isNegative && remaining.inMinutes.abs() <= 60) {
      final over = remaining.inMinutes.abs();
      final msg = _notifications.alertMessage(
        'ChronoWarden 🚨',
        '🚨 $over min past your time — finish up and stop the day!',
        isUrgent: true,
      );
      _alertMessage = msg;
      _notifications.markNotified(dateStr);
    }
  }

  Widget _buildTransitCard(ThemeData theme) {
    _transitCfg = _transit.config;

    if (!_transitCfg!.enabled || !_transitCfg!.hasHome) {
      _transitCardShown = false;
      return const SizedBox.shrink();
    }

    // Determine direction: active day → afternoon, otherwise time-based
    final hasActiveDay = _state.todayLog?.endTime == null &&
        _state.todayLog != null;
    final isMorning = hasActiveDay ? false : DateTime.now().hour < 11;

    // Fetch site ID based on direction
    final fetchSiteId = isMorning
        ? _transitCfg!.homeSiteId
        : _transitCfg!.workSiteId;
    final destName = isMorning
        ? _transitCfg!.workSiteName
        : _transitCfg!.homeSiteName;

    // Try cached departures first, fetch if stale
    _transitDeps = _transit.cachedDepartures;

    // We'll show the data even if slightly stale — the ticker refreshes it
    if (_transitDeps == null || _transitDeps!.isEmpty) {
      _transitCardShown = false;
      return const SizedBox.shrink();
    }

    // Filter to relevant departures for this direction
    final now = DateTime.now();
    final relevant = _transitDeps!
        .where((d) => d.isRailRelevant)
        .where((d) => _transitCfg!.hasLineFilter
            ? _transit.filterByLineNumber([d], _transitCfg!.lineFilter).isNotEmpty
            : true)
        .where((d) => d.directionCode == (isMorning ? 1 : 2))
        .where((d) =>
            d.scheduledTime.isAfter(now.subtract(const Duration(minutes: 5))))
        .take(4)
        .toList();

    if (relevant.isEmpty) {
      _transitCardShown = false;
      return const SizedBox.shrink();
    }

    _transitCardShown = true;

    final walkBuffer = isMorning
        ? _transitCfg!.walkHomeMinutes
        : _transitCfg!.walkWorkMinutes;
    final walkFromArrival = isMorning
        ? _transitCfg!.walkWorkMinutes
        : _transitCfg!.walkHomeMinutes;
    final directionLabel = isMorning
        ? '${_transitCfg!.homeSiteName} → ${_transitCfg!.workSiteName}'
        : '${_transitCfg!.workSiteName} → ${_transitCfg!.homeSiteName}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_train,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Transit — $directionLabel',
                      style: theme.textTheme.titleSmall),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...relevant.map((d) => _TransitDepartureRow(
                  departure: d,
                  now: now,
                  walkBuffer: walkBuffer,
                  walkFromArrival: walkFromArrival,
                  theme: theme,
                )),
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
    final leaveTime = log.leaveTime; // includes lunch
    final now = DateTime.now();
    final remaining = leaveTime.difference(now);
    final isPast = remaining.isNegative;
    final lunch = log.lunchMinutes;
    // "net work" leave time = when you've done expected+overhead (no lunch)
    final netWorkLeaveTime = leaveTime.subtract(Duration(minutes: lunch));
    final netRemaining = netWorkLeaveTime.difference(now);
    final isNetPast = netRemaining.isNegative;

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
                  if (lunch > 0 && !isPast)
                    Text(
                      'net: ${isNetPast ? '✓ done' : _formatDuration(netRemaining)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                    ),
                ]),
              ],
            ),
            const SizedBox(height: 24),
            _statRow(theme, 'Expected', _fmtMins(log.expectedMinutes)),
            if (log.morningOverheadMinutes + log.eveningOverheadMinutes > 0)
              _statRow(theme, 'Commute overhead', '${log.morningOverheadMinutes}/${log.eveningOverheadMinutes} min (am/pm)'),
            if (log.morningProductiveCommuteMinutes + log.eveningProductiveCommuteMinutes > 0)
              _statRow(theme, 'Productive commute', '${log.morningProductiveCommuteMinutes}/${log.eveningProductiveCommuteMinutes} min (am/pm)'),
            _statRow(theme, 'Total', _fmtMins(log.expectedMinutes + log.overheadMinutes + log.productiveCommuteMinutes)),

            // Lunch timer section
            _LunchTimerSection(
              lunchMinutes: lunch,
              lunchStartTime: _state.lunchStartTime,
              lunchEndTime: _state.lunchEndTime,
              lunchActive: _state.lunchActive,
              onStartLunch: () => _state.startLunch(),
              onStopLunch: () => _showStopLunchDialog(context),
              onEditLunch: () => _showEditLunchDialog(context, lunch),
              theme: theme,
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showChangePresetDialog(context),
                icon: const Icon(Icons.directions),
                label: const Text('Change commute pattern'),
              ),
            ),
            const SizedBox(height: 8),
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
              color: log.overtimeMinutes >= 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(height: 12),
            Text('Day completed', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            _statRow(theme, 'Started', log.startTime),
            _statRow(theme, 'Ended', log.endTime ?? '—'),
            _statRow(
              theme,
              'Overtime',
              _formatBankMinutes(log.overtimeMinutes),
            ),
            if (log.lunchMinutes != null && log.lunchMinutes > 0)
              _statRow(theme, 'Lunch', '${log.lunchMinutes} min'),
            if (log.note?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Note: ${log.note}', style: theme.textTheme.bodyMedium),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showEditDayDialog(context, log),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, log.id!, log.date),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
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
    if (state.travelPresets.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Add at least one travel preset in Settings.')),
      );
      return;
    }

    final expected = state.expectedMinutesForDate(DateTime.now());

    // Load last-used preferences
    final prefs = PreferencesService();
    final lastPresetId = await prefs.getLastTravelPresetId();
    final defaultFlex = await UserSettingsService().getDefaultFlexMinutes();

    if (!ctx.mounted) return;
    final result = await showDialog<_StartDayResult>(
      context: ctx,
      builder: (_) => _StartDayDialog(
        expectedMinutes: expected,
        travelPresets: state.travelPresets,
        initialPresetId: lastPresetId,
        initialFlexMinutes: defaultFlex,
      ),
    );

    if (!ctx.mounted) return;
    if (result != null) {
      final startStr = '${result.time.hour.toString().padLeft(2, '0')}:${result.time.minute.toString().padLeft(2, '0')}:00';
      await state.startDay(
        startTime: startStr,
        expectedMinutes: result.expectedMinutes,
        lunchMinutes: result.lunchMinutes,
        morningOverheadMinutes: result.morningOverheadMinutes,
        morningProductiveCommuteMinutes: result.morningProductiveCommuteMinutes,
        eveningOverheadMinutes: result.eveningOverheadMinutes,
        eveningProductiveCommuteMinutes: result.eveningProductiveCommuteMinutes,
      );
      // Save last-used selections
      await prefs.setLastTravelPresetId(result.presetId);
    }
  }

  Future<void> _showStopDayDialog(BuildContext ctx) async {
    final log = _state.todayLog;
    final currentLunch = log?.lunchMinutes ?? 0;
    final result = await showDialog<_StopDayResult>(
      context: ctx,
      builder: (_) => _StopDayDialog(initialLunchMinutes: currentLunch),
    );

    if (result != null) {
      final endStr = '${result.time.hour.toString().padLeft(2, '0')}:${result.time.minute.toString().padLeft(2, '0')}:00';
      await _state.stopDay(endStr, lunchMinutes: result.lunchMinutes);
    }
  }

  Future<void> _showEditLunchDialog(BuildContext ctx, int currentLunch) async {
    int lunch = currentLunch;
    await showDialog<void>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adjust lunch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: lunch.toDouble(),
                min: 0,
                max: 120,
                divisions: _sliderDivisions(0, 120),
                label: '$lunch min',
                onChanged: (v) {
                  lunch = v.round();
                  setDialogState(() {});
                },
              ),
              const SizedBox(height: 4),
              Text('$lunch min', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _state.updateLunchMinutes(lunch);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog shown after pressing "Stop Lunch" — shows calculated duration
  /// and allows fine-tuning before saving.
  Future<void> _showStopLunchDialog(BuildContext ctx) async {
    final start = _state.lunchStartTime;
    if (start == null) return;

    final end = DateTime.now();
    final calculatedMinutes = end.difference(start).inMinutes;

    int lunch = calculatedMinutes.clamp(0, 240);
    await showDialog<void>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Lunch stopped'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Started: ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                   style: Theme.of(ctx).textTheme.bodyMedium),
              Text('Ended:   ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                   style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text('Duration: $calculatedMinutes min',
                   style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Adjust if needed:', style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: lunch.toDouble(),
                      min: 0,
                      max: 240,
                      divisions: _sliderDivisions(0, 240),
                      label: '$lunch min',
                      onChanged: (v) {
                        lunch = v.round();
                        setDialogState(() {});
                      },
                    ),
                  ),
                  Text('$lunch min', style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _state.resetLunchTimer();
                Navigator.pop(ctx);
              },
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _state.stopLunch(lunch);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDayDialog(BuildContext ctx, dynamic log) async {
    final state = _state;
    if (state.travelPresets.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Settings not loaded yet. Try again.')),
      );
      return;
    }

    final expected = state.expectedMinutesForDate(DateTime.parse(log.date));

    final result = await showDialog<_EditDayResult>(
      context: ctx,
      builder: (_) => _EditDayDialog(
        log: log,
        expectedMinutes: expected,
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
      // Save last-used selections from edit
      final prefs = PreferencesService();
      await prefs.setLastTravelPresetId(result.presetId);
    }
  }

  Future<void> _confirmDelete(BuildContext ctx, String id, String date) async {
    final confirmed = await showDialog<bool>(
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
    if (confirmed == true) {
      await _state.deleteDay(id);
    }
  }


  Future<void> _showChangePresetDialog(BuildContext ctx) async {
    final state = _state;
    if (state.travelPresets.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('No travel presets available. Add one in Settings.')),
      );
      return;
    }

    dynamic pickedPreset;
    final selected = await showDialog<dynamic>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change commute pattern'),
          content: DropdownButtonFormField(
            items: state.travelPresets.map<DropdownMenuItem>((p) {
              return DropdownMenuItem(
                value: p,
                child: Text('${p.name} — ${p.morningOverheadMinutes}/${p.eveningOverheadMinutes} min walk, ${p.morningProductiveCommuteMinutes}/${p.eveningProductiveCommuteMinutes} min train'),
              );
            }).toList(),
            onChanged: (v) {
              pickedPreset = v;
              setDialogState(() {});
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, pickedPreset),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      await state.updateCommuteValues(
        morningOverheadMinutes: selected.morningOverheadMinutes,
        morningProductiveCommuteMinutes: selected.morningProductiveCommuteMinutes,
        eveningOverheadMinutes: selected.eveningOverheadMinutes,
        eveningProductiveCommuteMinutes: selected.eveningProductiveCommuteMinutes,
      );
    }
  }
}

class _StartDayResult {
  final TimeOfDay time;
  final int expectedMinutes;
  final int lunchMinutes;
  final int flexMinutes;
  final int morningOverheadMinutes;
  final int morningProductiveCommuteMinutes;
  final int eveningOverheadMinutes;
  final int eveningProductiveCommuteMinutes;
  final String? presetId;
  _StartDayResult(
    this.time,
    this.expectedMinutes,
    this.lunchMinutes,
    this.flexMinutes,
    this.morningOverheadMinutes,
    this.morningProductiveCommuteMinutes,
    this.eveningOverheadMinutes,
    this.eveningProductiveCommuteMinutes, {
    this.presetId,
  });
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
  final List<dynamic> travelPresets;
  final String? initialPresetId;
  final int initialFlexMinutes;

  const _StartDayDialog({
    required this.expectedMinutes,
    required this.travelPresets,
    this.initialPresetId,
    this.initialFlexMinutes = 0,
  });

  @override
  State<_StartDayDialog> createState() => _StartDayDialogState();
}

class _StartDayDialogState extends State<_StartDayDialog> {
  late TimeOfDay _startTime;
  late dynamic _selectedPreset;
  int _lunchMinutes = 30;
  int _flexMinutes = 0;

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.now();
    _selectedPreset = _initialPreset();
    _flexMinutes = widget.initialFlexMinutes;
  }

  int get _expected => widget.expectedMinutes;
  int get _morningOverhead => _selectedPreset.morningOverheadMinutes;
  int get _morningProductive => _selectedPreset.morningProductiveCommuteMinutes;
  int get _eveningOverhead => _selectedPreset.eveningOverheadMinutes;
  int get _eveningProductive => _selectedPreset.eveningProductiveCommuteMinutes;

  dynamic _initialPreset() {
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
                '${_fmtMins(widget.expectedMinutes)} per day',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text('Travel preset', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField(
              initialValue: _selectedPreset,
              items: widget.travelPresets.map<DropdownMenuItem>((p) {
                return DropdownMenuItem(value: p, child: Text('${p.name}'));
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedPreset = v); },
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
                    value: _lunchMinutes.toDouble(),
                    min: 0,
                    max: 120,
                    divisions: _sliderDivisions(0, 120),
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
                    divisions: _sliderDivisions(0, 240),
                    label: '$_flexMinutes min',
                    onChanged: (v) => setState(() => _flexMinutes = v.round()),
                  ),
                ),
                Text('$_flexMinutes min', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
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
          onPressed: () => Navigator.pop(context, _StartDayResult(
            _startTime,
            _expected,
            _lunchMinutes,
            _flexMinutes,
            _morningOverhead,
            _morningProductive,
            _eveningOverhead,
            _eveningProductive,
            presetId: _selectedPreset?.id,
          )),
          child: const Text('Start'),
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
          Text('Morning: $_morningOverhead min walk, $_morningProductive min train work', style: theme.textTheme.bodySmall),
          Text('Evening: $_eveningOverhead min walk, $_eveningProductive min train work', style: theme.textTheme.bodySmall),
          Text('Total: $totalCommute min commute', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
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

class _StopDayDialog extends StatefulWidget {
  final int initialLunchMinutes;
  const _StopDayDialog({this.initialLunchMinutes = 0});

  @override
  State<_StopDayDialog> createState() => _StopDayDialogState();
}

class _StopDayDialogState extends State<_StopDayDialog> {
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
                  max: 240,
                  divisions: _sliderDivisions(0, 240),
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
  final int lunchMinutes;
  final int morningOverheadMinutes;
  final int morningProductiveCommuteMinutes;
  final int eveningOverheadMinutes;
  final int eveningProductiveCommuteMinutes;
  final String? note;
  final String? presetId;
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
    this.presetId,
  });
}

// ---------------------------------------------------------------------------
// Edit day dialog
// ---------------------------------------------------------------------------

class _EditDayDialog extends StatefulWidget {
  final dynamic log;
  final int expectedMinutes;
  final List<dynamic> travelPresets;

  const _EditDayDialog({
    required this.log,
    required this.expectedMinutes,
    required this.travelPresets,
  });

  @override
  State<_EditDayDialog> createState() => _EditDayDialogState();
}

class _EditDayDialogState extends State<_EditDayDialog> {
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

  @override
  void initState() {
    super.initState();
    _startTime = _timeOfDayFromStr(widget.log.startTime);
    _endTime = widget.log.endTime != null ? _timeOfDayFromStr(widget.log.endTime!) : null;
    _selectedPreset = _matchPreset(widget.travelPresets, widget.log);
    _lunch = widget.log.lunchMinutes ?? 0;
    _note = widget.log.note ?? '';
  }

  static dynamic _matchPreset(List<dynamic> presets, TimeLog log) {
    for (final p in presets) {
      if (p.morningOverheadMinutes == log.morningOverheadMinutes &&
          p.morningProductiveCommuteMinutes == log.morningProductiveCommuteMinutes &&
          p.eveningOverheadMinutes == log.eveningOverheadMinutes &&
          p.eveningProductiveCommuteMinutes == log.eveningProductiveCommuteMinutes) {
        return p;
      }
    }
    return presets.first;
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
            Text('Expected work', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_fmtMins(widget.expectedMinutes)} per day',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text('Travel preset', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField(
              initialValue: _selectedPreset,
              items: widget.travelPresets.map<DropdownMenuItem>((p) {
                return DropdownMenuItem(value: p, child: Text('${p.name}'));
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedPreset = v); },
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
            presetId: _selectedPreset?.id,
          )),
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Commute breakdown', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('Morning: $_morningOverhead min walk, $_morningProductive min train work', style: theme.textTheme.bodySmall),
          Text('Evening: $_eveningOverhead min walk, $_eveningProductive min train work', style: theme.textTheme.bodySmall),
          Text('Total: $totalCommute min commute', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transit departure row (used in My Day transit card)
// ---------------------------------------------------------------------------

class _TransitDepartureRow extends StatelessWidget {
  final DepartureInfo departure;
  final DateTime now;
  final int walkBuffer;
  final int walkFromArrival;
  final ThemeData theme;

  const _TransitDepartureRow({
    required this.departure,
    required this.now,
    required this.walkBuffer,
    required this.walkFromArrival,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final depTime = departure.scheduledTime;
    final leaveTime = depTime.subtract(Duration(minutes: walkBuffer));
    final isCatchable = leaveTime.isAfter(now) ||
        leaveTime.difference(now).inMinutes.abs() <= 1;
    final waitingMinutes = now.isBefore(leaveTime)
        ? leaveTime.difference(now).inMinutes
        : (now.isBefore(depTime) ? depTime.difference(now).inMinutes : 0);

    final depStr =
        '${depTime.hour.toString().padLeft(2, '0')}:'
        '${depTime.minute.toString().padLeft(2, '0')}';
    final leaveStr =
        '${leaveTime.hour.toString().padLeft(2, '0')}:'
        '${leaveTime.minute.toString().padLeft(2, '0')}';

    final lineBadge = departure.lineNumber ?? '';
    final delayColor = departure.isCancelled
        ? Colors.red
        : (departure.expectedTime == null
            ? Colors.green
            : departure.expectedTime!.difference(departure.scheduledTime).inMinutes > 0
                ? Colors.orange.shade700
                : Colors.green);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCatchable ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: isCatchable
                    ? Colors.green
                    : theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              Text(
                depStr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (lineBadge.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lineBadge,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Text(departure.delayLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                color: delayColor,
                fontSize: 10,
              )),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isCatchable
                ? 'Leave at $leaveStr · $waitingMinutes min wait'
                : 'Missed — needed to leave by $leaveStr',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isCatchable
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lunch timer section — Start/Stop buttons plus elapsed display.
class _LunchTimerSection extends StatelessWidget {
  final int lunchMinutes;
  final DateTime? lunchStartTime;
  final DateTime? lunchEndTime;
  final bool lunchActive;
  final VoidCallback onStartLunch;
  final VoidCallback onStopLunch;
  final VoidCallback onEditLunch;
  final ThemeData theme;

  const _LunchTimerSection({
    required this.lunchMinutes,
    required this.lunchStartTime,
    required this.lunchEndTime,
    required this.lunchActive,
    required this.onStartLunch,
    required this.onStopLunch,
    required this.onEditLunch,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (lunchActive) {
      // Timer is running — show elapsed + Stop button
      final elapsed = DateTime.now().difference(lunchStartTime!);
      final mins = elapsed.inMinutes;
      final secs = elapsed.inSeconds % 60;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.restaurant, size: 16, color: theme.colorScheme.tertiary),
            const SizedBox(width: 4),
            Text('Lunch  ', style: theme.textTheme.bodyMedium),
            Text(
              '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
            const Spacer(),
            _SmallButton(
              onPressed: onStopLunch,
              backgroundColor: theme.colorScheme.tertiary,
              foregroundColor: theme.colorScheme.onTertiary,
              label: 'Stop',
            ),
          ],
        ),
      );
    }

    // Timer not running — show stored lunch minutes + Start button
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.restaurant, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('Lunch: $lunchMinutes min', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (lunchEndTime != null)
            Text(' (timer)', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
          const Spacer(),
          _SmallButton(
            onPressed: onStartLunch,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            label: 'Start',
          ),
          const SizedBox(width: 4),
          _SmallButton(
            onPressed: onEditLunch,
            backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            label: 'Edit',
          ),
        ],
      ),
    );
  }
}

/// A compact button with label, used in _LunchTimerSection.
class _SmallButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final String label;

  const _SmallButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: const TextStyle(fontSize: 12),
        ),
        child: Text(label),
      ),
    );
  }
}

/// A colored banner that appears at the top of MyDayTab when an alert fires.
class _AlertBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _AlertBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrgent = message.contains('🚨');
    return Card(
      color: isUrgent ? theme.colorScheme.errorContainer : theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              isUrgent ? Icons.warning_rounded : Icons.info_outlined,
              color: isUrgent ? theme.colorScheme.onErrorContainer : theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
