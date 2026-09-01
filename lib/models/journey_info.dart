/// A slimmed journey from SL Journey Planner API.
///
/// This is the slimmed response from our edge function (sl-proxy),
/// which strips the verbose API response down to essential fields.
class JourneyInfo {
  final DateTime departureTime;
  final DateTime departureEstimated;
  final DateTime arrivalTime;
  final DateTime arrivalEstimated;
  final int durationMinutes;
  final int rtDurationMinutes;
  final List<LegInfo> legs;

  const JourneyInfo({
    required this.departureTime,
    required this.departureEstimated,
    required this.arrivalTime,
    required this.arrivalEstimated,
    required this.durationMinutes,
    required this.rtDurationMinutes,
    required this.legs,
  });

  /// The delay of the departure in minutes (0 = on time).
  int get departureDelayMinutes {
    final diff = departureEstimated.difference(departureTime).inMinutes;
    return diff > 0 ? diff : 0;
  }

  /// Human-readable delay label for the departure.
  String get delayLabel {
    final diff = departureDelayMinutes;
    if (diff <= 0) return 'On time';
    return '+$diff min';
  }

  /// Whether the departure is delayed (more than 0 min).
  bool get isDelayed => departureDelayMinutes > 0;

  /// Whether the arrival is delayed compared to planned.
  int get arrivalDelayMinutes {
    final diff = arrivalEstimated.difference(arrivalTime).inMinutes;
    return diff > 0 ? diff : 0;
  }

  /// The first transport leg's line number, if any.
  String? get mainLine {
    for (final leg in legs) {
      if (leg.type == LegType.transport && leg.line != null) {
        return leg.line;
      }
    }
    return null;
  }

  /// The first transport leg's destination, if any.
  String? get mainDestination {
    for (final leg in legs) {
      if (leg.type == LegType.transport && leg.destination != null) {
        return leg.destination;
      }
    }
    return null;
  }

  /// The first transport leg's platform, if any.
  String? get departurePlatform {
    for (final leg in legs) {
      if (leg.type == LegType.transport && leg.departurePlatform != null) {
        return leg.departurePlatform;
      }
    }
    return null;
  }

  /// The first transport leg's occupancy, if any.
  String? get occupancy {
    for (final leg in legs) {
      if (leg.type == LegType.transport && leg.occupancy != null) {
        return leg.occupancy;
      }
    }
    return null;
  }

  /// The first transport leg's transport mode, if any.
  String? get transportMode {
    for (final leg in legs) {
      if (leg.type == LegType.transport && leg.transportMode != null) {
        return leg.transportMode;
      }
    }
    return null;
  }

  factory JourneyInfo.fromJson(Map<String, dynamic> json) {
    final legsRaw = json['legs'] as List<dynamic>? ?? [];
    final legs = legsRaw
        .map((e) => LegInfo.fromJson(e as Map<String, dynamic>))
        .cast<LegInfo>()
        .toList();

    return JourneyInfo(
      departureTime: DateTime.parse(json['departure_time'] as String),
      departureEstimated: DateTime.parse(
          json['departure_estimated'] as String? ?? json['departure_time']),
      arrivalTime: DateTime.parse(json['arrival_time'] as String),
      arrivalEstimated: DateTime.parse(
          json['arrival_estimated'] as String? ?? json['arrival_time']),
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      rtDurationMinutes: json['rt_duration_minutes'] as int? ?? 0,
      legs: legs,
    );
  }

  @override
  String toString() =>
      'Journey(depart ${_fmtTime(departureTime)}, '
      'arrive ${_fmtTime(arrivalTime)}, '
      '${durationMinutes}min, '
      '${delayLabel})';

  static String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';  // ignore: unnecessary_brace_in_string_interps
}

/// A single leg in a journey — either transport or walking.
class LegInfo {
  final LegType type;
  final int durationMinutes;
  final String? line;
  final String? destination;
  final String? transportMode;
  final String? departurePlatform;
  final String? occupancy;
  final int? delayMinutes;

  const LegInfo({
    required this.type,
    required this.durationMinutes,
    this.line,
    this.destination,
    this.transportMode,
    this.departurePlatform,
    this.occupancy,
    this.delayMinutes,
  });

  /// Human-readable delay label.
  String? get delayLabel {
    final d = delayMinutes;
    if (d == null || d <= 0) return null;
    return '+$d min';
  }

  /// Whether this leg is a transport leg (not walking).
  bool get isTransport => type == LegType.transport;

  factory LegInfo.fromJson(Map<String, dynamic> json) {
    return LegInfo(
      type: LegType.fromString(json['type'] as String? ?? 'walk'),
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      line: json['line'] as String?,
      destination: json['destination'] as String?,
      transportMode: json['transport_mode'] as String?,
      departurePlatform: json['departure_platform'] as String?,
      occupancy: json['occupancy'] as String?,
      delayMinutes: json['delay_minutes'] as int?,
    );
  }

  @override
  String toString() =>
      'Leg($type ${durationMinutes}min${line != null ? ' $line' : ''})';
}

enum LegType { transport, walk;

  static LegType fromString(String value) {
    switch (value) {
      case 'transport':
        return LegType.transport;
      case 'walk':
        return LegType.walk;
      default:
        return LegType.walk;
    }
  }
}
