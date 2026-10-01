import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/journey_info.dart';
import '../models/transit_config.dart';
import '../services/notification_service.dart';
import '../services/pinned_journey_store.dart';
import '../services/preferences_service.dart';
import '../services/transit_service.dart';
import '../services/user_settings_service.dart';
import '../utils/format.dart';
import '../widgets/alert_banner.dart';
import '../widgets/edit_day_dialog.dart';
import '../widgets/lunch_timer_section.dart';
import '../widgets/journey_tile.dart';
import '../widgets/start_stop_day_dialogs.dart';
import '../widgets/stat_row.dart';

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
  List<JourneyInfo>? _transitJourneys;
  TransitConfig? _transitCfg;
  // ignore: unused_field
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
              AlertBanner(message: _alertMessage!, onDismiss: () {
                setState(() => _alertMessage = null);
              }),
            _buildBalanceCard(theme),
            const SizedBox(height: 24),
            _buildTodayCard(theme),
            const SizedBox(height: 24),
            _buildTransitCard(theme),
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

    if (!_transitCfg!.enabled || !_transitCfg!.hasWork || !_transitCfg!.hasHome) {
      _transitCardShown = false;
      return const SizedBox.shrink();
    }

    // Determine direction and visibility based on day state.
    // - Day ended (endTime != null): hide transit, no longer relevant
    // - Day active (endTime == null): show afternoon commute IF preset uses transit
    // - No day active: show morning commute planning
    final todayLog = _state.todayLog;
    final dayEnded = todayLog?.endTime != null;
    final hasActiveDay = todayLog != null && todayLog.endTime == null;

    if (dayEnded) {
      _transitCardShown = false;
      return const SizedBox.shrink();
    }

    // Direction: active day → always afternoon (commute home)
    // No active day → morning (commute to work)
    final isMorning = hasActiveDay ? false : DateTime.now().hour < 11;

    // Get origin/dest IDs based on direction
    final originId = _transitCfg!.originStopId(isMorning);
    final destId = _transitCfg!.destStopId(isMorning);

    final walkOffset = _transitCfg!.walkMinutes(isMorning);

    // Fetch journey data if cache is stale, missing, or for wrong route
    _transitJourneys = _transit.cachedJourneys;
    if (_transitJourneys == null) {
      _transit.fetchJourneys(
        originId: originId,
        destId: destId,
        walkOffsetMinutes: walkOffset,
      ).then((_) {
        if (mounted) setState(() {});
      });
      _transitCardShown = false;
      return const SizedBox.shrink();
    }

    // Refresh if cache is stale (> 60s) or for a different route
    if (_transit.shouldRefreshJourneys(originId, destId, walkOffset)) {
      _transit.fetchJourneys(
        originId: originId,
        destId: destId,
        walkOffsetMinutes: walkOffset,
      ).then((_) {
        if (mounted) setState(() {});
      });
    }

    // Filter to catchable journeys (departure within reasonable time)
    // Compare local times since journey times are UTC
    final now = DateTime.now();
    final pinStore = PinnedJourneyStore();
    final pinned = pinStore.effectivePinnedJourney(
        _transitJourneys ?? [], originId, destId, isMorning);
    final relevant = (_transitJourneys ?? [])
        .where((j) =>
            j.departureTime.toLocal().isAfter(
                now.subtract(const Duration(minutes: 5))))
        .take(4)
        .toList();

    // Show the card if there is a pinned journey OR any catchable journeys.
    if (relevant.isEmpty && pinned == null) {
      _transitCardShown = false;
      return const SizedBox.shrink();
    }

    _transitCardShown = true;

    final walkBuffer = _transitCfg!.walkMinutes(isMorning);
    final directionLabel = _transitCfg!.directionLabel(isMorning);

    final others = relevant
        .where((j) => !pinStore.isPinnedJourney(j, originId, destId, isMorning))
        .toList();

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
            if (pinned != null)
              TransitJourneyRow(
                journey: pinned,
                now: now,
                walkBuffer: walkBuffer,
                theme: theme,
                isPinned: true,
                onTogglePin: () => pinStore.unpin(),
              ),
            ...others.map((j) => TransitJourneyRow(
                  journey: j,
                  now: now,
                  walkBuffer: walkBuffer,
                  theme: theme,
                  isPinned: false,
                  onTogglePin: () => pinStore.pin(j, _transitCfg!, isMorning),
                )),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Departure data provided by Trafiklab.se (CC-BY 4.0)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
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
                    formatSignedMinutes(minutes),
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
            const SizedBox(height: 4),
            Text(
              'Started at ${log.startTime.substring(0, 5)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
            StatRow(label: 'Expected', value: formatMins(log.expectedMinutes), verticalPadding: 4),
            if (log.morningOverheadMinutes + log.eveningOverheadMinutes > 0)
              StatRow(label: 'Commute overhead', value: '${log.morningOverheadMinutes}/${log.eveningOverheadMinutes} min (am/pm)', verticalPadding: 4),
            if (log.morningProductiveCommuteMinutes + log.eveningProductiveCommuteMinutes > 0)
              StatRow(label: 'Productive commute', value: '${log.morningProductiveCommuteMinutes}/${log.eveningProductiveCommuteMinutes} min (am/pm)', verticalPadding: 4),
            StatRow(label: 'Total', value: formatMins(log.expectedMinutes + log.overheadMinutes + log.productiveCommuteMinutes), verticalPadding: 4),

            const SizedBox(height: 8),
            // Banked time to withdraw (flex) — live projection only
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Banked time to withdraw',
                    style: theme.textTheme.titleSmall),
                Text(
                  formatMins(log.flexMinutes),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _showEditFlexDialog(context, log.flexMinutes),
                  child: const Text('Adjust'),
                ),
              ],
            ),

            // Note — editable while the day is active
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Note', style: theme.textTheme.titleSmall),
                TextButton(
                  onPressed: () => _showEditNoteDialog(context, log.note),
                  child: Text(
                    (log.note?.isNotEmpty == true) ? 'Edit' : 'Add',
                  ),
                ),
              ],
            ),
            if (log.note?.isNotEmpty == true)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  log.note,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            // Lunch timer section
            LunchTimerSection(
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
            StatRow(label: 'Started', value: log.startTime, verticalPadding: 4),
            StatRow(label: 'Ended', value: log.endTime ?? '—', verticalPadding: 4),
            StatRow(
              label: log.overtimeMinutes < 0 ? 'Undertime' : 'Overtime',
              value: formatSignedMinutes(log.overtimeMinutes),
              verticalPadding: 4,
            ),
            if (log.lunchMinutes != null && log.lunchMinutes > 0)
              StatRow(label: 'Lunch', value: '${log.lunchMinutes} min', verticalPadding: 4),
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


  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
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
    final result = await showDialog<StartDayResult>(
      context: ctx,
      builder: (_) => StartDayDialog(
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
        flexMinutes: result.flexMinutes,
        morningOverheadMinutes: result.morningOverheadMinutes,
        morningProductiveCommuteMinutes: result.morningProductiveCommuteMinutes,
        eveningOverheadMinutes: result.eveningOverheadMinutes,
        eveningProductiveCommuteMinutes: result.eveningProductiveCommuteMinutes,
        note: result.note,
      );
      // Save last-used selections
      await prefs.setLastTravelPresetId(result.presetId);
    }
  }

  Future<void> _showStopDayDialog(BuildContext ctx) async {
    final log = _state.todayLog;
    final currentLunch = log?.lunchMinutes ?? 0;
    final result = await showDialog<StopDayResult>(
      context: ctx,
      builder: (_) => StopDayDialog(initialLunchMinutes: currentLunch),
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
                divisions: PreferencesService().sliderDivisions(0, 120),
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

  /// Adjust how much banked overtime the user plans to withdraw as personal
  /// time. Live projection only — moves the projected leave time earlier.
  Future<void> _showEditFlexDialog(BuildContext ctx, int currentFlex) async {
    int flex = currentFlex;
    await showDialog<void>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Banked time to withdraw'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Time taken from your bank as personal time. This moves your '
                'projected leave time earlier.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: flex.toDouble(),
                      min: 0,
                      max: 240,
                      divisions: PreferencesService().sliderDivisions(0, 240),
                      label: '$flex min',
                      onChanged: (v) {
                        flex = v.round();
                        setDialogState(() {});
                      },
                    ),
                  ),
                  Text(
                    '$flex min',
                    style: Theme.of(ctx)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _state.updateFlexMinutes(flex);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Add or edit the note on the active day.
  Future<void> _showEditNoteDialog(BuildContext ctx, String? currentNote) async {
    final controller = TextEditingController(text: currentNote ?? '');
    await showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Optional note...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _state.updateNote(controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
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
                      divisions: PreferencesService().sliderDivisions(0, 240),
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
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
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

    final result = await showDialog<EditDayResult>(
      context: ctx,
      builder: (_) => EditDayDialog(
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
      // Persist the preset now in effect (used as dialog default elsewhere).
      await PreferencesService().setLastTravelPresetId(selected.id);
    }
  }
}




// ---------------------------------------------------------------------------
// Transit departure row (used in My Day transit card)
// ---------------------------------------------------------------------------

