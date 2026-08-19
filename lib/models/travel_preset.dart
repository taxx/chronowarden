/// A named commute / work-scenario preset. Maps to [travel_presets].
///
/// Stores morning and evening commute values separately instead of
/// dividing total values by 2. This supports asymmetrical commutes
/// (e.g., train to work, car home).
class TravelPreset {
  final String? id;
  final String? userId;
  final String name;
  final int morningOverheadMinutes;
  final int morningProductiveCommuteMinutes;
  final int eveningOverheadMinutes;
  final int eveningProductiveCommuteMinutes;
  final String? createdAt;

  const TravelPreset({
    this.id,
    this.userId,
    required this.name,
    this.morningOverheadMinutes = 0,
    this.morningProductiveCommuteMinutes = 0,
    this.eveningOverheadMinutes = 0,
    this.eveningProductiveCommuteMinutes = 0,
    this.createdAt,
  });

  /// Total overhead across both directions.
  int get defaultOverheadMinutes =>
      morningOverheadMinutes + eveningOverheadMinutes;

  /// Total productive commute across both directions.
  int get productiveCommuteMinutes =>
      morningProductiveCommuteMinutes + eveningProductiveCommuteMinutes;

  factory TravelPreset.fromJson(Map<String, dynamic> json) {
    // Try reading new per-direction fields first.
    final morningOverhead = json['morning_overhead_minutes'] as int?;
    final morningProductive = json['morning_productive_commute_minutes'] as int?;
    final eveningOverhead = json['evening_overhead_minutes'] as int?;
    final eveningProductive = json['evening_productive_commute_minutes'] as int?;

    if (morningOverhead != null && eveningOverhead != null) {
      // New format — use per-direction values directly.
      return TravelPreset(
        id: json['id'] as String?,
        userId: json['user_id'] as String?,
        name: json['name'] as String,
        morningOverheadMinutes: morningOverhead,
        morningProductiveCommuteMinutes: morningProductive ?? 0,
        eveningOverheadMinutes: eveningOverhead,
        eveningProductiveCommuteMinutes: eveningProductive ?? 0,
        createdAt: json['created_at'] as String?,
      );
    }

    // Legacy format — split total values 50/50 (rounding down for morning,
    // remainder for evening).
    final totalOverhead = json['default_overhead_minutes'] as int;
    final totalProductive = (json['productive_commute_minutes'] as int?) ?? 0;
    return TravelPreset(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      morningOverheadMinutes: totalOverhead ~/ 2,
      morningProductiveCommuteMinutes: totalProductive ~/ 2,
      eveningOverheadMinutes: totalOverhead - (totalOverhead ~/ 2),
      eveningProductiveCommuteMinutes: totalProductive - (totalProductive ~/ 2),
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      // New per-direction fields
      'morning_overhead_minutes': morningOverheadMinutes,
      'morning_productive_commute_minutes': morningProductiveCommuteMinutes,
      'evening_overhead_minutes': eveningOverheadMinutes,
      'evening_productive_commute_minutes': eveningProductiveCommuteMinutes,
      // Legacy total fields for backward compat
      'default_overhead_minutes': defaultOverheadMinutes,
      'productive_commute_minutes': productiveCommuteMinutes,
      'created_at': createdAt,
    };
  }

  @override
  String toString() =>
      'TravelPreset($name: '
      'morning ${morningOverheadMinutes}o/${morningProductiveCommuteMinutes}p, '
      'evening ${eveningOverheadMinutes}o/${eveningProductiveCommuteMinutes}p)';
}
