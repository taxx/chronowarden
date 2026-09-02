/// How this travel preset handles the commute to/from work.
enum CommuteMode {
  /// No public transit commute (e.g., working from home, walking distance).
  none,

  /// Uses public transit (train, bus, etc.) — enables transit integration.
  transit,

  /// Uses a personal vehicle — reserved for future car integration.
  car,

  /// Vespa scooter — coming soon!
  vespa,
}

/// A named commute / work-scenario preset. Maps to [travel_presets].
///
/// Stores morning and evening commute values separately instead of
/// dividing total values by 2. This supports asymmetrical commutes
/// (e.g., train to work, car home).
///
/// [commuteMode] is stored inside the encrypted_data blob alongside
/// the numeric commute fields. Defaults to [CommuteMode.none] for
/// backward compatibility with existing presets.
class TravelPreset {
  final String? id;
  final String? userId;
  final String name;
  final int morningOverheadMinutes;
  final int morningProductiveCommuteMinutes;
  final int eveningOverheadMinutes;
  final int eveningProductiveCommuteMinutes;
  final CommuteMode commuteMode;
  final String? createdAt;

  const TravelPreset({
    this.id,
    this.userId,
    required this.name,
    this.morningOverheadMinutes = 0,
    this.morningProductiveCommuteMinutes = 0,
    this.eveningOverheadMinutes = 0,
    this.eveningProductiveCommuteMinutes = 0,
    this.commuteMode = CommuteMode.none,
    this.createdAt,
  });

  /// Whether this preset uses transit — controls transit UI visibility.
  bool get usesTransit => commuteMode == CommuteMode.transit;

  /// Total overhead across both directions.
  int get defaultOverheadMinutes =>
      morningOverheadMinutes + eveningOverheadMinutes;

  /// Total productive commute across both directions.
  int get productiveCommuteMinutes =>
      morningProductiveCommuteMinutes + eveningProductiveCommuteMinutes;

  factory TravelPreset.fromJson(Map<String, dynamic> json) {
    // Parse commute mode from encrypted payload
    final commuteModeStr = json['commute_mode'] as String?;
    final commuteMode = _parseCommuteMode(commuteModeStr);

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
        commuteMode: commuteMode,
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
      commuteMode: commuteMode,
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
      'commute_mode': commuteMode.name,
      // Legacy total fields for backward compat
      'default_overhead_minutes': defaultOverheadMinutes,
      'productive_commute_minutes': productiveCommuteMinutes,
      'created_at': createdAt,
    };
  }

  TravelPreset copyWith({
    String? name,
    int? morningOverheadMinutes,
    int? morningProductiveCommuteMinutes,
    int? eveningOverheadMinutes,
    int? eveningProductiveCommuteMinutes,
    CommuteMode? commuteMode,
  }) {
    return TravelPreset(
      id: id,
      userId: userId,
      name: name ?? this.name,
      morningOverheadMinutes: morningOverheadMinutes ?? this.morningOverheadMinutes,
      morningProductiveCommuteMinutes: morningProductiveCommuteMinutes ?? this.morningProductiveCommuteMinutes,
      eveningOverheadMinutes: eveningOverheadMinutes ?? this.eveningOverheadMinutes,
      eveningProductiveCommuteMinutes: eveningProductiveCommuteMinutes ?? this.eveningProductiveCommuteMinutes,
      commuteMode: commuteMode ?? this.commuteMode,
      createdAt: createdAt,
    );
  }

  @override
  String toString() =>
      'TravelPreset($name: '
      'morning ${morningOverheadMinutes}o/${morningProductiveCommuteMinutes}p, '
      'evening ${eveningOverheadMinutes}o/${eveningProductiveCommuteMinutes}p, '
      'mode=$commuteMode)';

  static CommuteMode _parseCommuteMode(String? value) {
    switch (value) {
      case 'transit':
        return CommuteMode.transit;
      case 'car':
        return CommuteMode.car;
      case 'vespa':
        return CommuteMode.vespa;
      default:
        return CommuteMode.none;
    }
  }
}
