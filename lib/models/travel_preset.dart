/// A named commute / work-scenario preset (e.g. "Train via Mörby", "WFH")
/// that carries a default overhead buffer. Maps to the [travel_presets] table.
class TravelPreset {
  final String id;
  final String userId;
  final String name;
  final int defaultOverheadMinutes;
  final String createdAt;

  const TravelPreset({
    required this.id,
    required this.userId,
    required this.name,
    required this.defaultOverheadMinutes,
    required this.createdAt,
  });

  /// Create from Supabase JSON (snake_case keys).
  factory TravelPreset.fromJson(Map<String, dynamic> json) {
    return TravelPreset(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      defaultOverheadMinutes: json['default_overhead_minutes'] as int,
      createdAt: json['created_at'] as String,
    );
  }

  /// Serialise to Supabase JSON (snake_case keys).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'default_overhead_minutes': defaultOverheadMinutes,
      'created_at': createdAt,
    };
  }

  @override
  String toString() =>
      'TravelPreset($name: $defaultOverheadMinutes min overhead)';
}
