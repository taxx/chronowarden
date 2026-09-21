import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/journey_info.dart';
import '../models/pinned_journey.dart';
import '../models/transit_config.dart';

/// Stores the user's committed ("pinned") journey in localStorage.
///
/// Ephemeral, per-device, not encrypted (it is not secret data). Auto-expires
/// once the departure time has passed (or the day ends, whichever is first).
///
/// Exposes a [ChangeNotifier] so both the transit screen and the My Day card
/// rebuild when the pin changes.
class PinnedJourneyStore extends ChangeNotifier {
  PinnedJourneyStore._();
  static final PinnedJourneyStore _instance = PinnedJourneyStore._();
  factory PinnedJourneyStore() => _instance;

  static const _key = 'pinned_journey';

  PinnedJourney? _pinned;

  /// The currently pinned journey, or null.
  PinnedJourney? get pinned => _pinned;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _pinned = null;
      notifyListeners();
      return;
    }
    try {
      final pin = PinnedJourney.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (pin.isExpired) {
        _pinned = null;
        await prefs.remove(_key);
      } else {
        _pinned = pin;
      }
    } catch (_) {
      _pinned = null;
    }
    notifyListeners();
  }

  /// Pin the journey the user committed to, for the given route/direction.
  Future<void> pin(JourneyInfo journey, TransitConfig cfg, bool isMorning) async {
    final originId = cfg.originStopId(isMorning);
    final destId = cfg.destStopId(isMorning);
    final depLocal = journey.departureTime.toLocal();
    _pinned = PinnedJourney(
      originId: originId,
      destId: destId,
      isMorning: isMorning,
      line: journey.mainLine ?? '',
      destination: journey.mainDestination ?? 'Unknown',
      departure: DateTime(depLocal.year, depLocal.month, depLocal.day,
          depLocal.hour, depLocal.minute),
      durationMinutes: journey.durationMinutes,
      transportMode: journey.transportMode,
      departurePlatform: journey.departurePlatform,
      occupancy: journey.occupancy,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_pinned!.toJson()));
    notifyListeners();
  }

  /// Unpin — reverts to normal rolling-window behavior.
  Future<void> unpin() async {
    _pinned = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }

  /// Whether the pinned journey belongs to the current route/direction.
  bool isPinnedFor(String origin, String dest, bool morning) {
    final p = _pinned;
    return p != null &&
        p.originId == origin &&
        p.destId == dest &&
        p.isMorning == morning;
  }

  /// Whether [journey] is the currently pinned journey.
  bool isPinnedJourney(JourneyInfo journey, String origin, String dest, bool morning) {
    final p = _pinned;
    return p != null && p.matches(journey, origin, dest, morning);
  }

  /// The journey to render as "pinned": the live matched journey from the
  /// returned list if present (so delays/occupancy stay accurate), otherwise
  /// a synthetic journey built from the pin so it stays visible even when the
  /// rolling 3-trip window has pushed it out.
  ///
  /// Returns null if there is no pin, it has expired, or it belongs to a
  /// different route/direction.
  JourneyInfo? effectivePinnedJourney(
    List<JourneyInfo> journeys, String origin, String dest, bool morning) {
    final p = _pinned;
    if (p == null) return null;
    if (p.isExpired) {
      _pinned = null;
      unawaited(_removeFromStorage());
      notifyListeners();
      return null;
    }
    if (!isPinnedFor(origin, dest, morning)) return null;
    for (final j in journeys) {
      if (p.matches(j, origin, dest, morning)) return j;
    }
    return p.toJourneyInfo();
  }

  /// Clear any pin tied to a changed route (different stations).
  Future<void> clearForRouteChange() async {
    _pinned = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }

  Future<void> _removeFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
