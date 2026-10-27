/// Per-user work-time configuration. Stored as columns in [user_settings].
///
/// Replaces the old multiple-work-period model with a simpler system:
///   - [defaultExpectedMinutes] — always used unless...
///   - [reducedExpectedMinutes] — used when today's ISO week falls within
///     [reducedStartWeek] .. [reducedEndWeek].
class WorkConfig {
  final String? userId;
  final int defaultExpectedMinutes;
  final int? reducedExpectedMinutes;
  final int? reducedStartWeek;
  final int? reducedEndWeek;

  const WorkConfig({
    this.userId,
    required this.defaultExpectedMinutes,
    this.reducedExpectedMinutes,
    this.reducedStartWeek,
    this.reducedEndWeek,
  });

  bool get hasReducedPeriod =>
      reducedExpectedMinutes != null &&
      reducedStartWeek != null &&
      reducedEndWeek != null;

  /// Returns the expected minutes for [date] based on this config.
  ///
  /// If the ISO week of [date] falls within the reduced period, returns
  /// [reducedExpectedMinutes]; otherwise returns [defaultExpectedMinutes].
  int expectedMinutesForDate(DateTime date) {
    if (hasReducedPeriod) {
      final week = isoWeekNumber(date);
      if (week >= reducedStartWeek! && week <= reducedEndWeek!) {
        return reducedExpectedMinutes!;
      }
    }
    return defaultExpectedMinutes;
  }

  factory WorkConfig.fromJson(Map<String, dynamic> json) {
    return WorkConfig(
      userId: json['user_id'] as String?,
      defaultExpectedMinutes:
          (json['default_expected_minutes'] as int?) ?? 480,
      reducedExpectedMinutes: json['reduced_expected_minutes'] as int?,
      reducedStartWeek: json['reduced_start_week'] as int?,
      reducedEndWeek: json['reduced_end_week'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'default_expected_minutes': defaultExpectedMinutes,
      'reduced_expected_minutes': reducedExpectedMinutes,
      'reduced_start_week': reducedStartWeek,
      'reduced_end_week': reducedEndWeek,
    };
  }

  @override
  String toString() {
    if (!hasReducedPeriod) {
      return 'WorkConfig($defaultExpectedMinutes min default)';
    }
    return 'WorkConfig($defaultExpectedMinutes min default, '
        '$reducedExpectedMinutes min weeks $reducedStartWeek–$reducedEndWeek)';
  }
}

/// ISO week number for a given [date] (1–53).
///
/// Implements the standard algorithm: the week containing the first Thursday
/// of the year is week 1.
///
/// All arithmetic is done on [DateTime.utc] dates so that the day-count is
/// unaffected by Daylight Saving Time transitions (Europe/Sweden has DST),
/// which would otherwise skew the week number by ±1 for part of the year.
int isoWeekNumber(DateTime date) {
  final d = DateTime.utc(date.year, date.month, date.day);
  final wd = d.weekday; // 1=Mon ... 7=Sun

  // Thursday of the ISO week (Mon–Sun) that contains [d]. The offset must
  // go backwards for Fri/Sat/Sun, so it ranges −3..+3 days.
  final thu = DateTime.utc(d.year, d.month, d.day + ((4 - wd + 3) % 7 - 3));

  // ISO year of that week (may differ from the calendar year near Jan 1).
  final year = thu.year;

  // First Thursday of that calendar year (always within Jan 1..7).
  final jan1 = DateTime.utc(year, 1, 1);
  final firstThu = DateTime.utc(year, 1, 1 + ((4 - jan1.weekday + 7) % 7));

  // Difference in days → weeks
  final days = thu.difference(firstThu).inDays;
  return (days ~/ 7) + 1;
}
