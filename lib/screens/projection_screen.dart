import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/time_log.dart';
import '../utils/format.dart';
import '../widgets/projection_chart.dart';
import '../widgets/stat_row.dart';

/// Projection calculator — shows how daily flex minutes reduce the time bank.
class ProjectionScreen extends StatefulWidget {
  const ProjectionScreen({super.key});

  @override
  State<ProjectionScreen> createState() => _ProjectionScreenState();
}

class _ProjectionScreenState extends State<ProjectionScreen> {
  final _state = AppState();
  int _dailyFlex = 30;
  bool _useTrend = false;
  bool _loading = true;

  // Computed projection data
  late int _currentBalance;
  late List<TimeLog> _allLogs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _state.refresh();
    if (mounted) {
      setState(() {
        _currentBalance = _state.timeBankMinutes;
        _allLogs = _state.allLogs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Projection')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Time Bank Projection')),
      body: ListenableBuilder(
        listenable: _state,
        builder: (context, _) {
          _currentBalance = _state.timeBankMinutes;
          _allLogs = _state.allLogs;
          return _buildContent(theme);
        },
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final projection = _computeProjection(_dailyFlex, _useTrend);
    final balanceStr = formatDurationMinutes(_currentBalance);
    final avgGrowth = _computeAvgGrowth();
    final netDailyChange = _dailyFlex - (avgGrowth ~/ 5);
    final effectiveFlex = _useTrend ? netDailyChange : _dailyFlex;
    final effectiveWeekly = effectiveFlex * 5;
    final weeksToZero = _currentBalance <= 0 || effectiveFlex <= 0
        ? 0
        : (_currentBalance / (effectiveFlex * 5)).ceil();
    final zeroDate = _computeZeroDate(weeksToZero);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // -- Current balance card --
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current time bank', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  balanceStr,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _currentBalance >= 0
                        ? theme.colorScheme.primary
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // -- Daily flex slider --
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Daily flex target', style: theme.textTheme.titleMedium)),
                    const SizedBox(width: 8),
                    Text('Use trend', style: theme.textTheme.bodySmall),
                    Switch(
                      value: _useTrend,
                      onChanged: (v) => setState(() => _useTrend = v),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _useTrend
                      ? 'Minutes to take from the bank each workday.\nTrend adjusts for your avg growth (${formatDurationMinutes(avgGrowth)}/week).'
                      : 'Minutes to take from the bank each workday.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _dailyFlex.toDouble(),
                        min: 0,
                        max: 120,
                        divisions: 24,
                        label: '$_dailyFlex min',
                        onChanged: (v) => setState(() => _dailyFlex = v.round()),
                      ),
                    ),
                    Text(
                      '$_dailyFlex min',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // -- Projection summary --
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Projection', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_useTrend) ...[  
                  StatRow(label: 'Avg growth rate', value: '${formatDurationMinutes(avgGrowth)}/week'),
                  StatRow(label: 'Net weekly change', value: formatDurationMinutes(-effectiveWeekly)),
                ],
                StatRow(label: 'Weekly reduction', value: formatDurationMinutes(-effectiveWeekly)),
                StatRow(label: 'Weeks to zero', value: '$weeksToZero weeks'),
                StatRow(label: 'Estimated zero date', value: zeroDate),
                if (effectiveFlex > 0) ...[  
                  const SizedBox(height: 8),
                  Text(
                    _useTrend
                        ? 'Taking $_dailyFlex min flex per workday (net ${formatDurationMinutes(-effectiveWeekly)}/week after avg growth of ${formatDurationMinutes(avgGrowth)}/week), your bank of $balanceStr will reach zero in ~$weeksToZero weeks ($zeroDate).'
                        : 'Taking $_dailyFlex min per workday, your bank of $balanceStr will reach zero in ~$weeksToZero weeks ($zeroDate).',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    'Set a daily flex target above to see when your bank reaches zero.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // -- Chart: historical + projected --
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Balance over time', style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Actual bank history (green) vs projected with $_dailyFlex min/day flex (blue)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: ProjectionChartPainter(
                      balances: projection.allBalances,
                      labels: projection.allLabels,
                      splitIndex: projection.splitIndex,
                      greenColor: Colors.green.shade700,
                      blueColor: theme.colorScheme.primary,
                      trendColor: _useTrend ? Colors.orange.shade700 : null,
                      trendBalances: _useTrend ? projection.trendBalances : null,
                      gridColor: theme.dividerColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  // -- Projection calculation ------------------------------------------------

  /// Average weekly overtime accumulation from the last 30 working days.
  /// Returns 0 if insufficient data.
  int _computeAvgGrowth() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get completed logs from last 60 calendar days (to find ~30 workdays)
    final cutoff = today.subtract(const Duration(days: 60));
    final recent = _allLogs.where((l) {
      if (l.endTime == null) return false;
      final d = DateTime.parse(l.date);
      return d.isAfter(cutoff) && d.isBefore(today.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    if (recent.length < 5) return 0; // not enough data

    int totalOvertime = 0;
    int count = 0;
    for (final l in recent) {
      totalOvertime += l.overtimeMinutes;
      count++;
    }

    final avgPerDay = totalOvertime ~/ count;
    return avgPerDay * 5;
  }

  _ProjectionData _computeProjection(int dailyFlex, bool useTrend) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Sort logs by date, compute cumulative balance
    final sorted = _allLogs.where((l) => l.endTime != null).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final allBalances = <int>[];
    final allLabels = <String>[];
    var cum = 0;

    // ---- Historical portion ----
    for (final l in sorted) {
      cum += l.overtimeMinutes;
      allBalances.add(cum);
      final d = DateTime.parse(l.date);
      // Label first, last, and every ~10th
      if (allBalances.length == 1 ||
          allBalances.length == sorted.length ||
          allBalances.length % 10 == 0) {
        allLabels.add('${d.day}/${d.month}');
      } else {
        allLabels.add('');
      }
    }

    final splitIndex = allBalances.length; // where historical ends

    // ---- Projection portion ----
    var projectedCum = _currentBalance;
    // Add today as the connection point
    allBalances.add(projectedCum);
    allLabels.add('now');

    // When trend is enabled, net change = flex - avg growth per day
    final avgDailyGrowth = _computeAvgGrowth() ~/ 5;
    final netChange = useTrend ? (dailyFlex - avgDailyGrowth).clamp(0, dailyFlex) : dailyFlex;

    // Trend line data (what if we keep growing at current pace without flex)
    final trendBalances = <int>[];
    var trendCum = _currentBalance;
    trendBalances.add(trendCum);

    const maxDays = 365;
    for (int i = 1; i <= maxDays; i++) {
      final day = today.add(Duration(days: i));
      if (day.weekday > 5) continue;
      projectedCum -= netChange;
      if (projectedCum <= 0) {
        allBalances.add(0);
        allLabels.add('${day.day}/${day.month}');
        break;
      }
      allBalances.add(projectedCum);
      if (i % 20 == 0) {
        allLabels.add('${day.day}/${day.month}');
      } else {
        allLabels.add('');
      }

      // Trend: add avg daily growth (shows where bank goes without flex)
      if (useTrend) {
        trendCum += avgDailyGrowth;
        trendBalances.add(trendCum);
      }
    }

    return _ProjectionData(
      allBalances: allBalances,
      allLabels: allLabels,
      splitIndex: splitIndex,
      trendBalances: useTrend ? trendBalances : null,
    );
  }

  String _computeZeroDate(int weeks) {
    if (weeks <= 0) return 'Already at zero!';
    final date = DateTime.now().add(Duration(days: weeks * 7));
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _ProjectionData {
  final List<int> allBalances;
  final List<String> allLabels;
  final int splitIndex; // index where projection begins
  final List<int>? trendBalances;

  const _ProjectionData({
    required this.allBalances,
    required this.allLabels,
    required this.splitIndex,
    this.trendBalances,
  });
}

