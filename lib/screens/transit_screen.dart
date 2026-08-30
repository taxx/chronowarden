import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/departure_info.dart';
import '../models/transit_config.dart';
import '../services/transit_service.dart';

/// Transit tab — shows real-time Roslagsbanan departures.
///
/// Only fetches data when [TransitConfig.enabled] is true.
/// Auto-refreshes every 30 seconds when visible.
class TransitScreen extends StatefulWidget {
  const TransitScreen({super.key});

  @override
  State<TransitScreen> createState() => _TransitScreenState();
}

class _TransitScreenState extends State<TransitScreen>
    with WidgetsBindingObserver {
  final _transit = TransitService();
  List<DepartureInfo>? _matched;
  List<DepartureInfo>? _other;
  TransitConfig? _cfg;
  bool _loading = true;
  Timer? _refreshTimer;
  bool _isVisible = true;

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
    // Pause refresh when app is backgrounded
    if (state == AppLifecycleState.resumed) {
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }

  Future<void> _load() async {
    await _transit.loadConfig();
    _cfg = _transit.config;

    if (_cfg!.enabled) {
      await _refresh();
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    if (_cfg == null || !_cfg!.enabled) return;

    final departures = await _transit.fetchDepartures(_cfg!.departureSiteId);
    if (departures == null) return;

    final railRelevant = _transit.filterRailRelevant(departures);

    List<DepartureInfo> matched;
    List<DepartureInfo> other;

    if (_cfg!.hasDestination) {
      matched = _transit.filterByDestination(
        railRelevant,
        _cfg!.destinationSiteId,
        _cfg!.destinationSiteName,
      );
      other = railRelevant
          .where((d) => !matched.contains(d))
          .toList();
    } else {
      matched = railRelevant;
      other = [];
    }

    if (mounted) setState(() {
      _matched = matched;
      _other = other;
    });
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isVisible && _cfg?.enabled == true) {
        _refresh();
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, _) {
        // Re-read config in case it changed in settings
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
            Icon(Icons.train, size: 64,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Transit integration is disabled.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Enable it in Settings to see real-time departures.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -- Header --
          _HeaderCard(
            cfg: _cfg!,
            theme: theme,
          ),
          const SizedBox(height: 16),

          // -- Matched departures (destination filtered) --
          if (_matched != null && _matched!.isNotEmpty) ...[
            Text('Departures to ${_cfg!.destinationSiteName}',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._matched!.map((d) => _DepartureCard(
                  departure: d,
                  isTarget: true,
                  theme: theme,
                )),
            const SizedBox(height: 16),
          ],

          // -- Other departures --
          if (_other != null && _other!.isNotEmpty) ...[
            Text('Other departures',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._other!.map((d) => _DepartureCard(
                  departure: d,
                  isTarget: false,
                  theme: theme,
                )),
          ],

          // -- Empty state --
          if ((_matched == null || _matched!.isEmpty) &&
              (_other == null || _other!.isEmpty)) ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No departures found',
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

          // -- Refresh button --
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header card
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  final TransitConfig cfg;
  final ThemeData theme;

  const _HeaderCard({required this.cfg, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.train, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Real-Time Departures',
                      style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _statRow('From', cfg.departureSiteName),
            _statRow('To', cfg.hasDestination
                ? cfg.destinationSiteName
                : 'All destinations'),
            _statRow('Walk to station', '${cfg.walkMinutesToStation} min'),
            _statRow('Walk from station', '${cfg.walkMinutesFromStation} min'),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
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
// Departure card
// ---------------------------------------------------------------------------

class _DepartureCard extends StatelessWidget {
  final DepartureInfo departure;
  final bool isTarget;
  final ThemeData theme;

  const _DepartureCard({
    required this.departure,
    required this.isTarget,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final scheduledStr =
        '${departure.scheduledTime.hour.toString().padLeft(2, '0')}:'
        '${departure.scheduledTime.minute.toString().padLeft(2, '0')}';

    final delayColor = _delayColor(departure);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isTarget
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isTarget)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.brightness_high_outlined, size: 18,
                        color: theme.colorScheme.primary),
                  ),
                Text(
                  scheduledStr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '→ ${departure.destination}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                // Delay badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: delayColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    departure.delayLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: delayColor,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (departure.track != null)
                  Text(
                    'Platform ${departure.track}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (departure.track != null && departure.lineNumber != null)
                  Text(' · ', style: theme.textTheme.bodySmall),
                if (departure.lineNumber != null)
                  Text(
                    'Line ${departure.lineNumber}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (departure.track == null && departure.lineNumber == null)
                  SizedBox(width: 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _delayColor(DepartureInfo d) {
    if (d.isCancelled) return Colors.red;
    if (d.expectedTime == null) return Colors.green;
    final diff = d.expectedTime!.difference(d.scheduledTime).inMinutes;
    if (diff <= 0) return Colors.green;
    if (diff <= 5) return Colors.orange.shade700;
    return Colors.red;
  }
}
