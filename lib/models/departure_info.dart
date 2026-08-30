/// A single departure from SL Transport API.
///
/// Maps to the JSON returned by:
///   GET /v1/sites/{site_id}/departures
class DepartureInfo {
  final String destination;
  final DateTime scheduledTime;
  final DateTime? expectedTime;
  final String state; // "IN_TIME", "EXPECTED", "CANCELLED"
  final String? track;
  final String transportMode;
  final String? lineNumber;

  const DepartureInfo({
    required this.destination,
    required this.scheduledTime,
    this.expectedTime,
    required this.state,
    this.track,
    required this.transportMode,
    this.lineNumber,
  });

  /// Human-readable delay label.
  String get delayLabel {
    if (state == 'CANCELLED') return 'Cancelled';
    if (expectedTime == null) return 'On time';
    final diff = expectedTime!.difference(scheduledTime).inMinutes;
    if (diff <= 0) return 'On time';
    return '+$diff min';
  }

  /// True if this departure is relevant for Roslagsbanan
  /// (TRAM or TRAIN transport modes).
  bool get isRailRelevant =>
      transportMode == 'TRAM' || transportMode == 'TRAIN';

  /// Whether the departure has been cancelled.
  bool get isCancelled => state == 'CANCELLED';

  factory DepartureInfo.fromJson(Map<String, dynamic> json) {
    final scheduledStr = json['scheduledDateTime'] as String? ??
        json['scheduledTime'] as String?;
    final expectedStr = json['expectedDateTime'] as String? ??
        json['expectedTime'] as String?;

    return DepartureInfo(
      destination: json['destination'] as String? ?? 'Unknown',
      scheduledTime: DateTime.parse(scheduledStr ?? ''),
      expectedTime: expectedStr != null ? DateTime.parse(expectedStr) : null,
      state: json['state'] as String? ?? 'IN_TIME',
      track: json['track'] as String? ??
          json['platform'] as String?,
      transportMode: json['transportMode'] as String? ?? 'TRAM',
      lineNumber: json['lineNumber'] as String? ??
          json['line'] as String?,
    );
  }

  @override
  String toString() =>
      'Departure($destination at $scheduledTime, $delayLabel, '
      'track: $track, mode: $transportMode, line: $lineNumber)';
}
