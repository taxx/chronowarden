import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../models/journey_info.dart';
import '../models/station_info.dart';
import '../models/transit_config.dart';

import 'api_client.dart';
import 'auth_service.dart';
import 'crypto_service.dart';
import 'pinned_journey_store.dart';
import 'transit_fetch_guard.dart';

/// Manages transit integration with SL (Stockholm Public Transport).
///
/// Responsibilities:
/// 1. Read/write [TransitConfig] from encrypted [user_settings]
/// 2. Fetch SL journey planner stops from /v2/stop-finder (per-query, no cache)
/// 3. Fetch journey plans from /v2/trips (cached 60s per route, coalesces
///    concurrent requests for the same route, and backs off exponentially
///    after failures — see [TransitFetchGuard])
///
/// All API calls go through the API's `/sl/proxy` route (same origin).
class TransitService {
  TransitService._({
    TransitFetchGuard? guard,
    this.proxyOverride,
    DateTime Function()? now,
  })  : _guard = guard ?? TransitFetchGuard(),
        _now = now ?? DateTime.now;

  static final TransitService _instance = TransitService._();
  factory TransitService() => _instance;

  /// Test seam: a non-singleton instance backed by a fake proxy and clock.
  @visibleForTesting
  static TransitService createForTest({
    TransitFetchGuard? guard,
    Future<dynamic> Function(String path)? proxyOverride,
    DateTime Function()? now,
  }) =>
      TransitService._(
        guard: guard,
        proxyOverride: proxyOverride,
        now: now,
      );

  final TransitFetchGuard _guard;

  /// Test seam: replaces the real Edge Function call. Null in production.
  final Future<dynamic> Function(String path)? proxyOverride;

  final DateTime Function() _now;

  // -----------------------------------------------------------------
  // API proxy for the SL Journey Planner
  // -----------------------------------------------------------------

  /// Invoke the sl-proxy Edge Function with a given path.
  Future<dynamic> _slProxy(String path) {
    final override = proxyOverride;
    if (override != null) return override(path);
    return _invokeProxy(path);
  }

  Future<dynamic> _invokeProxy(String path) async {
    try {
      return await _api.post('/sl/proxy', {'path': path});
    } on ApiException catch (e) {
      throw TransitApiException(status: e.status, message: e.message);
    } catch (e) {
      throw TransitApiException(
        status: transitNetworkErrorStatus,
        message: e.toString(),
      );
    }
  }

  // -----------------------------------------------------------------
  // In-memory cache
  // -----------------------------------------------------------------

  List<JourneyInfo>? _cachedJourneys;
  DateTime? _journeysFetchedAt;
  String? _lastJourneyCacheKey; // "${originId}:${destId}:${walkOffset}"

  /// Tracks in-flight fetch to coalesce concurrent requests for the same key.
  Future<List<JourneyInfo>?>? _pendingJourneyFetch;

  /// Public read-only access to cached journeys.
  List<JourneyInfo>? get cachedJourneys => _cachedJourneys;

  /// Current transit availability, derived from the retry guard.
  TransitAvailability get availability => _guard.availability(_now());

  /// Whether the service may hit the network right now.
  bool get canAttempt => _guard.canAttempt(_now());

  /// Time left before the next automatic retry (zero when not backing off).
  Duration get backoffRemaining => _guard.remaining(_now());

  /// When the next automatic attempt will happen (null when not backing off).
  DateTime? get nextRetryAt => _guard.backoffUntil;

  /// Whether the service has given up until an explicit retry.
  bool get hasGivenUp => _guard.hasGivenUp;

  /// Last failure message, if any.
  String? get lastErrorMessage => _guard.lastErrorMessage;

  /// Explicit user retry: clear back-off/give-up and drop the cache so the
  /// next fetch actually hits the network.
  void retryNow() {
    _guard.reset();
    clearJourneyCache();
  }

  /// Whether the journey cache needs refreshing (stale > 60s or wrong route).
  bool shouldRefreshJourneys(String originId, String destId, int walkOffset) {
    final key = '$originId:$destId:$walkOffset';
    if (_cachedJourneys == null) return true;
    if (_lastJourneyCacheKey != key) return true;
    if (_journeysFetchedAt == null) return true;
    return DateTime.now().difference(_journeysFetchedAt!).abs()
        > _journeysCacheTtl;
  }

  /// Clear journey cache so next fetch is forced (e.g., after settings change).
  void clearJourneyCache() {
    _cachedJourneys = null;
    _journeysFetchedAt = null;
    _lastJourneyCacheKey = null;
    _pendingJourneyFetch = null;
  }

  // Cache TTL constants
  static const _journeysCacheTtl = Duration(seconds: 60);

  // -----------------------------------------------------------------
  // Config management
  // -----------------------------------------------------------------

  TransitConfig? _config;

  TransitConfig get config =>
      _config ?? const TransitConfig(enabled: false);

  ApiClient get _api => ApiClient();

  String? get _userId => AuthService().profile?.id;

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
      final resp = await _api.get('/settings');
      final encrypted = resp is Map<String, dynamic>
          ? resp['encrypted_data'] as String?
          : null;

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
  /// Clears journey cache so UI refreshes with new station settings.
  /// Drops any pinned journey if the stations (route) changed.
  void applyConfig(TransitConfig cfg) {
    if (_config != null &&
        (_config!.workStopId != cfg.workStopId ||
            _config!.homeStopId != cfg.homeStopId)) {
      PinnedJourneyStore().clearForRouteChange();
    }
    _config = cfg;
    clearJourneyCache();
  }

  /// Save [TransitConfig] to encrypted [user_settings].
  Future<void> saveConfig(TransitConfig cfg) async {
    final userId = _userId;
    final dek = _dek;
    if (userId == null || dek == null) return;

    try {
      final resp = await _api.get('/settings');
      Map<String, dynamic> existing = {};
      if (resp is Map<String, dynamic>) {
        final encrypted = resp['encrypted_data'] as String?;
        if (encrypted != null && encrypted.isNotEmpty) {
          existing = jsonDecode(await CryptoService.decrypt(encrypted, dek))
              as Map<String, dynamic>;
        }
      }

      existing['transit_config'] = cfg.toJson();
      _config = cfg;
      clearJourneyCache();

      final ciphertext = await CryptoService.encrypt(jsonEncode(existing), dek);
      await _api.patch('/settings', {'encrypted_data': ciphertext});
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
  /// Coalesces concurrent requests: if a fetch for the same key is already
  /// in-flight, returns that pending future instead of starting a new one.
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
      final age = _now().difference(_journeysFetchedAt!);
      if (age < _journeysCacheTtl) return _cachedJourneys;
    }

    // Coalesce: if a fetch for this key is already in-flight, reuse it. The
    // pending future never rejects (see [_runFetch]), so this is safe for
    // every caller.
    final pending = _pendingJourneyFetch;
    if (pending != null && _lastJourneyCacheKey == key) {
      return pending;
    }

    // Respect back-off / give-up: return stale data without touching the
    // network. This is what stops a failing proxy from being hammered once
    // per widget rebuild.
    if (!_guard.canAttempt(_now())) {
      return _lastJourneyCacheKey == key ? _cachedJourneys : null;
    }

    final now = _now();

    // Offset the query time by walk minutes so the API gives us
    // journeys we can actually catch
    final queryTime = now.add(Duration(minutes: walkOffsetMinutes));
    final itdTime = '${queryTime.hour.toString().padLeft(2, '0')}'
        '${queryTime.minute.toString().padLeft(2, '0')}';
    final itdDate =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';

    // Request 3 journeys
    final path = '/v2/trips'
        '?type_origin=any&name_origin=$originId'
        '&type_destination=any&name_destination=$destId'
        '&itd_date=$itdDate&itd_time=$itdTime'
        '&calc_number_of_trips=3'
        '&calc_one_direction=true';

    _lastJourneyCacheKey = key;
    final safe = _runFetch(path, key);
    _pendingJourneyFetch = safe;
    try {
      return await safe;
    } finally {
      _pendingJourneyFetch = null;
    }
  }

  /// Run a fetch, translating any failure into guard state and a resulting
  /// value so coalesced callers can never observe an unhandled error.
  Future<List<JourneyInfo>?> _runFetch(String path, String key) async {
    try {
      final journeys = await _performFetch(path);
      _guard.recordSuccess();
      return journeys;
    } on TransitApiException catch (e) {
      _guard.recordFailure(
        _now(),
        status: e.status,
        message: e.message,
        retryAfter: e.retryAfter,
      );
      return _lastJourneyCacheKey == key ? _cachedJourneys : null;
    } catch (e) {
      _guard.recordFailure(
        _now(),
        status: transitNetworkErrorStatus,
        message: e.toString(),
      );
      return _lastJourneyCacheKey == key ? _cachedJourneys : null;
    }
  }

  /// Internal: perform the actual API fetch and parse the response.
  Future<List<JourneyInfo>?> _performFetch(String path) async {
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
    _journeysFetchedAt = _now();
    return journeys;
  }

  // -----------------------------------------------------------------
  // Cleanup
  // -----------------------------------------------------------------

  void onLogout() {
    _config = null;
    _guard.reset();
    clearJourneyCache();
  }
}
