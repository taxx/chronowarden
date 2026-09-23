import 'dart:math';

import 'package:flutter/material.dart';

import '../models/period.dart';
import '../models/time_log.dart';
import '../services/preferences_service.dart';
import '../utils/format.dart';

// ---------------------------------------------------------------------------
// Time Bank Chart — deviation-from-baseline bar chart with cumulative overlay
// ---------------------------------------------------------------------------

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class TimeBankChart extends StatefulWidget {
  final List<TimeLog> logs;       // filtered logs for this period
  final List<TimeLog> allLogs;    // all logs (unfiltered) for baseline calc
  final Period period;
  final DateTime refDate;
  final bool showWeekends;

  const TimeBankChart({
    super.key,
    required this.logs,
    required this.allLogs,
    required this.period,
    required this.refDate,
    this.showWeekends = false,
  });

  @override
  State<TimeBankChart> createState() => _TimeBankChartState();
}

class _TimeBankChartState extends State<TimeBankChart> {
  final _prefs = PreferencesService();
  late bool _showTrend;

  @override
  void initState() {
    super.initState();
    _showTrend = _prefs.showTrend.value;
  }

  void _toggleTrend(bool v) {
    setState(() => _showTrend = v);
    _prefs.setShowTrend(v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = _buildData();
    if (data.deltas.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Time Bank', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text('Trend', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(width: 4),
                Switch(
                  value: _showTrend,
                  onChanged: _toggleTrend,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Daily overtime relative to your time bank — green bars mean you earned time back.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              width: double.infinity,
              child: CustomPaint(painter: _BarChartPainter(
                deltas: data.deltas,
                cumulative: data.cumulative,
                labels: data.labels,
                baseline: data.baseline,
                positiveBarColor: Colors.red.shade700,
                negativeBarColor: Colors.green.shade700,
                lineColor: data.netChange >= 0 ? Colors.red.shade700 : Colors.green.shade700,
                baselineColor: theme.colorScheme.onSurfaceVariant,
                gridColor: theme.dividerColor,
                labelColor: theme.dividerColor,
                isDark: isDark,
                showTrend: _showTrend,
              )),
            ),
            const SizedBox(height: 8),
            _balanceLabel(theme, data),
          ],
        ),
      ),
    );
  }

  Widget _balanceLabel(ThemeData theme, _ChartData data) {
    if (data.deltas.isEmpty) return const SizedBox.shrink();

    final baseline = data.baseline;
    final endBalance = data.cumulative.last;
    final netChange = endBalance - baseline;

    final baselineStr = formatMins(baseline);
    final endStr = formatMins(endBalance);
    final changeSign = netChange >= 0 ? '+' : '';
    final changeH = netChange.abs() ~/ 60;
    final changeM = netChange.abs() % 60;
    final changeStr = changeH > 0 ? '${changeH}h ${changeM}m' : '$changeM min';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Started with ', style: theme.textTheme.bodyMedium),
            Text(
              baselineStr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(' in the bank', style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Period total: ', style: theme.textTheme.bodySmall),
            Text(
              '$changeSign$changeStr',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: netChange >= 0 ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
            Icon(
              netChange >= 0 ? Icons.trending_up : Icons.trending_down,
              size: 16,
              color: netChange >= 0 ? Colors.red.shade700 : Colors.green.shade700,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Ends with ', style: theme.textTheme.bodySmall),
            Text(
              endStr,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  _ChartData _buildData() {
    final logByDate = <String, TimeLog>{};
    for (final l in widget.logs) {
      logByDate[l.date] = l;
    }

    switch (widget.period) {
      case Period.week:
        return _buildWeekData(logByDate);
      case Period.month:
        return _buildMonthData(logByDate);
      case Period.year:
        return _buildYearData(logByDate);
    }
  }

  /// Compute the time bank balance at the start of [periodStart].
  int _baselineBefore(DateTime periodStart) {
    int sum = 0;
    for (final l in widget.allLogs) {
      final date = DateTime.tryParse(l.date);
      if (date != null && date.isBefore(periodStart)) {
        sum += l.overtimeMinutes;
      }
    }
    return sum;
  }

  _ChartData _buildWeekData(Map<String, TimeLog> logByDate) {
    final weekStart = widget.refDate.subtract(Duration(days: widget.refDate.weekday - 1));
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final deltas = <int>[];
    final labels = <String>[];

    final baseline = _baselineBefore(weekStart);

    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      if (!widget.showWeekends && day.weekday > 5) continue;
      final dateStr = _dateStr(day);
      final log = logByDate[dateStr];
      if (log == null || log.endTime == null) continue;
      deltas.add(log.overtimeMinutes);
      labels.add(dayNames[i]);
    }

    return _ChartData(
      deltas: deltas,
      cumulative: _buildCumulative(baseline, deltas),
      labels: labels,
      baseline: baseline,
    );
  }

  _ChartData _buildMonthData(Map<String, TimeLog> logByDate) {
    final ref = DateTime(widget.refDate.year, widget.refDate.month, 1);
    final daysInMonth = DateTime(widget.refDate.year, widget.refDate.month + 1, 0).day;
    final deltas = <int>[];
    final labels = <String>[];

    final baseline = _baselineBefore(ref);

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(widget.refDate.year, widget.refDate.month, day);
      if (!widget.showWeekends && date.weekday > 5) continue;
      final dateStr = _dateStr(date);
      final log = logByDate[dateStr];
      if (log == null || log.endTime == null) continue;
      deltas.add(log.overtimeMinutes);
      // Label every 5th day or first/last
      if (day == 1 || day == daysInMonth || day % 5 == 0) {
        labels.add('$day');
      } else {
        labels.add('');
      }
    }

    return _ChartData(
      deltas: deltas,
      cumulative: _buildCumulative(baseline, deltas),
      labels: labels,
      baseline: baseline,
    );
  }

  _ChartData _buildYearData(Map<String, TimeLog> logByDate) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final deltas = <int>[];
    final labels = <String>[];

    final baseline = _baselineBefore(DateTime(widget.refDate.year, 1, 1));

    for (int i = 0; i < 12; i++) {
      final monthStr = '${widget.refDate.year}-${(i+1).toString().padLeft(2, '0')}';
      final logsThisMonth = logByDate.entries
          .where((e) => e.key.startsWith(monthStr))
          .map((e) => e.value)
          .toList();
      final monthOt = logsThisMonth.fold<int>(0, (s, l) => s + l.overtimeMinutes);
      deltas.add(monthOt);
      labels.add(months[i]);
    }

    return _ChartData(
      deltas: deltas,
      cumulative: _buildCumulative(baseline, deltas),
      labels: labels,
      baseline: baseline,
    );
  }

  /// Build cumulative running total starting from [baseline].
  List<int> _buildCumulative(int baseline, List<int> deltas) {
    final cum = <int>[];
    var running = baseline;
    for (final d in deltas) {
      running += d;
      cum.add(running);
    }
    return cum;
  }
}

class _ChartData {
  final List<int> deltas;          // per-period overtime (bar heights)
  final List<int> cumulative;      // running total for overlay line
  final List<String> labels;       // X-axis labels
  final int baseline;              // time bank at start of period

  int get netChange => cumulative.last - baseline;

  const _ChartData({
    required this.deltas,
    required this.cumulative,
    required this.labels,
    required this.baseline,
  });
}

// ---------------------------------------------------------------------------
// CustomPainter for the bar chart + cumulative trend line (optional dashed)
// ---------------------------------------------------------------------------

class _BarChartPainter extends CustomPainter {
  final List<int> deltas;
  final List<int> cumulative;
  final List<String> labels;
  final int baseline;
  final Color positiveBarColor;
  final Color negativeBarColor;
  final Color lineColor;
  final Color baselineColor;
  final Color gridColor;
  final Color labelColor;
  final bool isDark;
  final bool showTrend;

  _BarChartPainter({
    required this.deltas,
    required this.cumulative,
    required this.labels,
    required this.baseline,
    required this.positiveBarColor,
    required this.negativeBarColor,
    required this.lineColor,
    required this.baselineColor,
    required this.gridColor,
    required this.labelColor,
    this.isDark = false,
    this.showTrend = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (deltas.isEmpty) return;

    const leftPad = 44.0;
    const bottomPad = 18.0;
    const topPad = 8.0;
    const rightPad = 12.0;
    final barWidth = (size.width - leftPad - rightPad) / deltas.length * 0.6;

    final graphWidth = size.width - leftPad - rightPad;
    final graphHeight = size.height - topPad - bottomPad;
    final stepX = graphWidth / deltas.length;

    // ---- Determine Y range centered on baseline ----
    final maxBarDev = deltas.fold<double>(0, (s, d) => s > d.abs() ? s : d.abs().toDouble());
    double yRange;
    if (showTrend && cumulative.isNotEmpty) {
      // When trend is shown, scale to accommodate both bars and cumulative line
      final maxCumDev = cumulative.fold<double>(0, (s, v) {
        final dev = (v - baseline).abs().toDouble();
        return s > dev ? s : dev;
      });
      yRange = (maxBarDev > maxCumDev ? maxBarDev : maxCumDev).clamp(1.0, double.infinity) * 1.3;
    } else {
      yRange = maxBarDev.clamp(1.0, double.infinity) * 1.3;
    }
    final paddedRange = yRange;

    /// Maps a deviation value (relative to baseline) to pixel Y.
    /// deviation=0 → center of graph.
    double yOf(double deviation) {
      return topPad + graphHeight / 2 - (deviation / paddedRange) * graphHeight / 2;
    }

    final baselineY = yOf(0);

    // ---- Y-axis deviation labels ----
    void drawYLabel(String text, double y) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(fontSize: 10, color: labelColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 4, y - tp.height / 2));
    }

    final halfRange = (paddedRange / 2).round();
    final fullRange = paddedRange.round();
    drawYLabel('+${formatMins(fullRange)}', topPad);
    drawYLabel('+${formatMins(halfRange)}', topPad + graphHeight / 4);
    drawYLabel('0', baselineY);
    drawYLabel('-${formatMins(halfRange)}', topPad + graphHeight * 0.75);
    drawYLabel('-${formatMins(fullRange)}', topPad + graphHeight);

    // ---- Grid lines ----
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = topPad + (graphHeight * i / 4);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);
    }

    // ---- Baseline reference line (dashed) ----
    final dashPaint = Paint()
      ..color = baselineColor
      ..strokeWidth = 1.5;
    const dashWidth = 6.0;
    const gapWidth = 4.0;
    double x0 = leftPad;
    while (x0 < size.width - rightPad) {
      final x1 = (x0 + dashWidth).clamp(leftPad, size.width - rightPad);
      canvas.drawLine(Offset(x0, baselineY), Offset(x1, baselineY), dashPaint);
      x0 = x1 + gapWidth;
    }

    // ---- Baseline value label (top-left of dashed line) ----
    final baselineLabel = TextPainter(
      text: TextSpan(
        text: 'bank: ${formatMins(baseline)}',
        style: TextStyle(fontSize: 9, color: baselineColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    baselineLabel.paint(
      canvas,
      Offset(leftPad + 2, baselineY - baselineLabel.height - 2),
    );

    // ---- Bars ----
    for (int i = 0; i < deltas.length; i++) {
      final delta = deltas[i];
      final x = leftPad + i * stepX + (stepX - barWidth) / 2;
      final barHeight = (delta.abs().toDouble() / paddedRange) * graphHeight / 2;
      final yTop = delta >= 0
          ? baselineY - barHeight
          : baselineY;
      final yBottom = delta >= 0
          ? baselineY
          : baselineY + barHeight;

      final isPositive = delta > 0;
      final barColor = isPositive ? positiveBarColor : negativeBarColor;

      // Bar fill
      final barPaint = Paint()
        ..color = barColor.withValues(alpha: isDark ? 0.5 : 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTRB(x, yTop, x + barWidth, yBottom), barPaint);

      // Bar outline + top edge accent
      final outlinePaint = Paint()
        ..color = barColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRect(Rect.fromLTRB(x, yTop, x + barWidth, yBottom), outlinePaint);

      // Deviation label above/below bar
      final devLabel = TextPainter(
        text: TextSpan(
          text: delta >= 0 ? '+${formatMins(delta)}' : '-${formatMins(delta.abs())}',
          style: TextStyle(fontSize: 9, color: barColor, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final devY = delta >= 0
          ? yTop - devLabel.height - 2
          : yBottom + 2;
      final devX = x + (barWidth - devLabel.width) / 2;
      if (devY >= topPad && devY <= size.height - bottomPad) {
        devLabel.paint(canvas, Offset(
          devX.clamp(leftPad, size.width - rightPad - devLabel.width),
          devY,
        ));
      }
    }

    // ---- Cumulative trend line (dashed, no fill, only when showTrend is on) ----
    if (showTrend && cumulative.length > 1) {
      final trendPaint = Paint()
        ..color = lineColor.withValues(alpha: isDark ? 0.6 : 0.7)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;

      // Draw dashed line connecting cumulative points
      const dashLen = 8.0;
      const gapLen = 5.0;

      for (int i = 0; i < cumulative.length; i++) {
        if (i == 0) continue;
        final x1 = leftPad + (i - 1) * stepX + stepX / 2;
        final y1 = yOf((cumulative[i - 1] - baseline).toDouble());
        final x2 = leftPad + i * stepX + stepX / 2;
        final y2 = yOf((cumulative[i] - baseline).toDouble());

        // Dash the segment between (x1,y1) and (x2,y2)
        final dx = x2 - x1;
        final dy = y2 - y1;
        final length = sqrt(dx * dx + dy * dy);
        final steps = (length / (dashLen + gapLen)).ceil().clamp(1, 100);

        for (int s = 0; s < steps; s++) {
          final t = s / steps;
          final tNext = (s + 0.5) / steps;
          final sx1 = x1 + dx * t;
          final sy1 = y1 + dy * t;
          final sx2 = x1 + dx * tNext;
          final sy2 = y1 + dy * tNext;
          if (s % 2 == 0) {
            canvas.drawLine(Offset(sx1, sy1), Offset(sx2, sy2), trendPaint);
          }
        }
      }

      // Small translucent dots at each cumulative point
      final dotPaint = Paint()
        ..color = lineColor.withValues(alpha: isDark ? 0.5 : 0.4)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < cumulative.length; i++) {
        final x = leftPad + i * stepX + stepX / 2;
        final devFromBaseline = (cumulative[i] - baseline).toDouble();
        final y = yOf(devFromBaseline);
        canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
      }
    }

    // ---- X-axis labels ----
    for (int i = 0; i < labels.length; i++) {
      final label = labels[i];
      if (label.isEmpty) continue;
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(fontSize: 10, color: labelColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = (leftPad + i * stepX + stepX / 2 - tp.width / 2)
          .clamp(leftPad, size.width - rightPad - tp.width);
      tp.paint(canvas, Offset(x, size.height - bottomPad + 4));
    }
  }


  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => true;
}
