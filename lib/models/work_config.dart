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
int isoWeekNumber(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);

  // Find the nearest Thursday (weekday 4)
  final wd = d.weekday; // 1=Mon ... 7=Sun
  final nearestThursday = d.add(Duration(days: (4 - wd + 7) % 7));

  // Year of the nearest Thursday
  final year = nearestThursday.year;

  // First Thursday of that year
  final firstJan = DateTime(year, 1, 1);
  final firstThursday = firstJan.add(Duration(
    days: (4 - firstJan.weekday + 7) % 7,
  ));

  // Difference in days → weeks
  final days = nearestThursday.difference(firstThursday).inDays;
  return (days ~/ 7) + 1;
}
