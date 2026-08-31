/// Per-user transit integration preferences.
///
/// Stored as encrypted JSON inside [user_settings.encrypted_data]
/// under the key "transit_config". Zero-knowledge like all other
/// encrypted data in ChronoWarden.
class TransitConfig {
  final bool enabled;
  final int departureSiteId;
  final String departureSiteName;
  final int destinationSiteId;
  final String destinationSiteName;
  final int walkMinutesToStation;
  final int walkMinutesFromStation;
  final List<String> lineFilter;

  const TransitConfig({
    this.enabled = false,
    this.departureSiteId = 9600, // Stockholms Östra
    this.departureSiteName = 'Stockholms Östra',
    this.destinationSiteId = 0,
    this.destinationSiteName = '',
    this.walkMinutesToStation = 5,
    this.walkMinutesFromStation = 5,
    this.lineFilter = const [],
  });

  bool get hasDestination => destinationSiteId > 0 && destinationSiteName.isNotEmpty;

  bool get hasLineFilter => lineFilter.isNotEmpty;

  factory TransitConfig.fromJson(Map<String, dynamic> json) {
    final lineFilterRaw = json['line_filter'] as List<dynamic>?;
    final lineFilter = lineFilterRaw == null
        ? <String>[]
        : lineFilterRaw.map((e) => e as String).toList();

    return TransitConfig(
      enabled: json['enabled'] as bool? ?? false,
      departureSiteId: json['departure_site_id'] as int? ?? 9600,
      departureSiteName: json['departure_site_name'] as String? ?? 'Stockholms Östra',
      destinationSiteId: json['destination_site_id'] as int? ?? 0,
      destinationSiteName: json['destination_site_name'] as String? ?? '',
      walkMinutesToStation: json['walk_minutes_to_station'] as int? ?? 5,
      walkMinutesFromStation: json['walk_minutes_from_station'] as int? ?? 5,
      lineFilter: lineFilter,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'departure_site_id': departureSiteId,
      'departure_site_name': departureSiteName,
      'destination_site_id': destinationSiteId,
      'destination_site_name': destinationSiteName,
      'walk_minutes_to_station': walkMinutesToStation,
      'walk_minutes_from_station': walkMinutesFromStation,
      'line_filter': lineFilter,
    };
  }

  TransitConfig copyWith({
    bool? enabled,
    int? departureSiteId,
    String? departureSiteName,
    int? destinationSiteId,
    String? destinationSiteName,
    int? walkMinutesToStation,
    int? walkMinutesFromStation,
    List<String>? lineFilter,
  }) {
    return TransitConfig(
      enabled: enabled ?? this.enabled,
      departureSiteId: departureSiteId ?? this.departureSiteId,
      departureSiteName: departureSiteName ?? this.departureSiteName,
      destinationSiteId: destinationSiteId ?? this.destinationSiteId,
      destinationSiteName: destinationSiteName ?? this.destinationSiteName,
      walkMinutesToStation: walkMinutesToStation ?? this.walkMinutesToStation,
      walkMinutesFromStation: walkMinutesFromStation ?? this.walkMinutesFromStation,
      lineFilter: lineFilter ?? this.lineFilter,
    );
  }

  @override
  String toString() =>
      'TransitConfig(enabled: $enabled, departure: $departureSiteName ($departureSiteId), '
      'destination: ${hasDestination ? "$destinationSiteName ($destinationSiteId)" : "none"}, '
      'walk to: ${walkMinutesToStation}min, walk from: ${walkMinutesFromStation}min)';
}
