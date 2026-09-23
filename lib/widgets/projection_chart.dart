import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Chart painter — two lines: historical (green) + projected (blue)
// ---------------------------------------------------------------------------

class ProjectionChartPainter extends CustomPainter {
  final List<int> balances;
  final List<String> labels;
  final int splitIndex;
  final Color greenColor;
  final Color blueColor;
  final Color? trendColor;
  final List<int>? trendBalances;
  final Color gridColor;

  ProjectionChartPainter({
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

    // Include trend balances in Y-range so trend line stays visible
    final allForRange = [...balances, ...(trendBalances ?? [])];
    final max = allForRange.reduce((a, b) => a > b ? a : b).toDouble();
    final min = allForRange.reduce((a, b) => a < b ? a : b).toDouble();
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
          if (i == 0) {
            histPath.moveTo(x, y);
          } else {
            histPath.lineTo(x, y);
          }
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
          if (i == splitIndex) {
            projPath.moveTo(x, y);
          } else {
            projPath.lineTo(x, y);
          }
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

      // ---- Trend line (pink, drawn as segments) ----
      if (trendBalances != null && trendBalances!.length >= 2 && trendColor != null) {
        final trendPaint = Paint()
          ..color = trendColor!
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round;
        // Draw as individual line segments instead of a Path
        for (int i = 1; i < trendBalances!.length; i++) {
          final idx0 = splitIndex + (i - 1);
          final idx1 = splitIndex + i;
          if (idx1 >= balances.length) break;
          final x0 = leftPad + idx0 * stepX;
          final y0 = yOf(trendBalances![i - 1].toDouble());
          final x1 = leftPad + idx1 * stepX;
          final y1 = yOf(trendBalances![i].toDouble());
          canvas.drawLine(Offset(x0, y0), Offset(x1, y1), trendPaint);
        }
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
  bool shouldRepaint(covariant ProjectionChartPainter oldDelegate) => true;
}
