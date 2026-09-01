import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/journey_info.dart';
import '../models/station_info.dart';
import '../models/transit_config.dart';

import 'auth_service.dart';
import 'crypto_service.dart';
import 'supabase_service.dart';

/// Manages transit integration with SL (Stockholm Public Transport).
///
/// Responsibilities:
/// 1. Read/write [TransitConfig] from encrypted [user_settings]
/// 2. Fetch SL journey planner stops from /v2/stop-finder (per-query, no cache)
/// 3. Fetch journey plans from /v2/trips (cached 60s per route)
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

  List<JourneyInfo>? _cachedJourneys;
  DateTime? _journeysFetchedAt;
  String? _lastJourneyCacheKey; // "${originId}:${destId}:${walkOffset}"

  /// Public read-only access to cached journeys.
  List<JourneyInfo>? get cachedJourneys => _cachedJourneys;

  /// Whether the journey cache needs refreshing (stale > 60s or wrong route).
  bool shouldRefreshJourneys(String originId, String destId, int walkOffset) {
    final key = '$originId:$destId:$walkOffset';
    if (_cachedJourneys == null) return true;
    if (_lastJourneyCacheKey != key) return true;
    if (_journeysFetchedAt == null) return true;
    return DateTime.now().difference(_journeysFetchedAt!).abs()
        > _journeysCacheTtl;
  }

  // Cache TTL constants
  static const _journeysCacheTtl = Duration(seconds: 60);

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

  /// Fetch stops matching [query] from the journey planner stop-finder.
  ///
  /// No caching — each query fetches fresh results. The caller (StationPicker)
  /// debounces requests to avoid spamming the API.
  Future<List<StationInfo>?> fetchStops(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final path =
          '/v2/stop-finder?name_sf=$encodedQuery&type_sf=any&any_obj_filter_sf=2';
      final data = await _slProxy(path);

      if (data is! Map<String, dynamic>) return null;
      final locations = data['locations'] as List<dynamic>?;
      if (locations == null) return [];

      final stops = locations
          .map((e) => StationInfo.fromStopFinderJson(e as Map<String, dynamic>))
          .where((s) => s.id.isNotEmpty)
          .toList();

      stops.sort((a, b) => a.name.compareTo(b.name));
      return stops;
    } catch (_) {
      return null;
    }
  }

  // -----------------------------------------------------------------
  // SL Journey Planner — Trips (journey planning)
  // -----------------------------------------------------------------

  /// Fetch journey plans between [originId] and [destId].
  ///
  /// The query time is offset by [walkOffsetMinutes] so the API returns
  /// journeys that depart after the user has walked to the station,
  /// maximizing useful results from the 3-journey limit.
  ///
  /// Returns cached list if cache is still fresh (< 60s) and
  /// the origin/destination/walk offset matches.
  Future<List<JourneyInfo>?> fetchJourneys({
    required String originId,
    required String destId,
    int walkOffsetMinutes = 0,
  }) async {
    final key = '$originId:$destId:$walkOffsetMinutes';

    // Return cached if fresh and same route
    if (_cachedJourneys != null &&
        _journeysFetchedAt != null &&
        _lastJourneyCacheKey == key) {
      final age = DateTime.now().difference(_journeysFetchedAt!);
      if (age < _journeysCacheTtl) return _cachedJourneys;
    }

    try {
      final now = DateTime.now();

      // Offset the query time by walk minutes so the API gives us
      // journeys we can actually catch
      final queryTime = now.add(Duration(minutes: walkOffsetMinutes));
      final time = '${queryTime.hour.toString().padLeft(2, '0')}:'
          '${queryTime.minute.toString().padLeft(2, '0')}';
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
  // Cleanup
  // -----------------------------------------------------------------

  void onLogout() {
    _config = null;
    _cachedJourneys = null;
    _journeysFetchedAt = null;
    _lastJourneyCacheKey = null;
  }
}
