/// Settings defining a seasonal work period (e.g. "Summer Time" with 435 min,
/// "Winter Time" with 480 min). Maps to the [work_period_settings] table.
class WorkPeriodSetting {
  final String id;
  final String userId;
  final String name;
  final String startDate; // "YYYY-MM-DD"
  final String endDate;   // "YYYY-MM-DD"
  final int expectedMinutes;
  final String createdAt;

  const WorkPeriodSetting({
    required this.id,
    required this.userId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.expectedMinutes,
    required this.createdAt,
  });

  /// Create from Supabase JSON (snake_case keys).
  factory WorkPeriodSetting.fromJson(Map<String, dynamic> json) {
    return WorkPeriodSetting(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      expectedMinutes: json['expected_minutes'] as int,
      createdAt: json['created_at'] as String,
    );
  }

  /// Serialise to Supabase JSON (snake_case keys).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'start_date': startDate,
      'end_date': endDate,
      'expected_minutes': expectedMinutes,
      'created_at': createdAt,
    };
  }

  /// Check whether a given date falls within this work period's range.
  bool isActiveOn(DateTime date) {
    final check = DateTime(date.year, date.month, date.monthDay);
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    return check.isAfter(start.subtract(const Duration(days: 1))) &&
        check.isBefore(end.add(const Duration(days: 1)));
  }

  @override
  String toString() =>
      'WorkPeriodSetting($name: $expectedMinutes min, $startDate → $endDate)';
}
