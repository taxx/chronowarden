import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_strings.dart';
import '../models/journey_info.dart';
import '../models/time_log.dart';
import '../models/travel_preset.dart';
import '../models/transit_config.dart';
import '../services/notification_service.dart';
import '../services/pinned_journey_store.dart';
import '../services/preferences_service.dart';
import '../services/transit_service.dart';
import '../services/user_settings_service.dart';
import '../utils/format.dart';
import '../widgets/edit_day_dialog.dart';
import '../widgets/lunch_timer_section.dart';
import '../widgets/journey_tile.dart';
import '../widgets/start_stop_day_dialogs.dart';
import '../widgets/stat_row.dart';

/// Whether the pre-start My Day transit card ("morning planning") should be
/// shown on [now]'s weekday.
///
/// Weekends are hidden unless the user works them, which they signal by
/// enabling the "show weekends" calendar setting. An active day bypasses this
/// check entirely (see `_buildTransitCard`).
bool shouldShowTransitPlanning({
  required DateTime now,
  required bool showWeekends,
}) {
  if (now.weekday <= DateTime.friday) return true;
  return showWeekends;
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
  List<JourneyInfo>? _transitJourneys;
  TransitConfig? _transitCfg;
  // ignore: unused_field
  bool _transitCardShown = false;
  String? _selectedPresetId;

  @override
  void initState() {
    super.initState();
    _notifications.init(); // fire-and-forget; _enabled stays false until ready
    _notifications.addListener(_onNotificationsChanged);
    // Last-used travel preset — determines transit-card visibility when no
    // day is active yet (it is the Start Day dialog default).
    PreferencesService().getLastTravelPresetId().then((id) {
      if (mounted) setState(() => _selectedPresetId = id);
    });
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
    _notifications.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onNotificationsChanged() {
    if (mounted) setState(() {});
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
            const SizedBox(height: 24),
            _buildTransitCard(theme),
          ],
        ),
      ),
    );
  }

  /// Check if we should fire a notification.
  ///
  /// All decision logic lives in [NotificationService.check] so it is
  /// consistent, testable and unaffected by which tab is visible.
  void _checkNotification() {
    final log = _state.todayLog;
    if (log == null || log.endTime != null) {
      _notifications.clearAlert();
      return;
    }
    _notifications.check(
      date: log.date,
      leaveTime: _state.effectiveLeaveTime(log),
      now: DateTime.now(),
    );
  }

  /// The preset that currently applies, for transit visibility.
  ///
  /// An active/completed day is matched by commute profile so the decision
  /// follows the synced log rather than this device's last-used preset. When
  /// no day exists yet, the last-used preset (the Start Day default) is used.
  TravelPreset? _selectedPreset() {
    final log = _state.todayLog;
    if (log != null) {
      final match = _state.presetMatchingLog(log);
      if (match != null) return match;
    }
    final id = _selectedPresetId;
    if (id == null) return null;
    for (final p in _state.travelPresets) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Whether the current commute involves public transit. When the selection
  /// is unknown we keep the card visible so transit users aren't cut off.
  bool _commuteUsesTransit() => _selectedPreset()?.usesTransit ?? true;

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

    // On weekends, the pre-start "morning planning" card only makes sense if
    // the user works weekends (signalled by the "show weekends" calendar
    // setting). An active day always shows, whatever the weekday.
    if (!hasActiveDay &&
        !shouldShowTransitPlanning(
          now: DateTime.now(),
          showWeekends: PreferencesService().showWeekends.value,
        )) {
      _transitCardShown = false;
      return const SizedBox.shrink();
    }

    // Respect the applicable travel preset: a non-transit commute (e.g.
    // "No commute, work from home") hides the card even when the global
    // transit integration is enabled and stops are configured.
    if (!_commuteUsesTransit()) {
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
                  child: Text(
                    context.t('Transit — {direction}',
                        {'direction': directionLabel}),
                    style: theme.textTheme.titleSmall,
                  ),
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
                context.t('Departure data provided by Trafiklab.se (CC-BY 4.0)'),
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
                  Text(context.t('Time Bank'), style: theme.textTheme.titleSmall),
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
            Text(context.t('Today has not started'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              context.t('Tap the button below to start tracking your day.'),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showStartDayDialog(context),
                icon: const Icon(Icons.play_arrow),
                label: Text(context.t('Start Day')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActive(ThemeData theme, TimeLog log) {
    final elapsed = log.elapsed;
    final leaveTime = _state.effectiveLeaveTime(log); // includes live lunch
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
              isPast
                  ? context.t("You're free to go!")
                  : context.t('Day is active'),
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
              context.t('Started at {time}',
                  {'time': log.startTime.substring(0, 5)}),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.t('Leave time'), style: theme.textTheme.titleSmall),
                  Text(
                    '${leaveTime.hour.toString().padLeft(2, '0')}:${leaveTime.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(context.t('Remaining'), style: theme.textTheme.titleSmall),
                  Text(
                    isPast ? '—' : _formatDuration(remaining),
                    style: theme.textTheme.titleMedium,
                  ),
                  if (lunch > 0 && !isPast)
                    Text(
                      context.t('net: {value}', {
                        'value': isNetPast
                            ? context.t('✓ done')
                            : _formatDuration(netRemaining),
                      }),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                    ),
                ]),
              ],
            ),
            const SizedBox(height: 24),
            StatRow(label: context.t('Expected'), value: formatMins(log.expectedMinutes), verticalPadding: 4),
            if (log.morningOverheadMinutes + log.eveningOverheadMinutes > 0)
              StatRow(label: context.t('Commute overhead'), value: '${log.morningOverheadMinutes}/${log.eveningOverheadMinutes} min (am/pm)', verticalPadding: 4),
            if (log.morningProductiveCommuteMinutes + log.eveningProductiveCommuteMinutes > 0)
              StatRow(label: context.t('Productive commute'), value: '${log.morningProductiveCommuteMinutes}/${log.eveningProductiveCommuteMinutes} min (am/pm)', verticalPadding: 4),
            StatRow(label: context.t('Total'), value: formatMins(log.expectedMinutes + log.overheadMinutes + log.productiveCommuteMinutes), verticalPadding: 4),

            const SizedBox(height: 8),
            // Banked time to withdraw (flex) — live projection only
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.t('Banked time to withdraw'),
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
                  child: Text(context.t('Adjust')),
                ),
              ],
            ),

            // Note — editable while the day is active
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.t('Note'), style: theme.textTheme.titleSmall),
                TextButton(
                  onPressed: () => _showEditNoteDialog(context, log.note),
                  child: Text(
                    (log.note?.isNotEmpty == true)
                        ? context.t('Edit')
                        : context.t('Add'),
                  ),
                ),
              ],
            ),
            if (log.note?.isNotEmpty == true)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  log.note!,
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
                label: Text(context.t('Change commute pattern')),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showStopDayDialog(context),
                icon: const Icon(Icons.stop),
                label: Text(context.t('Stop Day')),
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

  Widget _buildCompleted(ThemeData theme, TimeLog log) {
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
            Text(context.t('Day completed'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            StatRow(label: context.t('Started'), value: log.startTime, verticalPadding: 4),
            StatRow(label: context.t('Ended'), value: log.endTime ?? '—', verticalPadding: 4),
            StatRow(
              label: log.overtimeMinutes < 0
                  ? context.t('Undertime')
                  : context.t('Overtime'),
              value: formatSignedMinutes(log.overtimeMinutes),
              verticalPadding: 4,
            ),
            if (log.lunchMinutes > 0)
              StatRow(label: context.t('Lunch'), value: '${log.lunchMinutes} min', verticalPadding: 4),
            if (log.note?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.t('Note: {note}', {'note': log.note}),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showEditDayDialog(context, log),
                  icon: const Icon(Icons.edit),
                  label: Text(context.t('Edit')),
                ),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, log.id!, log.date),
                  icon: const Icon(Icons.delete),
                  label: Text(context.t('Delete')),
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
        SnackBar(content: Text(ctx.t('Add at least one travel preset in Settings.'))),
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
      if (mounted) setState(() => _selectedPresetId = result.presetId);
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
          title: Text(context.t('Adjust lunch')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: lunch.toDouble(),
                min: 0,
                max: PreferencesService.maxLunchMinutes.toDouble(),
                divisions: PreferencesService()
                    .sliderDivisions(0, PreferencesService.maxLunchMinutes.toDouble()),
                label: context.t('{minutes} min', {'minutes': lunch}),
                onChanged: (v) {
                  lunch = v.round();
                  setDialogState(() {});
                },
              ),
              const SizedBox(height: 4),
              Text(context.t('{minutes} min', {'minutes': lunch}),
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('Cancel'))),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _state.updateLunchMinutes(lunch);
              },
              child: Text(context.t('Save')),
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
          title: Text(context.t('Banked time to withdraw')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t(
                  'Time taken from your bank as personal time. This moves your '
                  'projected leave time earlier.',
                ),
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
                      label: context.t('{minutes} min', {'minutes': flex}),
                      onChanged: (v) {
                        flex = v.round();
                        setDialogState(() {});
                      },
                    ),
                  ),
                  Text(
                    context.t('{minutes} min', {'minutes': flex}),
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
              child: Text(context.t('Cancel')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _state.updateFlexMinutes(flex);
              },
              child: Text(context.t('Save')),
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
        title: Text(ctx.t('Note')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: ctx.t('Optional note...'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.t('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _state.updateNote(controller.text);
            },
            child: Text(ctx.t('Save')),
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

    int lunch =
        calculatedMinutes.clamp(0, PreferencesService.maxLunchMinutes);
    await showDialog<void>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.t('Lunch stopped')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t('Started: {time}', {'time': '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}'}),
                   style: Theme.of(ctx).textTheme.bodyMedium),
              Text(context.t('Ended: {time}', {'time': '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}'}),
                   style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(context.t('Duration: {minutes} min', {'minutes': calculatedMinutes}),
                   style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(context.t('Adjust if needed:'), style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: lunch.toDouble(),
                      min: 0,
                      max: PreferencesService.maxLunchMinutes.toDouble(),
                      divisions: PreferencesService()
                          .sliderDivisions(0, PreferencesService.maxLunchMinutes.toDouble()),
                      label: context.t('{minutes} min', {'minutes': lunch}),
                      onChanged: (v) {
                        lunch = v.round();
                        setDialogState(() {});
                      },
                    ),
                  ),
                  Text(context.t('{minutes} min', {'minutes': lunch}), style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text(context.t('Cancel')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _state.stopLunch(lunch);
              },
              child: Text(context.t('Save')),
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
        SnackBar(content: Text(ctx.t('Settings not loaded yet. Try again.'))),
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
      if (mounted) setState(() => _selectedPresetId = result.presetId);
    }
  }

  Future<void> _confirmDelete(BuildContext ctx, String id, String date) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(ctx.t('Delete day')),
        content: Text(ctx.t(
          'Permanently delete the entry for {date}? This cannot be undone.',
          {'date': date},
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t('Cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(ctx.t('Delete')),
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
        SnackBar(content: Text(ctx.t('No travel presets available. Add one in Settings.'))),
      );
      return;
    }

    dynamic pickedPreset;
    final selected = await showDialog<dynamic>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.t('Change commute pattern')),
          content: DropdownButtonFormField(
            items: state.travelPresets.map<DropdownMenuItem>((p) {
              return DropdownMenuItem(
                value: p,
                child: Text(context.t(
                  '{name} — {am} min walk, {pm} min train',
                  {
                    'name': p.name,
                    'am': '${p.morningOverheadMinutes}/${p.eveningOverheadMinutes}',
                    'pm': '${p.morningProductiveCommuteMinutes}/${p.eveningProductiveCommuteMinutes}',
                  },
                )),
              );
            }).toList(),
            onChanged: (v) {
              pickedPreset = v;
              setDialogState(() {});
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('Cancel'))),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, pickedPreset),
              child: Text(context.t('Apply')),
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
      if (mounted) setState(() => _selectedPresetId = selected.id);
    }
  }
}




// ---------------------------------------------------------------------------
// Transit departure row (used in My Day transit card)
// ---------------------------------------------------------------------------

