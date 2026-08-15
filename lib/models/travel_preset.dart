/// A named commute / work-scenario preset. Maps to [travel_presets].
class TravelPreset {
  final String? id;
  final String? userId;
  final String name;
  final int defaultOverheadMinutes;
  final int productiveCommuteMinutes;
  final String? createdAt;

  const TravelPreset({
    this.id,
    this.userId,
    required this.name,
    required this.defaultOverheadMinutes,
    this.productiveCommuteMinutes = 0,
    this.createdAt,
  });

  factory TravelPreset.fromJson(Map<String, dynamic> json) {
    return TravelPreset(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      defaultOverheadMinutes: json['default_overhead_minutes'] as int,
      productiveCommuteMinutes: (json['productive_commute_minutes'] as int?) ?? 0,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'default_overhead_minutes': defaultOverheadMinutes,
      'productive_commute_minutes': productiveCommuteMinutes,
      'created_at': createdAt,
    };
  }

  @override
  String toString() =>
      'TravelPreset($name: ${defaultOverheadMinutes}min overhead, ${productiveCommuteMinutes}min productive commute)';
}
