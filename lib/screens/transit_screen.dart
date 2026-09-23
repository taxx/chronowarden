import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/journey_info.dart';
import '../models/transit_config.dart';
import '../services/pinned_journey_store.dart';
import '../services/transit_service.dart';
import '../widgets/journey_card.dart';
import '../widgets/stat_row.dart';

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
    final originId = _cfg!.originStopId(_isMorning);
    final destId = _cfg!.destStopId(_isMorning);
    final walkOffset = _cfg!.walkMinutes(_isMorning);

    final journeys = await _transit.fetchJourneys(
      originId: originId,
      destId: destId,
      walkOffsetMinutes: walkOffset,
    );

    if (mounted) {
      setState(() {
        _journeys = journeys;
        _lastUpdatedAt = DateTime.now();
      });
    }
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

    final directionLabel = _cfg!.directionLabel(_isMorning);

    final originId = _cfg!.originStopId(_isMorning);
    final destId = _cfg!.destStopId(_isMorning);
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
                  StatRow(label: 'Direction', value: directionLabel, expanded: true),
                  StatRow(label: 'Walk home↔station', value: '${_cfg!.walkHomeMinutes} min', expanded: true),
                  StatRow(label: 'Walk station↔work', value: '${_cfg!.walkWorkMinutes} min', expanded: true),
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
              JourneyCard(
                journey: pinned,
                cfg: _cfg!,
                isMorning: _isMorning,
                theme: theme,
                isPinned: true,
                onTogglePin: () => pinStore.unpin(),
              ),
            ...others.map((j) => JourneyCard(
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

}

