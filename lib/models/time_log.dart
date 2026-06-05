/// A single workday log entry. Maps to the [time_logs] table.
///
/// The core model behind ChronoWarden's two UX states:
///   • *Morning Calculator* — project leave time from [startTime],
///     [expectedMinutes] and [overheadMinutes].
///   • *Afternoon Logger* — compute [overtimeMinutes] once [endTime] is set.
class TimeLog {
  final String id;
  final String userId;
  final String date; // "YYYY-MM-DD"
  final String startTime; // "HH:MM:SS"
  final String? endTime;  // "HH:MM:SS" — null while the day is active
  final int overheadMinutes;
  final int expectedMinutes;
  final int overtimeMinutes;
  final String? note;
  final String createdAt;

  const TimeLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.overheadMinutes,
    required this.expectedMinutes,
    required this.overtimeMinutes,
    this.note,
    required this.createdAt,
  });

  // ------------------------------------------------------------------
  // JSON factories (snake_case ↔ camelCase)
  // ------------------------------------------------------------------

  factory TimeLog.fromJson(Map<String, dynamic> json) {
    return TimeLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: json['date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String?,
      overheadMinutes: json['overhead_minutes'] as int,
      expectedMinutes: json['expected_minutes'] as int,
      overtimeMinutes: json['overtime_minutes'] as int,
      note: json['note'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'overhead_minutes': overheadMinutes,
      'expected_minutes': expectedMinutes,
      'overtime_minutes': overtimeMinutes,
      'note': note,
      'created_at': createdAt,
    };
  }

  // ------------------------------------------------------------------
  // Parsing helpers
  // ------------------------------------------------------------------

  /// Combine [date] + [startTime] into a single local [DateTime].
  /// Anchored to a neutral epoch so DST boundaries cannot corrupt the
  /// wall-clock arithmetic we rely on for leave-time projection.
  DateTime get _dayStart => _combineDateAndTime(date, startTime);

  /// Combine [date] + [endTime] into a single local [DateTime] (if set).
  DateTime? get _dayEnd => endTime == null
      ? null
      : _combineDateAndTime(date, endTime!);

  /// Merge a date string ("YYYY-MM-DD") and a time string ("HH:MM:SS")
  /// into a single [DateTime] in the local timezone.
  static DateTime _combineDateAndTime(String dateStr, String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final second = parts.length > 2 ? int.parse(parts[2].split('.').first) : 0;
    final date = DateTime.parse(dateStr);
    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
      second,
    );
  }

  // ------------------------------------------------------------------
  // Core calculations
  // ------------------------------------------------------------------

  /// **Morning Calculator** — Given the workday's exact start [DateTime],
  /// return the precise wall-clock moment the user is free to log off.
  ///
  /// Formula: `[dayStart] + expectedMinutes + overheadMinutes`
  ///
  /// Uses pure `Duration` arithmetic on the supplied [dayStart], so the
  /// result is always in the user's local wall-clock time.
  DateTime calculateLeaveTime(DateTime dayStart) {
    return dayStart.add(
      Duration(minutes: expectedMinutes + overheadMinutes),
    );
  }

  /// **Afternoon Logger** — Calculate the net overtime (or undertime) in
  /// minutes by comparing the actual elapsed time against the expected
  /// total (expected + overhead).
  ///
  /// Positive = overtime worked, negative = left early (time bank credit).
  /// Returns `0` if [endTime] has not yet been set.
  int calculateOvertimeMinutes() {
    if (endTime == null) return 0;

    final start = _dayStart;
    final end = _dayEnd!;
    final actualMinutes = end.difference(start).inMinutes;
    final totalExpected = expectedMinutes + overheadMinutes;

    return actualMinutes - totalExpected;
  }

  /// Total minutes the user is expected to spend (work + overhead).
  int get totalExpectedMinutes => expectedMinutes + overheadMinutes;

  /// Human-readable label for the overtime status.
  String get overtimeLabel {
    if (endTime == null) return '— working —';
    final mins = overtimeMinutes;
    if (mins == 0) return '✓ Exactly on target';
    if (mins > 0) return '+${mins} min overtime';
    return '${mins} min early';
  }

  @override
  String toString() =>
      'TimeLog($date, $startTime${endTime != null ? ' → $endTime' : ''}, '
      'overtime: ${overtimeLabel})';
}
