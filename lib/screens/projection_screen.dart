import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/time_log.dart';
import '../models/work_period_setting.dart';

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
  late List<WorkPeriodSetting> _workPeriods;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _state.refresh();
    if (mounted) setState(() {
      _currentBalance = _state.timeBankMinutes;
      _allLogs = _state.allLogs;
      _workPeriods = _state.workPeriods;
      _loading = false;
    });
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
          _workPeriods = _state.workPeriods;
          return _buildContent(theme);
        },
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final projection = _computeProjection(_dailyFlex, _useTrend);
    final balanceStr = _formatMinutes(_currentBalance);
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
                      ? 'Minutes to take from the bank each workday.\nTrend adjusts for your avg growth (${_formatMinutes(avgGrowth)}/week).'
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
                  _statRow(theme, 'Avg growth rate', '${_formatMinutes(avgGrowth)}/week'),
                  _statRow(theme, 'Net weekly change', _formatMinutes(-effectiveWeekly)),
                ],
                _statRow(theme, 'Weekly reduction', _formatMinutes(-effectiveWeekly)),
                _statRow(theme, 'Weeks to zero', '$weeksToZero weeks'),
                _statRow(theme, 'Estimated zero date', zeroDate),
                if (effectiveFlex > 0) ...[  
                  const SizedBox(height: 8),
                  Text(
                    _useTrend
                        ? 'Taking $_dailyFlex min flex per workday (net ${_formatMinutes(-effectiveWeekly)}/week after avg growth of ${_formatMinutes(avgGrowth)}/week), your bank of $balanceStr will reach zero in ~$weeksToZero weeks ($zeroDate).'
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
                    painter: _ProjectionChartPainter(
                      balances: projection.allBalances,
                      labels: projection.allLabels,
                      splitIndex: projection.splitIndex,
                      greenColor: Colors.green.shade700,
                      blueColor: theme.colorScheme.primary,
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

  Widget _statRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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

    const maxDays = 365;
    for (int i = 1; i <= maxDays; i++) {
      final day = today.add(Duration(days: i));
      if (day.weekday > 5) continue;
      projectedCum -= dailyFlex;
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
    }

    return _ProjectionData(
      allBalances: allBalances,
      allLabels: allLabels,
      splitIndex: splitIndex,
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes == 0) return '0 min';
    final sign = minutes < 0 ? '-' : '';
    final abs = minutes.abs();
    final h = abs ~/ 60;
    final m = abs % 60;
    if (h == 0) return '$sign${m} min';
    if (m == 0) return '$sign${h}h';
    return '$sign${h}h ${m}m';
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

  const _ProjectionData({
    required this.allBalances,
    required this.allLabels,
    required this.splitIndex,
  });
}

// ---------------------------------------------------------------------------
// Chart painter — two lines: historical (green) + projected (blue)
// ---------------------------------------------------------------------------

class _ProjectionChartPainter extends CustomPainter {
  final List<int> balances;
  final List<String> labels;
  final int splitIndex;
  final Color greenColor;
  final Color blueColor;
  final Color? trendColor;
  final List<int>? trendBalances;
  final Color gridColor;

  _ProjectionChartPainter({
    required this.balances,
    required this.labels,
    required this.splitIndex,
    required this.greenColor,
    required this.blueColor,
    this.trendColor,
    this.trendBalances,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (balances.isEmpty) return;

    final max = balances.reduce((a, b) => a > b ? a : b).toDouble();
    final min = balances.reduce((a, b) => a < b ? a : b).toDouble();
    final range = (max - min).clamp(1.0, double.infinity);

    const leftPad = 44.0;
    const bottomPad = 18.0;
    const topPad = 8.0;
    const rightPad = 12.0;

    final graphWidth = size.width - leftPad - rightPad;
    final graphHeight = size.height - topPad - bottomPad;
    final stepX = graphWidth / (balances.length - 1).clamp(1, double.infinity);

    double yOf(double v) => topPad + graphHeight - ((v - min) / range) * graphHeight;

    // ---- Grid lines ----
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = topPad + (graphHeight * i / 4);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);
    }

    // ---- Single combined line (green → blue at splitIndex) ----
    if (balances.length >= 2) {
      final path = Path();
      for (int i = 0; i < balances.length; i++) {
        final x = leftPad + i * stepX;
        final y = yOf(balances[i].toDouble());
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      // Draw historical portion in green (up to splitIndex)
      if (splitIndex > 1) {
        final histPath = Path();
        for (int i = 0; i <= splitIndex && i < balances.length; i++) {
          final x = leftPad + i * stepX;
          final y = yOf(balances[i].toDouble());
          if (i == 0) histPath.moveTo(x, y);
          else histPath.lineTo(x, y);
        }
        canvas.drawPath(histPath, Paint()
          ..color = greenColor
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round);
      }

      // Draw projected portion in blue (from splitIndex)
      if (splitIndex < balances.length - 1) {
        final projPaint = Paint()
          ..color = blueColor
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round;
        final projPath = Path();
        for (int i = splitIndex; i < balances.length; i++) {
          final x = leftPad + i * stepX;
          final y = yOf(balances[i].toDouble());
          if (i == splitIndex) projPath.moveTo(x, y);
          else projPath.lineTo(x, y);
        }
        canvas.drawPath(projPath, projPaint);
        // Draw dots on each projected data point
        final dotPaint = Paint()
          ..color = blueColor
          ..style = PaintingStyle.fill;
        for (int i = splitIndex; i < balances.length; i++) {
          final x = leftPad + i * stepX;
          final y = yOf(balances[i].toDouble());
          canvas.drawCircle(Offset(x, y), 4, dotPaint);
        }
      }

      // ---- Trend line (orange, dashed) ----
      if (trendBalances != null && trendBalances!.length >= 2 && trendColor != null) {
        final trendPaint = Paint()
          ..color = trendColor!
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        final trendPath = Path();
        // Trend starts at splitIndex (same starting point as projection)
        for (int i = 0; i < trendBalances!.length; i++) {
          final idx = splitIndex + i;
          if (idx >= balances.length) break;
          final x = leftPad + idx * stepX;
          final y = yOf(trendBalances![i].toDouble());
          if (i == 0) trendPath.moveTo(x, y);
          else trendPath.lineTo(x, y);
        }
        canvas.drawPath(trendPath, trendPaint);
      }
    }

    // ---- Zero reference line (dashed) ----
    final zeroY = yOf(0).clamp(topPad, size.height - bottomPad);
    final dashPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.5;
    double x0 = leftPad;
    while (x0 < size.width - rightPad) {
      final x1 = (x0 + 6).clamp(leftPad, size.width - rightPad);
      canvas.drawLine(Offset(x0, zeroY), Offset(x1, zeroY), dashPaint);
      x0 = x1 + 4;
    }

    // ---- Y-axis labels ----
    void drawYLabel(String text, double y) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(fontSize: 10, color: gridColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 4, y - tp.height / 2));
    }

    drawYLabel(_minLabel(max, min, max), topPad);
    final mid = (min + max) / 2;
    drawYLabel(_minLabel(max, min, mid), topPad + graphHeight / 2);
    drawYLabel(_minLabel(max, min, min), topPad + graphHeight);

    // ---- X-axis labels ----
    for (int i = 0; i < labels.length; i++) {
      final label = labels[i];
      if (label.isEmpty) continue;
      final color = i < splitIndex ? gridColor : blueColor;
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(fontSize: 10, color: color)),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = (leftPad + i * stepX - tp.width / 2).clamp(leftPad, size.width - rightPad - tp.width);
      tp.paint(canvas, Offset(x, size.height - bottomPad + 4));
    }
  }

  String _minLabel(double max, double min, double v) {
    final mins = v.round();
    final sign = mins >= 0 ? '+' : '';
    final abs = mins.abs();
    final h = abs ~/ 60;
    final m = abs % 60;
    if (h == 0) return '$sign${m}min';
    if (m == 0) return '$sign${h}h';
    return '$sign${h}h${m}m';
  }

  @override
  bool shouldRepaint(covariant _ProjectionChartPainter oldDelegate) => true;
}
