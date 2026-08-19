/// A single workday log entry. Maps to the [time_logs] table.
///
/// Commute values (morningOverheadMinutes, eveningProductiveCommuteMinutes,
/// etc.) are stored per-direction so asymmetrical commutes are handled
/// correctly instead of dividing totals by 2.
class TimeLog {
  final String? id;
  final String? userId;
  final String date; // "YYYY-MM-DD"
  final String startTime; // "HH:MM:SS"
  final String? endTime;  // "HH:MM:SS" — null while the day is active
  final int expectedMinutes;
  final int lunchMinutes;
  final int morningOverheadMinutes;
  final int morningProductiveCommuteMinutes;
  final int eveningOverheadMinutes;
  final int eveningProductiveCommuteMinutes;
  final int overtimeMinutes;
  final String? note;
  final String? createdAt;

  const TimeLog({
    this.id,
    this.userId,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.expectedMinutes,
    this.lunchMinutes = 0,
    this.morningOverheadMinutes = 0,
    this.morningProductiveCommuteMinutes = 0,
    this.eveningOverheadMinutes = 0,
    this.eveningProductiveCommuteMinutes = 0,
    required this.overtimeMinutes,
    this.note,
    this.createdAt,
  });

  /// Total overhead across both directions (computed).
  int get overheadMinutes =>
      morningOverheadMinutes + eveningOverheadMinutes;

  /// Total productive commute across both directions (computed).
  int get productiveCommuteMinutes =>
      morningProductiveCommuteMinutes + eveningProductiveCommuteMinutes;

  // ------------------------------------------------------------------
  // JSON factories (snake_case ↔ camelCase)
  // ------------------------------------------------------------------

  factory TimeLog.fromJson(Map<String, dynamic> json) {
    // Try reading per-direction fields first.
    final morningOverhead = json['morning_overhead_minutes'] as int?;
    final morningProductive = json['morning_productive_commute_minutes'] as int?;
    final eveningOverhead = json['evening_overhead_minutes'] as int?;
    final eveningProductive = json['evening_productive_commute_minutes'] as int?;

    if (morningOverhead != null && eveningOverhead != null) {
      // New format — use per-direction values.
      return TimeLog(
        id: json['id'] as String?,
        userId: json['user_id'] as String?,
        date: json['date'] as String,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String?,
        expectedMinutes: json['expected_minutes'] as int,
        lunchMinutes: (json['lunch_minutes'] as int?) ?? 0,
        morningOverheadMinutes: morningOverhead,
        morningProductiveCommuteMinutes: morningProductive ?? 0,
        eveningOverheadMinutes: eveningOverhead,
        eveningProductiveCommuteMinutes: eveningProductive ?? 0,
        overtimeMinutes: json['overtime_minutes'] as int,
        note: json['note'] as String?,
        createdAt: json['created_at'] as String?,
      );
    }

    // Legacy format — split total values 50/50.
    final totalOverhead = json['overhead_minutes'] as int;
    final totalProductive = (json['productive_commute_minutes'] as int?) ?? 0;
    return TimeLog(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      date: json['date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String?,
      expectedMinutes: json['expected_minutes'] as int,
      lunchMinutes: (json['lunch_minutes'] as int?) ?? 0,
      morningOverheadMinutes: totalOverhead ~/ 2,
      morningProductiveCommuteMinutes: totalProductive ~/ 2,
      eveningOverheadMinutes: totalOverhead - (totalOverhead ~/ 2),
      eveningProductiveCommuteMinutes: totalProductive - (totalProductive ~/ 2),
      overtimeMinutes: json['overtime_minutes'] as int,
      note: json['note'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'expected_minutes': expectedMinutes,
      'lunch_minutes': lunchMinutes,
      // New per-direction fields
      'morning_overhead_minutes': morningOverheadMinutes,
      'morning_productive_commute_minutes': morningProductiveCommuteMinutes,
      'evening_overhead_minutes': eveningOverheadMinutes,
      'evening_productive_commute_minutes': eveningProductiveCommuteMinutes,
      // Legacy total fields for backward compat
      'overhead_minutes': overheadMinutes,
      'productive_commute_minutes': productiveCommuteMinutes,
      'overtime_minutes': overtimeMinutes,
      'note': note,
      'created_at': createdAt,
    };
  }

  // ------------------------------------------------------------------
  // Parsing helpers
  // ------------------------------------------------------------------

  /// Combine [date] + [startTime] into a single local [DateTime].
  DateTime get _dayStart => combineDateAndTime(date, startTime);

  /// Combine [date] + [endTime] into a single local [DateTime] (if set).
  DateTime? get _dayEnd => endTime == null
      ? null
      : combineDateAndTime(date, endTime!);

  /// Merge a date string ("YYYY-MM-DD") and a time string ("HH:MM:SS")
  /// into a single [DateTime] in the local timezone.
  static DateTime combineDateAndTime(String dateStr, String timeStr) {
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

  /// Convenience: same as [calculateLeaveTime] but derived from the stored
  /// [date] + [startTime] fields (no external [dayStart] argument needed).
  ///
  /// Formula: `[dayStart] + expectedMinutes + lunchMinutes
  ///          + morningOverheadMinutes - eveningProductiveCommuteMinutes`
  ///
  /// [morningOverheadMinutes] is added because the morning commute (walking)
  /// happens after startTime but before arriving at the office — it pushes
  /// office arrival later, so you leave later.
  ///
  /// [eveningProductiveCommuteMinutes] is subtracted because that work
  /// happens after leaving the office, so you can leave earlier.
  ///
  /// Does NOT include [eveningOverheadMinutes] — evening commute overhead
  /// happens after leaving, so it doesn't extend your office stay.
  DateTime get leaveTime {
    final start = combineDateAndTime(date, startTime);
    return start.add(Duration(
      minutes: expectedMinutes +
          lunchMinutes +
          morningOverheadMinutes -
          eveningProductiveCommuteMinutes,
    ));
  }

  /// Elapsed minutes from start → now (or end if closed).
  Duration get elapsed {
    final start = combineDateAndTime(date, startTime);
    final end = endTime != null
        ? combineDateAndTime(date, endTime!)
        : DateTime.now();
    return end.difference(start);
  }

  // ------------------------------------------------------------------
  // Core calculations
  // ------------------------------------------------------------------

  /// **Morning Calculator** — Given the workday's exact start [DateTime],
  /// return the precise wall-clock moment the user is free to log off.
  ///
  /// Formula: `[dayStart] + expectedMinutes + lunchMinutes
  ///          + morningOverheadMinutes - eveningProductiveCommuteMinutes`
  DateTime calculateLeaveTime(DateTime dayStart) {
    return dayStart.add(Duration(
      minutes: expectedMinutes +
          lunchMinutes +
          morningOverheadMinutes -
          eveningProductiveCommuteMinutes,
    ));
  }

  /// **Afternoon Logger** — Calculate the net overtime (or undertime) in
  /// minutes by comparing the actual elapsed time against the expected
  /// total (expected + total overhead).
  ///
  /// Positive = overtime worked, negative = left early (time bank credit).
  /// Returns `0` if [endTime] has not yet been set.
  int calculateOvertimeMinutes() {
    if (endTime == null) return 0;

    final start = _dayStart;
    final end = _dayEnd!;
    final actualMinutes = end.difference(start).inMinutes;
    final totalExpected = expectedMinutes + overheadMinutes;

    return actualMinutes - lunchMinutes - totalExpected;
  }

  /// Total minutes the user is expected to spend (work + total overhead).
  int get totalExpectedMinutes => expectedMinutes + overheadMinutes;

  /// Human-readable label for the overtime status.
  String get overtimeLabel {
    if (endTime == null) return '— working —';
    final mins = overtimeMinutes;
    if (mins == 0) return '✓ Exactly on target';
    if (mins > 0) return '+$mins min overtime';
    return '$mins min early';
  }

  /// Returns a copy of this log with the given fields replaced.
  TimeLog copyWith({
    String? id,
    String? userId,
    String? date,
    String? startTime,
    String? endTime,
    int? expectedMinutes,
    int? lunchMinutes,
    int? morningOverheadMinutes,
    int? morningProductiveCommuteMinutes,
    int? eveningOverheadMinutes,
    int? eveningProductiveCommuteMinutes,
    int? overtimeMinutes,
    int? productiveCommuteMinutes, // convenience: sets evening only
    String? note,
    String? createdAt,
  }) {
    return TimeLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      expectedMinutes: expectedMinutes ?? this.expectedMinutes,
      lunchMinutes: lunchMinutes ?? this.lunchMinutes,
      morningOverheadMinutes:
          morningOverheadMinutes ?? this.morningOverheadMinutes,
      morningProductiveCommuteMinutes:
          morningProductiveCommuteMinutes ??
              this.morningProductiveCommuteMinutes,
      eveningOverheadMinutes:
          eveningOverheadMinutes ?? this.eveningOverheadMinutes,
      eveningProductiveCommuteMinutes:
          eveningProductiveCommuteMinutes ??
              this.eveningProductiveCommuteMinutes,
      overtimeMinutes: overtimeMinutes ?? this.overtimeMinutes,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'TimeLog($date, $startTime${endTime != null ? ' → $endTime' : ''}, '
      'overtime: $overtimeLabel)';
}
