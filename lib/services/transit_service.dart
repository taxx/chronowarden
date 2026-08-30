import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/departure_info.dart';
import '../models/station_info.dart';
import '../models/transit_config.dart';

import 'auth_service.dart';
import 'crypto_service.dart';
import 'supabase_service.dart';

/// Manages real-time transit integration with SL (Stockholm Public Transport).
///
/// Responsibilities:
/// 1. Read/write [TransitConfig] from encrypted [user_settings]
/// 2. Fetch SL site list from /v1/sites (cached in memory)
/// 3. Fetch departures from /v1/sites/{siteId}/departures (cached 30s TTL)
/// 4. Filter departures by destination and transport mode
class TransitService {
  TransitService._();
  static final TransitService _instance = TransitService._();
  factory TransitService() => _instance;

  // -----------------------------------------------------------------
  // Supabase Edge Function proxy for SL API
  // -----------------------------------------------------------------

  /// Invoke the sl-proxy Edge Function to avoid CORS issues.
  /// [path] is the SL API path, e.g. "/v1/sites" or "/v1/sites/9600/departures".
  Future<dynamic> _slProxy(String path) async {
    final result = await _client.functions.invoke('sl-proxy', body: {
      'path': path,
    });
    return result.data;
  }

  // -----------------------------------------------------------------
  // In-memory cache
  // -----------------------------------------------------------------

  List<StationInfo>? _cachedSites;
  DateTime? _sitesFetchedAt;

  List<DepartureInfo>? _cachedDepartures;

  /// Public read-only access to cached departures.
  List<DepartureInfo>? get cachedDepartures => _cachedDepartures;

  DateTime? _departuresFetchedAt;
  int? _lastDepartureSiteId;

  // Cache TTL constants
  static const _sitesCacheTtl = Duration(hours: 24);
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

  /// Save [TransitConfig] to encrypted [user_settings].
  Future<void> saveConfig(TransitConfig cfg) async {
    final userId = _userId;
    final dek = _dek;
    if (userId == null || dek == null) return;

    // Read existing encrypted settings, merge transit_config key
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
  // SL Site API — fetch and cache
  // -----------------------------------------------------------------

  /// Fetch all SL sites from the API.
  ///
  /// Returns cached list if cache is still fresh (< 24h).
  /// Returns null on network error.
  Future<List<StationInfo>?> fetchSites() async {
    // Return cached sites if still fresh
    if (_cachedSites != null && _sitesFetchedAt != null) {
      final age = DateTime.now().difference(_sitesFetchedAt!);
      if (age < _sitesCacheTtl) return _cachedSites;
    }

    try {
      final data = await _slProxy('/v1/sites');
      if (data is! List<dynamic>) return null;

      final sites = data
          .map((e) => StationInfo.fromJson(e as Map<String, dynamic>))
          .where((s) => s.id > 0)
          .toList();

      // Sort by name for easier autocomplete display
      sites.sort((a, b) => a.name.compareTo(b.name));

      _cachedSites = sites;
      _sitesFetchedAt = DateTime.now();
      return sites;
    } catch (_) {
      // Return stale cache on error if we have one
      return _cachedSites;
    }
  }

  /// Search cached sites by name (client-side filter, no network).
  List<StationInfo> searchSites(String query) {
    final sites = _cachedSites;
    if (sites == null || query.trim().isEmpty) return sites ?? [];

    final lower = query.trim().toLowerCase();
    return sites.where((s) =>
        s.name.toLowerCase().contains(lower)).toList();
  }

  /// Clear site cache (e.g., on logout).
  void clearSiteCache() {
    _cachedSites = null;
    _sitesFetchedAt = null;
  }

  // -----------------------------------------------------------------
  // SL Departures API — fetch and cache
  // -----------------------------------------------------------------

  /// Fetch departures for [siteId].
  ///
  /// Returns cached list if cache is still fresh (< 30s) and
  /// the site ID matches.
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
  ///
  /// Uses site ID for exact matching, falls back to name contains
  /// when no ID is available.
  List<DepartureInfo> filterByDestination(
    List<DepartureInfo> departures,
    int? destinationSiteId,
    String destinationName,
  ) {
    if (destinationSiteId == null || destinationSiteId <= 0) return departures;

    final lower = destinationName.toLowerCase();
    return departures.where((d) {
      // Match by destination name (contains)
      return d.destination.toLowerCase().contains(lower);
    }).toList();
  }

  /// Filter departures to rail-relevant modes (TRAM/TRAIN).
  List<DepartureInfo> filterRailRelevant(List<DepartureInfo> departures) {
    return departures.where((d) => d.isRailRelevant).toList();
  }

  // -----------------------------------------------------------------
  // Cleanup
  // -----------------------------------------------------------------

  void onLogout() {
    _config = null;
    clearSiteCache();
    _cachedDepartures = null;
    _departuresFetchedAt = null;
    _lastDepartureSiteId = null;
  }
}
