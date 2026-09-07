import 'package:flutter/material.dart';

/// Returns a background tint color based on overtime minutes.
/// Positive overtime → red gradient (light → intense as minutes increase).
/// Negative overtime → green gradient (light → intense as minutes increase).
/// Zero → neutral / transparent.
Color overtimeBackground(int minutes, ThemeData theme) {
  if (minutes == 0) return Colors.transparent;
  final abs = minutes.abs();
  final isPositive = minutes > 0;
  final intensity = (abs / 120.0).clamp(0.0, 0.9);

  if (isPositive) {
    return Color.lerp(
      Colors.red.shade50.withValues(alpha: 0.15),
      Colors.red.shade800.withValues(alpha: 0.35),
      intensity,
    ) ?? Colors.red.shade50;
  } else {
    return Color.lerp(
      Colors.green.shade50.withValues(alpha: 0.15),
      Colors.green.shade800.withValues(alpha: 0.35),
      intensity,
    ) ?? Colors.green.shade50;
  }
}

/// Returns a foreground/text color for overtime display.
Color overtimeText(int minutes, ThemeData theme) {
  if (minutes == 0) return theme.colorScheme.onSurfaceVariant;
  final abs = minutes.abs();
  final isPositive = minutes > 0;
  final intensity = (abs / 120.0).clamp(0.0, 1.0);

  if (isPositive) {
    return Color.lerp(
      theme.colorScheme.primary,
      Colors.red.shade900,
      intensity,
    ) ?? theme.colorScheme.primary;
  } else {
    return Color.lerp(
      Colors.green.shade700,
      Colors.green.shade900,
      intensity,
    ) ?? Colors.green.shade700;
  }
}

/// Returns an icon color for overtime indicators.
Color overtimeIcon(int minutes, ThemeData theme) {
  if (minutes == 0) return theme.colorScheme.primary;
  if (minutes > 0) return Colors.red.shade700;
  return Colors.green.shade700;
}

/// Formats minutes to a compact string like "+1h 30min" or "-45min".
String formatOvertime(int minutes) {
  if (minutes == 0) return '✓';
  final sign = minutes > 0 ? '+' : '-';
  final abs = minutes.abs();
  final h = abs ~/ 60;
  final m = abs % 60;
  if (h == 0) return '$sign${m}min';
  return '$sign${h}h ${m}min';
}

/// Formats minutes to a readable balance string like "+1h 30m" or "-45m".
String formatBalance(int minutes) {
  final sign = minutes >= 0 ? '+' : '-';
  final abs = minutes.abs();
  final h = abs ~/ 60;
  final m = abs % 60;
  if (h == 0) return '$sign$m min';
  return '$sign${h}h ${m}m';
}
