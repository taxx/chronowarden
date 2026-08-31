import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/departure_info.dart';
import '../models/transit_config.dart';
import '../services/transit_service.dart';

/// Transit tab — shows real-time Roslagsbanan departures.
///
/// Smart direction:
///   Morning (before 11:00): departures from HOME → going toward WORK
///   Afternoon (11:00+):     departures from WORK → going toward HOME
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
  List<DepartureInfo>? _departures;
  TransitConfig? _cfg;
  DateTime? _lastUpdatedAt;
  bool _loading = true;
  Timer? _refreshTimer;
  bool _isVisible = true;
  bool _isMorning = true;

  /// Determines if current time is before 11:00 (morning commute).
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

    if (_cfg!.enabled) {
      _isMorning = _timeIsMorning();
      await _refresh();
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    if (_cfg == null || !_cfg!.enabled) return;

    _isMorning = _timeIsMorning();

    // Determine which station to fetch from
    // Morning:  home → work  (fetch from home station)
    // Afternoon: work → home (fetch from work station)
    final fetchSiteId = _isMorning
        ? _cfg!.destinationSiteId
        : _cfg!.departureSiteId;

    final departures = await _transit.fetchDepartures(fetchSiteId);
    if (departures == null) return;

    final railRelevant = _transit.filterRailRelevant(departures);

    // Filter by line number (e.g., "28", "28S") if configured
    // Line-based filtering works because the API shows the end
    // station as destination, not the intermediate station
    List<DepartureInfo> filtered;
    if (_cfg!.hasLineFilter) {
      filtered = _transit.filterByLineNumber(
        railRelevant,
        _cfg!.lineFilter,
      );
    } else if (_cfg!.hasDestination) {
      // Fall back to destination-name filtering
      final filterName = _isMorning
          ? _cfg!.departureSiteName
          : _cfg!.destinationSiteName;
      filtered = _transit.filterByDestination(
        railRelevant,
        null,
        filterName,
      );
    } else {
      filtered = railRelevant;
    }

    if (mounted) setState(() {
      _departures = filtered;
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
      listenable: AppState(),
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
            Text('Enable it in Settings to see real-time departures.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      );
    }

    final directionLabel = _isMorning
        ? '${_cfg!.destinationSiteName} → ${_cfg!.departureSiteName}'
        : '${_cfg!.departureSiteName} → ${_cfg!.destinationSiteName}';

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -- Header --
          _HeaderCard(
            cfg: _cfg!,
            isMorning: _isMorning,
            theme: theme,
          ),
          const SizedBox(height: 16),

          // -- Departures in current direction --
          if (_departures != null && _departures!.isNotEmpty) ...[
            Text(
              _isMorning
                  ? 'Traveling to ${_cfg!.departureSiteName}'
                  : 'Traveling to ${_cfg!.destinationSiteName}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._departures!.map((d) => _DepartureCard(
                  departure: d,
                  theme: theme,
                )),
          ],

          // -- Empty state --
          if (_departures == null || _departures!.isEmpty) ...[
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

          // -- Refresh button + last updated --
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
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

// ---------------------------------------------------------------------------
// Header card
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  final TransitConfig cfg;
  final bool isMorning;
  final ThemeData theme;

  const _HeaderCard({
    required this.cfg,
    required this.isMorning,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final directionLabel = isMorning
        ? '${cfg.destinationSiteName} → ${cfg.departureSiteName}'
        : '${cfg.departureSiteName} → ${cfg.destinationSiteName}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_train, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Real-Time Departures',
                      style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _statRow('Direction', directionLabel),
            _statRow('Lines', cfg.hasLineFilter
                ? cfg.lineFilter.join(', ')
                : 'All'),
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
  final ThemeData theme;

  const _DepartureCard({
    required this.departure,
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  scheduledStr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (departure.lineNumber != null) ...<Widget>[
                  const SizedBox(width: 10),
                  // Line badge — prominently displayed
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      departure.lineNumber!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
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
                Expanded(
                  child: Text(
                    '→ ${departure.destination}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (departure.track != null)
                  Text(
                    'Platform ${departure.track}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
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
