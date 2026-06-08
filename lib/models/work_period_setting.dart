/// Settings defining a seasonal work period. Maps to [work_period_settings].
class WorkPeriodSetting {
  final String? id;
  final String? userId;
  final String name;
  final String startDate; // "YYYY-MM-DD"
  final String endDate;   // "YYYY-MM-DD"
  final int expectedMinutes;
  final String? createdAt;

  const WorkPeriodSetting({
    this.id,
    this.userId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.expectedMinutes,
    this.createdAt,
  });

  factory WorkPeriodSetting.fromJson(Map<String, dynamic> json) {
    return WorkPeriodSetting(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      expectedMinutes: json['expected_minutes'] as int,
      createdAt: json['created_at'] as String?,
    );
  }

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

  bool isActiveOn(DateTime date) {
    final check = DateTime(date.year, date.month, date.day);
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    return check.isAfter(start.subtract(const Duration(days: 1))) &&
        check.isBefore(end.add(const Duration(days: 1)));
  }

  @override
  String toString() =>
      'WorkPeriodSetting($name: $expectedMinutes min, $startDate → $endDate)';
}
