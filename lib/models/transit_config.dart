/// Per-user transit integration preferences.
///
/// Stored as encrypted JSON inside [user_settings.encrypted_data]
/// under the key "transit_config". Zero-knowledge like all other
/// encrypted data in ChronoWarden.
///
/// Fields are named "work" / "home" rather than "departure" / "destination"
/// for clarity. The direction depends on time of day (morning vs afternoon).
class TransitConfig {
  final bool enabled;
  final int workSiteId;
  final String workSiteName;
  final int homeSiteId;
  final String homeSiteName;
  final int walkHomeMinutes; // walking between home ↔ home station
  final int walkWorkMinutes; // walking between work station ↔ work
  final List<String> lineFilter;

  const TransitConfig({
    this.enabled = false,
    this.workSiteId = 9600, // Stockholms Östra
    this.workSiteName = 'Stockholms Östra',
    this.homeSiteId = 0,
    this.homeSiteName = '',
    this.walkHomeMinutes = 5,
    this.walkWorkMinutes = 5,
    this.lineFilter = const [],
  });

  bool get hasHome => homeSiteId > 0 && homeSiteName.isNotEmpty;
  bool get hasLineFilter => lineFilter.isNotEmpty;

  /// Total walking buffer for a given direction.
  /// Morning (home→work): walkHomeMinutes + walkWorkMinutes
  /// Afternoon (work→home): walkWorkMinutes + walkHomeMinutes
  int get totalWalkMinutes => walkHomeMinutes + walkWorkMinutes;

  factory TransitConfig.fromJson(Map<String, dynamic> json) {
    final lineFilterRaw = json['line_filter'] as List<dynamic>?;
    final lineFilter = lineFilterRaw == null
        ? <String>[]
        : lineFilterRaw.map((e) => e as String).toList();

    final workSiteId = json['work_site_id'] as int? ?? 9600;
    final workSiteName = json['work_site_name'] as String? ?? 'Stockholms Östra';
    final homeSiteId = json['home_site_id'] as int? ?? 0;
    final homeSiteName = json['home_site_name'] as String? ?? '';
    final walkHomeMinutes = json['walk_home_minutes'] as int? ?? 5;
    final walkWorkMinutes = json['walk_work_minutes'] as int? ?? 5;

    return TransitConfig(
      enabled: json['enabled'] as bool? ?? false,
      workSiteId: workSiteId,
      workSiteName: workSiteName,
      homeSiteId: homeSiteId,
      homeSiteName: homeSiteName,
      walkHomeMinutes: walkHomeMinutes,
      walkWorkMinutes: walkWorkMinutes,
      lineFilter: lineFilter,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'work_site_id': workSiteId,
      'work_site_name': workSiteName,
      'home_site_id': homeSiteId,
      'home_site_name': homeSiteName,
      'walk_home_minutes': walkHomeMinutes,
      'walk_work_minutes': walkWorkMinutes,
      'line_filter': lineFilter,
    };
  }

  TransitConfig copyWith({
    bool? enabled,
    int? workSiteId,
    String? workSiteName,
    int? homeSiteId,
    String? homeSiteName,
    int? walkHomeMinutes,
    int? walkWorkMinutes,
    List<String>? lineFilter,
  }) {
    return TransitConfig(
      enabled: enabled ?? this.enabled,
      workSiteId: workSiteId ?? this.workSiteId,
      workSiteName: workSiteName ?? this.workSiteName,
      homeSiteId: homeSiteId ?? this.homeSiteId,
      homeSiteName: homeSiteName ?? this.homeSiteName,
      walkHomeMinutes: walkHomeMinutes ?? this.walkHomeMinutes,
      walkWorkMinutes: walkWorkMinutes ?? this.walkWorkMinutes,
      lineFilter: lineFilter ?? this.lineFilter,
    );
  }

  @override
  String toString() =>
      'TransitConfig(enabled: $enabled, work: $workSiteName ($workSiteId), '
      'home: ${hasHome ? "$homeSiteName ($homeSiteId)" : "none"}, '
      'walk home: ${walkHomeMinutes}min, walk work: ${walkWorkMinutes}min'
      '${hasLineFilter ? ", lines: ${lineFilter.join(',')}" : ""})';
}
