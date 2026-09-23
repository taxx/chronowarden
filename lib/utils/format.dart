/// Shared formatting helpers for minute values.
///
/// Centralised so every screen renders durations and overtime the same way.
/// All values are plain `int` minutes — conversion to display strings belongs
/// here in the presentation layer.
library;

/// Formats [minutes] as an unsigned magnitude: `45 min`, `8h 30m`, `8h`.
///
/// The sign is intentionally dropped; callers that need a sign prefix it
/// themselves (e.g. the edit-day "over/under" rows).
String formatMins(int minutes) {
  final abs = minutes.abs();
  final h = abs ~/ 60;
  final m = abs % 60;
  if (h == 0) return '$m min';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// Formats [minutes] as a signed duration without a leading `+`:
/// `8h 30m`, `8h`, `-45 min`, `0 min`.
String formatDurationMinutes(int minutes) {
  if (minutes == 0) return '0 min';
  final sign = minutes < 0 ? '-' : '';
  final abs = minutes.abs();
  final h = abs ~/ 60;
  final m = abs % 60;
  if (h == 0) return '$sign$m min';
  if (m == 0) return '$sign${h}h';
  return '$sign${h}h ${m}m';
}

/// Formats [minutes] as a signed balance with an explicit `+` for
/// non-negative values: `+8h 30m`, `+8h`, `-45 min`, `+0 min`.
String formatSignedMinutes(int minutes) {
  final sign = minutes >= 0 ? '+' : '-';
  final abs = minutes.abs();
  final h = abs ~/ 60;
  final m = abs % 60;
  if (h == 0) return '$sign$m min';
  if (m == 0) return '$sign${h}h';
  return '$sign${h}h ${m}m';
}

/// Label for an overtime status chip: `✓` when exactly on target, otherwise
/// the signed balance (e.g. `+8h 30m`).
String formatOvertimeStatus(int minutes) =>
    minutes == 0 ? '✓' : formatSignedMinutes(minutes);
