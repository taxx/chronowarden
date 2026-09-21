import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/journey_info.dart';
import '../models/transit_config.dart';
import '../services/pinned_journey_store.dart';
import '../services/transit_service.dart';

/// Transit tab — shows journey options between home ↔ work stations.
///
/// Smart direction:
///   No active day + before 11:00: home → work (morning commute)
///   Active day or 11:00+:         work → home (afternoon commute)
///
/// Only fetches data when [TransitConfig.enabled] is true and both
/// home and work stations are configured.
/// Auto-refreshes every 30 seconds when visible.
class TransitScreen extends StatefulWidget {
  const TransitScreen({super.key});

  @override
  State<TransitScreen> createState() => _TransitScreenState();
}

class _TransitScreenState extends State<TransitScreen>
    with WidgetsBindingObserver {
  final _transit = TransitService();
  List<JourneyInfo>? _journeys;
  TransitConfig? _cfg;
  DateTime? _lastUpdatedAt;
  bool _loading = true;
  Timer? _refreshTimer;
  bool _isVisible = true; // ignore: prefer_final_fields
  bool _isMorning = true;

  static bool _timeIsMorning() {
    final now = DateTime.now();
    return now.hour < 11;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }

  Future<void> _load() async {
    await _transit.loadConfig();
    _cfg = _transit.config;

    if (_cfg!.enabled && _cfg!.hasWork && _cfg!.hasHome) {
      _isMorning = _timeIsMorning();
      await _refresh();
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    if (_cfg == null || !_cfg!.enabled) return;

    // Active day → always afternoon (work → home).
    // Otherwise use time of day.
    final hasActiveDay = AppState().todayLog?.endTime == null &&
        AppState().todayLog != null;
    _isMorning = hasActiveDay ? false : _timeIsMorning();

    // Morning: home → work. Afternoon: work → home.
    final originId = _isMorning ? _cfg!.homeStopId : _cfg!.workStopId;
    final destId = _isMorning ? _cfg!.workStopId : _cfg!.homeStopId;

    final walkOffset = _isMorning
        ? _cfg!.walkHomeMinutes
        : _cfg!.walkWorkMinutes;

    final journeys = await _transit.fetchJourneys(
      originId: originId,
      destId: destId,
      walkOffsetMinutes: walkOffset,
    );

    if (mounted) setState(() {
      _journeys = journeys;
      _lastUpdatedAt = DateTime.now();
    });
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isVisible && _cfg?.enabled == true) {
        _isMorning = _timeIsMorning();
        _refresh();
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppState(), PinnedJourneyStore()]),
      builder: (context, _) {
        _cfg = _transit.config;
        return _buildContent(Theme.of(context));
      },
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_cfg!.enabled) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_train, size: 64,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Transit integration is disabled.',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Enable it in Settings to see journey options.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      );
    }

    if (!_cfg!.hasWork || !_cfg!.hasHome) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 64,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Configure your stations in Settings.',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Both work and home stations must be set.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      );
    }

    final directionLabel = _isMorning
        ? '${_cfg!.homeStopName} → ${_cfg!.workStopName}'
        : '${_cfg!.workStopName} → ${_cfg!.homeStopName}';

    final originId = _isMorning ? _cfg!.homeStopId : _cfg!.workStopId;
    final destId = _isMorning ? _cfg!.workStopId : _cfg!.homeStopId;
    final pinStore = PinnedJourneyStore();
    final pinned = pinStore.effectivePinnedJourney(
        _journeys ?? [], originId, destId, _isMorning);
    final others = (_journeys ?? [])
        .where((j) => !pinStore.isPinnedJourney(j, originId, destId, _isMorning))
        .toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -- Header --
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_train,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Journey Options',
                            style: theme.textTheme.titleMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _statRow(theme, 'Direction', directionLabel),
                  _statRow(theme, 'Walk home↔station',
                      '${_cfg!.walkHomeMinutes} min'),
                  _statRow(theme, 'Walk station↔work',
                      '${_cfg!.walkWorkMinutes} min'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // -- Journey cards --
          if (pinned != null || others.isNotEmpty) ...[ 
            Text(
              _isMorning
                  ? 'Traveling to ${_cfg!.workStopName}'
                  : 'Traveling to ${_cfg!.homeStopName}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (pinned != null)
              _JourneyCard(
                journey: pinned,
                cfg: _cfg!,
                isMorning: _isMorning,
                theme: theme,
                isPinned: true,
                onTogglePin: () => pinStore.unpin(),
              ),
            ...others.map((j) => _JourneyCard(
                  journey: j,
                  cfg: _cfg!,
                  isMorning: _isMorning,
                  theme: theme,
                  isPinned: false,
                  onTogglePin: () => pinStore.pin(j, _cfg!, _isMorning),
                )),
          ],

          // -- Empty state --
          if (pinned == null && (_journeys == null || _journeys!.isEmpty)) ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No journeys found',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Check your station settings or try again later.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // -- Refresh + timestamp --
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ),
          // -- Attribution --
          const SizedBox(height: 24),
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
          if (_lastUpdatedAt != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Updated ${_fmtTime(_lastUpdatedAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Journey card
// ---------------------------------------------------------------------------

class _JourneyCard extends StatelessWidget {
  final JourneyInfo journey;
  final TransitConfig cfg;
  final bool isMorning;
  final ThemeData theme;
  final bool isPinned;
  final VoidCallback? onTogglePin;

  const _JourneyCard({
    required this.journey,
    required this.cfg,
    required this.isMorning,
    required this.theme,
    this.isPinned = false,
    this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final depLocal = journey.departureTime.toLocal();
    final depStr =
        '${depLocal.hour.toString().padLeft(2, '0')}:'
        '${depLocal.minute.toString().padLeft(2, '0')}';

    final delayColor = _delayColor(journey);

    // Line badge
    final line = journey.mainLine;
    // Destination
    final dest = journey.mainDestination ?? 'Unknown';

    // Occupancy badge
    final occ = journey.occupancy;

    // Platform
    final platform = journey.departurePlatform;

    // Transport mode info is available via legs if needed
    // Transport mode info is available via legs if needed
    final mode = journey.transportMode;
    // ignore: unused_local_variable, no_leading_underscores_for_local_identifiers
    final mode_ = mode;

    final pinnedColor = isPinned
        ? theme.colorScheme.tertiary
        : theme.colorScheme.surfaceContainerHighest;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isPinned ? pinnedColor.withValues(alpha: 0.25) : null,
      shape: isPinned
          ? RoundedRectangleBorder(
              side: BorderSide(color: theme.colorScheme.tertiary, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: departure time + line badge + delay
            Row(
              children: [
                Text(
                  depStr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (line != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      line,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: delayColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    journey.delayLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: delayColor,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                _pinControl(),
              ],
            ),
            const SizedBox(height: 6),
            // Destination + duration + platform
            Row(
              children: [
                Expanded(
                  child: Text(
                    '→ $dest · ${journey.durationMinutes} min',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (platform != null)
                  Text(
                    'Platform $platform',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            // Occupancy badge
            if (occ != null) ...[
              const SizedBox(height: 4),
              _OccupancyBadge(occupancy: occ, theme: theme),
            ],
            const SizedBox(height: 6),
            _LeaveTimeInfo(
              journey: journey,
              cfg: cfg,
              isMorning: isMorning,
              theme: theme,
              isPinned: isPinned,
            ),
          ],
        ),
      ),
    );
  }

  Color _delayColor(JourneyInfo j) {
    final diff = j.departureDelayMinutes;
    if (diff <= 0) return Colors.green;
    if (diff <= 5) return Colors.orange.shade700;
    return Colors.red;
  }

  /// Compact pin/commit control shown on every journey card.
  Widget _pinControl() {
    final label = isPinned ? 'Locked' : 'Pin';
    final icon = isPinned ? Icons.lock : Icons.push_pin_outlined;
    final color = isPinned
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;
    return Tooltip(
      message: isPinned ? 'Unpin this journey' : 'Commit to this journey',
      child: InkWell(
        onTap: onTogglePin,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Occupancy badge
// ---------------------------------------------------------------------------

class _OccupancyBadge extends StatelessWidget {
  final String occupancy;
  final ThemeData theme;

  const _OccupancyBadge({
    required this.occupancy,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (occupancy) {
      'MANY_SEATS' => (
        Icons.chair,
        'Many seats available',
        Colors.green,
      ),
      'FEW_SEATS' => (
        Icons.chair,
        'Few seats available',
        Colors.orange.shade700,
      ),
      'STANDING_ONLY' => (
        Icons.directions_bus,
        'Standing room only',
        Colors.red,
      ),
      _ => (Icons.chair, 'Seats available', Colors.green),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Leave time info row
// ---------------------------------------------------------------------------

class _LeaveTimeInfo extends StatelessWidget {
  final JourneyInfo journey;
  final TransitConfig cfg;
  final bool isMorning;
  final ThemeData theme;
  final bool isPinned;

  const _LeaveTimeInfo({
    required this.journey,
    required this.cfg,
    required this.isMorning,
    required this.theme,
    this.isPinned = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final depTime = journey.departureTime.toLocal();
    final walkBuffer = isMorning
        ? cfg.walkHomeMinutes
        : cfg.walkWorkMinutes;
    // Leave time accounts for walking to station
    final leaveTime = depTime.subtract(
        Duration(minutes: walkBuffer));
    final isCatchable = leaveTime.isAfter(now) ||
        leaveTime.difference(now).inMinutes.abs() <= 1;

    final leaveStr =
        '${leaveTime.hour.toString().padLeft(2, '0')}:'
        '${leaveTime.minute.toString().padLeft(2, '0')}';

    // Time until user must leave
    final minutesUntilLeave = now.isBefore(leaveTime)
        ? leaveTime.difference(now).inMinutes
        : 0;
    String untilStr;
    if (minutesUntilLeave <= 0) {
      untilStr = '';
    } else if (minutesUntilLeave == 1) {
      untilStr = ' · leave in 1 min';
    } else {
      untilStr = ' · leave in $minutesUntilLeave min';
    }

    // Arrival time (local)
    final arrLocal = journey.arrivalTime.toLocal();
    final arrStr =
        '${arrLocal.hour.toString().padLeft(2, '0')}:'
        '${arrLocal.minute.toString().padLeft(2, '0')}';

    // For pinned journeys: never show "missed". If the leave time has passed,
    // show a neutral "Committed ride — leave time passed" label instead.
    String text;
    Color textColor;
    TextStyle? textStyle;
    if (isPinned) {
      if (isCatchable) {
        text = 'Leave at $leaveStr · arrive $arrStr$untilStr';
      } else {
        // Leave time has passed — keep showing the countdown to departure.
        final minutesUntilDeparture = now.isBefore(depTime)
            ? depTime.difference(now).inMinutes
            : 0;
        if (minutesUntilDeparture > 0) {
          final depCountdown = minutesUntilDeparture == 1
              ? '1 min'
              : '$minutesUntilDeparture min';
          text = 'Departs in $depCountdown · arrive $arrStr';
        } else {
          text = 'Committed ride — departed';
        }
      }
      textColor = theme.colorScheme.onSurfaceVariant;
      textStyle = const TextStyle(fontStyle: FontStyle.normal);
    } else {
      text = isCatchable
          ? 'Leave at $leaveStr · arrive $arrStr$untilStr'
          : 'Missed — needed to leave by $leaveStr';
      textColor = isCatchable
          ? theme.colorScheme.onSurfaceVariant
          : theme.colorScheme.error;
      textStyle = isCatchable ? null : const TextStyle(fontStyle: FontStyle.italic);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor,
            fontStyle: textStyle?.fontStyle,
          ),
        ),
      ],
    );
  }
}
