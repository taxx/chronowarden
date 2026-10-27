import 'journey_info.dart';

/// A journey the user has committed to ("pinned"), so it stays visible even
/// when the rolling 3-trip window from the API pushes it out of the response.
///
/// Stored in localStorage (per-device, ephemeral). Auto-expires when the day
/// ends, not at departure — the pinned trip stays visible all day even after
/// the departure time has passed.
class PinnedJourney {
  final String originId; // journey planner global ID of origin stop
  final String destId;   // journey planner global ID of destination stop
  final bool isMorning;  // direction this pin belongs to (home→work)
  final String line;     // line badge, used for matching
  final String destination; // destination name for display
  final DateTime departure; // LOCAL date + time-of-day of planned departure
  final int durationMinutes; // trip duration
  final String? transportMode;
  final String? departurePlatform;
  final String? occupancy;

  const PinnedJourney({
    required this.originId,
    required this.destId,
    required this.isMorning,
    required this.line,
    required this.destination,
    required this.departure,
    required this.durationMinutes,
    this.transportMode,
    this.departurePlatform,
    this.occupancy,
  });

  /// Natural key for matching against returned journeys.
  ///
  /// Match on the scheduled (planned) departure time-of-day + line + route,
  /// so real-time delays don't make the pin "slide" between trains.
  bool matches(JourneyInfo journey, String origin, String dest, bool morning) {
    if (originId != origin || destId != dest || isMorning != morning) {
      return false;
    }
    if (journey.mainLine != line) return false;
    final depLocal = journey.departureTime.toLocal();
    return depLocal.hour == departure.hour &&
        depLocal.minute == departure.minute;
  }

  /// Whether the pin has expired: the day on which the pin was made has ended.
  /// The pinned trip stays visible all day (even after departure) until the
  /// day ends or the user manually unpins it.
  bool get isExpired {
    final now = DateTime.now();
    final endOfDay = DateTime(departure.year, departure.month, departure.day + 1);
    return now.isAfter(endOfDay);
  }

  /// Build a synthetic [JourneyInfo] so the pinned card can be rendered even
  /// when the API no longer returns it in the current 3-trip window.
  JourneyInfo toJourneyInfo() {
    final dep = departure;
    final arr = dep.add(Duration(minutes: durationMinutes));
    return JourneyInfo(
      departureTime: dep,
      departureEstimated: dep,
      arrivalTime: arr,
      arrivalEstimated: arr,
      durationMinutes: durationMinutes,
      rtDurationMinutes: durationMinutes,
      legs: [
        LegInfo(type: LegType.walk, durationMinutes: 0),
        LegInfo(
          type: LegType.transport,
          durationMinutes: durationMinutes,
          line: line.isEmpty ? null : line,
          destination: destination == 'Unknown' ? null : destination,
          transportMode: transportMode,
          departurePlatform: departurePlatform,
          occupancy: occupancy,
        ),
      ],
    );
  }

  factory PinnedJourney.fromJson(Map<String, dynamic> json) {
    return PinnedJourney(
      originId: json['origin_id'] as String,
      destId: json['dest_id'] as String,
      isMorning: json['is_morning'] as bool? ?? false,
      line: json['line'] as String,
      destination: json['destination'] as String,
      departure: DateTime.parse(json['departure'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      transportMode: json['transport_mode'] as String?,
      departurePlatform: json['departure_platform'] as String?,
      occupancy: json['occupancy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'origin_id': originId,
      'dest_id': destId,
      'is_morning': isMorning,
      'line': line,
      'destination': destination,
      'departure': departure.toIso8601String(),
      'duration_minutes': durationMinutes,
      'transport_mode': transportMode,
      'departure_platform': departurePlatform,
      'occupancy': occupancy,
    };
  }
}
