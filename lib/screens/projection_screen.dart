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
    final projection = _computeProjection(_dailyFlex);
    final balanceStr = _formatMinutes(_currentBalance);
    final reductionPerWeek = _dailyFlex * 5;
    final weeksToZero = _currentBalance <= 0 || _dailyFlex <= 0
        ? 0
        : (_currentBalance / (_dailyFlex * 5)).ceil();
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
                Text('Daily flex target', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Minutes to take from the bank each workday.',
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
                _statRow(theme, 'Weekly reduction', _formatMinutes(-_dailyFlex * 5)),
                _statRow(theme, 'Weeks to zero', '$weeksToZero weeks'),
                _statRow(theme, 'Estimated zero date', zeroDate),
                if (_dailyFlex > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Taking $_dailyFlex min per workday, your bank of $balanceStr\n'
                    'will reach zero in ~$weeksToZero weeks ($zeroDate).',
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
                      historicalBalances: projection.historicalBalances,
                      historicalLabels: projection.historicalLabels,
                      projectedBalances: projection.projectedBalances,
                      projectedLabels: projection.projectedLabels,
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

  _ProjectionData _computeProjection(int dailyFlex) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Sort logs by date, compute cumulative balance
    final sorted = _allLogs.where((l) => l.endTime != null).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final historicalBalances = <int>[];
    final historicalLabels = <String>[];
    var cum = 0;
    for (final l in sorted) {
      cum += l.overtimeMinutes;
      historicalBalances.add(cum);
      // Label every 5th entry or first/last
      if (historicalBalances.length == 1 ||
          historicalBalances.length == sorted.length ||
          historicalBalances.length % 5 == 0) {
        // Use month-day label
        final d = DateTime.parse(l.date);
        historicalLabels.add('${d.day}/${d.month}');
      } else {
        historicalLabels.add('');
      }
    }

    // Projection: from today forward, reduce by flex per workday
    final projectedBalances = <int>[];
    final projectedLabels = <String>[];
    var projectedCum = _currentBalance;

    // Add today's actual balance as the starting point
    projectedBalances.add(projectedCum);
    projectedLabels.add('now');

    // Count forward up to 52 weeks (max projection horizon)
    const maxDays = 365;
    for (int i = 1; i <= maxDays; i++) {
      final day = today.add(Duration(days: i));
      // Skip weekends — 5-day workweek
      if (day.weekday > 5) continue;
      projectedCum -= dailyFlex;
      if (projectedCum <= 0) {
        projectedBalances.add(0);
        projectedLabels.add('${day.day}/${day.month}');
        break;
      }
      projectedBalances.add(projectedCum);
      // Label every ~20th data point
      if (i % 20 == 0 || projectedCum <= 0) {
        projectedLabels.add('${day.day}/${day.month}');
      } else {
        projectedLabels.add('');
      }
    }

    return _ProjectionData(
      historicalBalances: historicalBalances,
      historicalLabels: historicalLabels,
      projectedBalances: projectedBalances,
      projectedLabels: projectedLabels,
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
  final List<int> historicalBalances;
  final List<String> historicalLabels;
  final List<int> projectedBalances;
  final List<String> projectedLabels;

  const _ProjectionData({
    required this.historicalBalances,
    required this.historicalLabels,
    required this.projectedBalances,
    required this.projectedLabels,
  });
}

// ---------------------------------------------------------------------------
// Chart painter — two lines: historical (green) + projected (blue)
// ---------------------------------------------------------------------------

class _ProjectionChartPainter extends CustomPainter {
  final List<int> historicalBalances;
  final List<String> historicalLabels;
  final List<int> projectedBalances;
  final List<String> projectedLabels;
  final Color greenColor;
  final Color blueColor;
  final Color gridColor;

  _ProjectionChartPainter({
    required this.historicalBalances,
    required this.historicalLabels,
    required this.projectedBalances,
    required this.projectedLabels,
    required this.greenColor,
    required this.blueColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (historicalBalances.isEmpty && projectedBalances.isEmpty) return;

    // Combine all data for Y-axis range
    final allBalances = [...historicalBalances, ...projectedBalances];
    final max = allBalances.reduce((a, b) => a > b ? a : b).toDouble();
    final min = allBalances.reduce((a, b) => a < b ? a : b).toDouble();
    final range = (max - min).clamp(1.0, double.infinity);

    const leftPad = 44.0;
    const bottomPad = 18.0;
    const topPad = 8.0;
    const rightPad = 12.0;

    final graphWidth = size.width - leftPad - rightPad;
    final graphHeight = size.height - topPad - bottomPad;

    double yOf(double v) => topPad + graphHeight - ((v - min) / range) * graphHeight;

    // ---- Grid lines ----
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = topPad + (graphHeight * i / 4);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);
    }

    // ---- Draw historical line (green) ----
    if (historicalBalances.length >= 2) {
      final stepX = graphWidth / (historicalBalances.length - 1).clamp(1, double.infinity);
      final path = Path();
      for (int i = 0; i < historicalBalances.length; i++) {
        final x = leftPad + i * stepX;
        final y = yOf(historicalBalances[i].toDouble());
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, Paint()
        ..color = greenColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round);
    }

    // ---- Draw projected line (blue) ----
    if (projectedBalances.length >= 2) {
      final stepX = graphWidth / (projectedBalances.length - 1).clamp(1, double.infinity);
      final path = Path();
      for (int i = 0; i < projectedBalances.length; i++) {
        final x = leftPad + i * stepX;
        final y = yOf(projectedBalances[i].toDouble());
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, Paint()
        ..color = blueColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke);
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

    final mid = (min + max) / 2;
    drawYLabel(_minLabel(max, min, max), topPad);
    drawYLabel(_minLabel(max, min, mid), topPad + graphHeight / 2);
    drawYLabel(_minLabel(max, min, min), topPad + graphHeight);

    // ---- X-axis labels (historical) ----
    if (historicalLabels.isNotEmpty && historicalBalances.length >= 2) {
      final stepX = graphWidth / (historicalBalances.length - 1).clamp(1, double.infinity);
      for (int i = 0; i < historicalLabels.length; i++) {
        final label = historicalLabels[i];
        if (label.isEmpty) continue;
        final tp = TextPainter(
          text: TextSpan(text: label, style: TextStyle(fontSize: 10, color: gridColor)),
          textDirection: TextDirection.ltr,
        )..layout();
        final x = (leftPad + i * stepX - tp.width / 2).clamp(leftPad, size.width - rightPad - tp.width);
        tp.paint(canvas, Offset(x, size.height - bottomPad + 4));
      }
    }

    // ---- X-axis labels (projected) ----
    if (projectedLabels.isNotEmpty && projectedBalances.length >= 2) {
      final stepX = graphWidth / (projectedBalances.length - 1).clamp(1, double.infinity);
      for (int i = 0; i < projectedLabels.length; i++) {
        final label = projectedLabels[i];
        if (label.isEmpty) continue;
        final tp = TextPainter(
          text: TextSpan(text: label, style: TextStyle(fontSize: 10, color: blueColor)),
          textDirection: TextDirection.ltr,
        )..layout();
        final x = (leftPad + i * stepX - tp.width / 2).clamp(leftPad, size.width - rightPad - tp.width);
        tp.paint(canvas, Offset(x, size.height - bottomPad + 14));
      }
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
