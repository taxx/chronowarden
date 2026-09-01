/// A station/stop from SL APIs.
///
/// Can represent both:
/// - SL Transport API sites (int-based IDs like 9600)
/// - SL Journey Planner stops (string-based global IDs like "9091001001009638")
///
/// The [id] is stored as a string for flexibility. Use [siteId] for the
/// integer form when needed (departure API).
class StationInfo {
  final String id;
  final String name;
  final int? siteId; // Only populated for SL Transport API sites

  const StationInfo({
    required this.id,
    required this.name,
    this.siteId,
  });

  /// Construct from SL Transport API site JSON (int-based IDs).
  factory StationInfo.fromSiteJson(Map<String, dynamic> json) {
    final idRaw = json['id'] ?? json['SiteId'];
    int id;
    if (idRaw is int) {
      id = idRaw;
    } else if (idRaw is String) {
      id = int.parse(idRaw);
    } else {
      id = 0;
    }

    return StationInfo(
      id: id.toString(),
      name: json['name'] as String? ??
          json['SiteName'] as String? ??
          'Unknown',
      siteId: id > 0 ? id : null,
    );
  }

  /// Construct from SL Journey Planner stop-finder JSON.
  factory StationInfo.fromStopFinderJson(Map<String, dynamic> json) {
    return StationInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['disassembledName'] as String? ?? 'Unknown',
      siteId: _parseStopId(json),
    );
  }

  /// Parse the numeric stopId from journey planner properties.
  static int? _parseStopId(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>?;
    if (props == null) return null;
    final stopId = props['stopId'] as String?;
    if (stopId == null) return null;
    final parsed = int.tryParse(stopId);
    return parsed != null && parsed > 0 ? parsed : null;
  }

  @override
  String toString() => '$name ($id${siteId != null ? ', site=$siteId' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StationInfo && id == other.id && name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
