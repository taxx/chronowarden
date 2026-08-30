/// A single SL transport site from the SL Site API.
///
/// Maps to the JSON returned by:
///   GET /v1/sites
class StationInfo {
  final int id;
  final String name;

  const StationInfo({
    required this.id,
    required this.name,
  });

  factory StationInfo.fromJson(Map<String, dynamic> json) {
    // The API returns id as int or string; handle both.
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
      id: id,
      name: json['name'] as String? ??
          json['SiteName'] as String? ??
          'Unknown',
    );
  }

  @override
  String toString() => '$name ($id)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StationInfo && id == other.id && name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
