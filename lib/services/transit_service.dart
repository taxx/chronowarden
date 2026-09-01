import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/departure_info.dart';
import '../models/journey_info.dart';
import '../models/station_info.dart';
import '../models/transit_config.dart';

import 'auth_service.dart';
import 'crypto_service.dart';
import 'supabase_service.dart';

/// Manages real-time transit integration with SL (Stockholm Public Transport).
///
/// Responsibilities:
/// 1. Read/write [TransitConfig] from encrypted [user_settings]
/// 2. Fetch SL journey planner stops from /v2/stop-finder (cached in memory)
/// 3. Fetch journey plans from /v2/trips (cached 30s TTL)
/// 4. (Legacy) Fetch departures from /v1/sites/{siteId}/departures
///
/// All API calls go through the sl-proxy Edge Function to avoid CORS issues.
class TransitService {
  TransitService._();
  static final TransitService _instance = TransitService._();
  factory TransitService() => _instance;

  // -----------------------------------------------------------------
  // Supabase Edge Function proxy for SL API
  // -----------------------------------------------------------------

  /// Invoke the sl-proxy Edge Function with a given path.
  Future<dynamic> _slProxy(String path) async {
    final result = await _client.functions.invoke('sl-proxy', body: {
      'path': path,
    });
    return result.data;
  }

  // -----------------------------------------------------------------
  // In-memory cache
  // -----------------------------------------------------------------

  List<StationInfo>? _cachedStops;
  DateTime? _stopsFetchedAt;

  List<JourneyInfo>? _cachedJourneys;
  DateTime? _journeysFetchedAt;
  String? _lastJourneyCacheKey; // "${originId}:${destId}:${morningFlag}"

  List<DepartureInfo>? _cachedDepartures;
  DateTime? _departuresFetchedAt;
  int? _lastDepartureSiteId;

  /// Public read-only access to cached journeys.
  List<JourneyInfo>? get cachedJourneys => _cachedJourneys;

  /// Public read-only access to cached departures (legacy).
  List<DepartureInfo>? get cachedDepartures => _cachedDepartures;

  /// Whether the journey cache needs refreshing (stale > 30s or wrong route).
  bool shouldRefreshJourneys(String originId, String destId, bool isMorning) {
    final key = '$originId:$destId:$isMorning';
    if (_cachedJourneys == null) return true;
    if (_lastJourneyCacheKey != key) return true;
    if (_journeysFetchedAt == null) return true;
    return DateTime.now().difference(_journeysFetchedAt!).abs()
        > _journeysCacheTtl;
  }

  /// Whether the departure cache needs refreshing (stale > 30s or wrong station).
  bool shouldRefresh(int siteId) {
    if (_cachedDepartures == null) return true;
    if (_lastDepartureSiteId != siteId) return true;
    if (_departuresFetchedAt == null) return true;
    return DateTime.now().difference(_departuresFetchedAt!).abs()
        > _departuresCacheTtl;
  }

  // Cache TTL constants
  static const _stopsCacheTtl = Duration(hours: 24);
  static const _journeysCacheTtl = Duration(seconds: 30);
  static const _departuresCacheTtl = Duration(seconds: 30);

  // -----------------------------------------------------------------
  // Config management
  // -----------------------------------------------------------------

  TransitConfig? _config;

  TransitConfig get config =>
      _config ?? const TransitConfig(enabled: false);

  SupabaseClient get _client => SupabaseService.instance.client;

  String? get _userId {
    final session = _client.auth.currentSession;
    return session?.user.id;
  }

  SecretKey? get _dek => AuthService().dek;

  /// Load [TransitConfig] from encrypted [user_settings].
  Future<void> loadConfig() async {
    final userId = _userId;
    final dek = _dek;
    if (userId == null || dek == null) {
      _config = const TransitConfig(enabled: false);
      return;
    }

    try {
      final resp = await _client
          .from('user_settings')
          .select('encrypted_data')
          .eq('user_id', userId)
          .limit(1);
      final rows = resp as List<dynamic>;
      if (rows.isEmpty) {
        _config = const TransitConfig(enabled: false);
        return;
      }
      final row = rows.first as Map<String, dynamic>;
      final encrypted = row['encrypted_data'] as String?;

      if (encrypted == null || encrypted.isEmpty) {
        _config = const TransitConfig(enabled: false);
        return;
      }

      final plaintext = await CryptoService.decrypt(encrypted, dek);
      final data = jsonDecode(plaintext) as Map<String, dynamic>;
      final transitRaw = data['transit_config'];
      if (transitRaw is Map<String, dynamic>) {
        _config = TransitConfig.fromJson(transitRaw);
      } else {
        _config = const TransitConfig(enabled: false);
      }
    } catch (_) {
      _config = const TransitConfig(enabled: false);
    }
  }

  /// Apply [TransitConfig] in memory immediately (no persistence).
  void applyConfig(TransitConfig cfg) {
    _config = cfg;
  }

  /// Save [TransitConfig] to encrypted [user_settings].
  Future<void> saveConfig(TransitConfig cfg) async {
    final userId = _userId;
    final dek = _dek;
    if (userId == null || dek == null) return;

    try {
      final resp = await _client
          .from('user_settings')
          .select('encrypted_data')
          .eq('user_id', userId)
          .limit(1);
      final rows = resp as List<dynamic>;
      Map<String, dynamic> existing = {};
      if (rows.isNotEmpty) {
        final row = rows.first as Map<String, dynamic>;
        final encrypted = row['encrypted_data'] as String?;
        if (encrypted != null && encrypted.isNotEmpty) {
          final plaintext = await CryptoService.decrypt(encrypted, dek);
          existing = jsonDecode(plaintext) as Map<String, dynamic>;
        }
      }

      existing['transit_config'] = cfg.toJson();
      _config = cfg;

      final plaintext = jsonEncode(existing);
      final ciphertext = await CryptoService.encrypt(plaintext, dek);

      await _client.from('user_settings').upsert({
        'user_id': userId,
        'encrypted_data': ciphertext,
      }, onConflict: 'user_id');
    } catch (_) {}
  }

  // -----------------------------------------------------------------
  // SL Journey Planner — Stop Finder (search stations)
  // -----------------------------------------------------------------

  /// Fetch all matching stops from the journey planner stop-finder.
  ///
  /// Returns cached list if cache is still fresh (< 24h).
  /// Returns null on network error.
  Future<List<StationInfo>?> fetchStops(String query) async {
    // Return cached stops if still fresh
    if (_cachedStops != null && _stopsFetchedAt != null) {
      final age = DateTime.now().difference(_stopsFetchedAt!);
      if (age < _stopsCacheTtl) return _cachedStops;
    }

    try {
      // Use the journey planner stop-finder API
      // We search with name_sf and type_sf=any, any_obj_filter_sf=2 (stops)
      final encodedQuery = Uri.encodeComponent(query);
      final path = '/v2/stop-finder?name_sf=$encodedQuery&type_sf=any&any_obj_filter_sf=2';
      final data = await _slProxy(path);

      if (data is! Map<String, dynamic>) return null;
      final locations = data['locations'] as List<dynamic>?;
      if (locations == null) return null;

      final stops = locations
          .map((e) => StationInfo.fromStopFinderJson(e as Map<String, dynamic>))
          .where((s) => s.id.isNotEmpty)
          .toList();

      stops.sort((a, b) => a.name.compareTo(b.name));

      _cachedStops = stops;
      _stopsFetchedAt = DateTime.now();
      return stops;
    } catch (_) {
      return _cachedStops;
    }
  }

  /// Search cached stops by name (client-side filter, no network).
  List<StationInfo> searchStops(String query) {
    final stops = _cachedStops;
    if (stops == null || query.trim().isEmpty) return stops ?? [];

    final lower = query.trim().toLowerCase();
    return stops.where((s) =>
        s.name.toLowerCase().contains(lower)).toList();
  }

  /// Clear stop cache (e.g., on logout).
  void clearStopCache() {
    _cachedStops = null;
    _stopsFetchedAt = null;
  }

  // -----------------------------------------------------------------
  // SL Journey Planner — Trips (journey planning)
  // -----------------------------------------------------------------

  /// Fetch journey plans between [originId] and [destId].
  ///
  /// Returns cached list if cache is still fresh (< 30s) and
  /// the origin/destination/morning flag matches.
  Future<List<JourneyInfo>?> fetchJourneys({
    required String originId,
    required String destId,
    bool isMorning = true,
  }) async {
    final key = '$originId:$destId:$isMorning';

    // Return cached if fresh and same route
    if (_cachedJourneys != null && _journeysFetchedAt != null &&
        _lastJourneyCacheKey == key) {
      final age = DateTime.now().difference(_journeysFetchedAt!);
      if (age < _journeysCacheTtl) return _cachedJourneys;
    }

    try {
      final now = DateTime.now();
      final time = '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}';
      final date =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      // Request 3 journeys
      final path = '/v2/trips'
          '?type_origin=any&name_origin=$originId'
          '&type_destination=any&name_destination=$destId'
          '&date=$date&time=$time'
          '&calc_number_of_trips=3';

      final data = await _slProxy(path);

      if (data is! Map<String, dynamic>) return null;
      final journeysRaw = data['journeys'] as List<dynamic>?;
      if (journeysRaw == null) return [];

      final journeys = journeysRaw
          .map((e) => JourneyInfo.fromJson(e as Map<String, dynamic>))
          .toList();

      // Sort by departure time
      journeys.sort((a, b) => a.departureTime.compareTo(b.departureTime));

      _cachedJourneys = journeys;
      _journeysFetchedAt = DateTime.now();
      _lastJourneyCacheKey = key;
      return journeys;
    } catch (_) {
      // Return stale cache on error if we have one for same route
      if (_lastJourneyCacheKey == key) return _cachedJourneys;
      return null;
    }
  }

  // -----------------------------------------------------------------
  // SL Departures API — legacy (fetch and cache)
  // -----------------------------------------------------------------

  /// Fetch departures for [siteId] (legacy SL Transport API).
  Future<List<DepartureInfo>?> fetchDepartures(int siteId) async {
    // Return cached if fresh and same site
    if (_cachedDepartures != null && _departuresFetchedAt != null &&
        _lastDepartureSiteId == siteId) {
      final age = DateTime.now().difference(_departuresFetchedAt!);
      if (age < _departuresCacheTtl) return _cachedDepartures;
    }

    try {
      final data = await _slProxy('/v1/sites/$siteId/departures');
      if (data is! Map<String, dynamic>) return null;

      final departuresRaw = data['departures'] as List<dynamic>?;
      if (departuresRaw == null) return [];

      final now = DateTime.now();
      final departures = departuresRaw
          .map((e) => DepartureInfo.fromJson(e as Map<String, dynamic>))
          .where((d) =>
              d.scheduledTime.isAfter(now.subtract(const Duration(minutes: 1))) &&
              d.scheduledTime.isBefore(now.add(const Duration(hours: 6))))
          .toList();

      // Sort by scheduled time
      departures.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

      _cachedDepartures = departures;
      _departuresFetchedAt = DateTime.now();
      _lastDepartureSiteId = siteId;
      return departures;
    } catch (_) {
      // Return stale cache on error
      if (_lastDepartureSiteId == siteId) return _cachedDepartures;
      return null;
    }
  }

  /// Filter departures to those matching [destinationSiteId].
  List<DepartureInfo> filterByDestination(
    List<DepartureInfo> departures,
    int? destinationSiteId,
    String destinationName,
  ) {
    if (destinationName.trim().isEmpty) return departures;
    final lower = destinationName.trim().toLowerCase();
    return departures.where((d) {
      return d.destination.toLowerCase().contains(lower);
    }).toList();
  }

  /// Filter departures to rail-relevant modes (TRAM/TRAIN).
  List<DepartureInfo> filterRailRelevant(List<DepartureInfo> departures) {
    return departures.where((d) => d.isRailRelevant).toList();
  }

  /// Filter departures by direction code.
  List<DepartureInfo> filterByDirection(
    List<DepartureInfo> departures,
    int directionCode,
  ) {
    return departures.where((d) =>
        d.directionCode == directionCode).toList();
  }

  /// Filter departures by line number.
  List<DepartureInfo> filterByLineNumber(
    List<DepartureInfo> departures,
    List<String> lines,
  ) {
    if (lines.isEmpty) return departures;
    final lowerLines = lines.map((l) => l.trim().toLowerCase()).toList();
    return departures.where((d) {
      if (d.lineNumber == null) return false;
      final line = d.lineNumber!.toLowerCase();
      return lowerLines.any((filter) => line.startsWith(filter));
    }).toList();
  }

  // -----------------------------------------------------------------
  // Cleanup
  // -----------------------------------------------------------------

  void onLogout() {
    _config = null;
    clearStopCache();
    _cachedJourneys = null;
    _journeysFetchedAt = null;
    _lastJourneyCacheKey = null;
    _cachedDepartures = null;
    _departuresFetchedAt = null;
    _lastDepartureSiteId = null;
  }
}
