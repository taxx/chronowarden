/// Per-user transit integration preferences.
///
/// Stored as encrypted JSON inside [user_settings.encrypted_data]
/// under the key "transit_config". Zero-knowledge like all other
/// encrypted data in ChronoWarden.
///
/// Uses journey planner global IDs (strings like "9091001001009638")
/// for stop identification. The [workSiteId] / [homeSiteId] fields
/// are kept for backward compatibility with the SL Transport API
/// (departures endpoint) but are optional.
class TransitConfig {
  final bool enabled;
  final String workStopId;       // Journey planner global ID for work station
  final String workStopName;
  final String homeStopId;       // Journey planner global ID for home station
  final String homeStopName;
  final int workSiteId;          // SL Transport API site ID (optional, for departures)
  final int homeSiteId;          // SL Transport API site ID (optional, for departures)
  final int walkHomeMinutes;     // walking between home ↔ home station
  final int walkWorkMinutes;     // walking between work station ↔ work
  final int waitAtStationMinutes; // buffer: arrive at platform before departure

  const TransitConfig({
    this.enabled = false,
    this.workStopId = '',
    this.workStopName = '',
    this.homeStopId = '',
    this.homeStopName = '',
    this.workSiteId = 0,
    this.homeSiteId = 0,
    this.walkHomeMinutes = 5,
    this.walkWorkMinutes = 5,
    this.waitAtStationMinutes = 2,
  });

  bool get hasWork => workStopId.isNotEmpty && workStopName.isNotEmpty;
  bool get hasHome => homeStopId.isNotEmpty && homeStopName.isNotEmpty;

  /// Total walking buffer for a given direction.
  int get totalWalkMinutes => walkHomeMinutes + walkWorkMinutes;

  factory TransitConfig.fromJson(Map<String, dynamic> json) {
    return TransitConfig(
      enabled: json['enabled'] as bool? ?? false,
      workStopId: json['work_stop_id'] as String? ?? '',
      workStopName: json['work_stop_name'] as String? ?? '',
      homeStopId: json['home_stop_id'] as String? ?? '',
      homeStopName: json['home_stop_name'] as String? ?? '',
      workSiteId: json['work_site_id'] as int? ?? 0,
      homeSiteId: json['home_site_id'] as int? ?? 0,
      walkHomeMinutes: json['walk_home_minutes'] as int? ?? 5,
      walkWorkMinutes: json['walk_work_minutes'] as int? ?? 5,
      waitAtStationMinutes: json['wait_at_station_minutes'] as int? ?? 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'work_stop_id': workStopId,
      'work_stop_name': workStopName,
      'home_stop_id': homeStopId,
      'home_stop_name': homeStopName,
      'work_site_id': workSiteId,
      'home_site_id': homeSiteId,
      'walk_home_minutes': walkHomeMinutes,
      'walk_work_minutes': walkWorkMinutes,
      'wait_at_station_minutes': waitAtStationMinutes,
    };
  }

  TransitConfig copyWith({
    bool? enabled,
    String? workStopId,
    String? workStopName,
    String? homeStopId,
    String? homeStopName,
    int? workSiteId,
    int? homeSiteId,
    int? walkHomeMinutes,
    int? walkWorkMinutes,
    int? waitAtStationMinutes,
  }) {
    return TransitConfig(
      enabled: enabled ?? this.enabled,
      workStopId: workStopId ?? this.workStopId,
      workStopName: workStopName ?? this.workStopName,
      homeStopId: homeStopId ?? this.homeStopId,
      homeStopName: homeStopName ?? this.homeStopName,
      workSiteId: workSiteId ?? this.workSiteId,
      homeSiteId: homeSiteId ?? this.homeSiteId,
      walkHomeMinutes: walkHomeMinutes ?? this.walkHomeMinutes,
      walkWorkMinutes: walkWorkMinutes ?? this.walkWorkMinutes,
      waitAtStationMinutes: waitAtStationMinutes ?? this.waitAtStationMinutes,
    );
  }

  @override
  String toString() =>
      'TransitConfig(enabled: $enabled, '
      'work: $workStopName ($workStopId), '
      'home: ${hasHome ? "$homeStopName ($homeStopId)" : "none"}, '
      'walk home: ${walkHomeMinutes}min, walk work: ${walkWorkMinutes}min, '
      'wait station: ${waitAtStationMinutes}min)';
}
