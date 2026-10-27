import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/web_local_storage.dart';

/// Error surfaced by the API. [message] is safe to show to the user.
class ApiException implements Exception {
  final int status;
  final String code;
  final String message;

  const ApiException(this.status, this.code, this.message);

  @override
  String toString() => message;
}

/// Thin HTTP client for the self-hosted ChronoWarden API.
///
/// The API lives under `/api/v1` on the same origin in production (behind the
/// reverse proxy), so no absolute URL or CORS is needed. Local development can
/// point elsewhere with `--dart-define=API_URL=http://localhost:8080/api/v1`.
class ApiClient {
  ApiClient._();
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  static const String _defineBaseUrl = String.fromEnvironment('API_URL');
  static const String _tokenKey = 'cw_api_token';

  static const Duration _timeout = Duration(seconds: 30);

  String? _token;

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  /// Base URL of the API, without a trailing slash.
  String get baseUrl {
    final configured = _defineBaseUrl.isNotEmpty ? _defineBaseUrl : '/api/v1';
    return configured.endsWith('/')
        ? configured.substring(0, configured.length - 1)
        : configured;
  }

  /// Loads a cached session token (survives page reloads via localStorage).
  Future<void> init() async {
    _token = readLocalStorage(_tokenKey);
  }

  void setToken(String? token) {
    _token = token;
    if (token == null) {
      removeLocalStorage(_tokenKey);
    } else {
      writeLocalStorage(_tokenKey, token);
    }
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body: body);

  Future<dynamic> patch(String path, [Object? body]) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Uri _resolve(String path, Map<String, String>? query) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$normalized');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = _resolve(path, query);
    final headers = <String, String>{
      'accept': 'application/json',
      if (body != null) 'content-type': 'application/json',
      if (_token != null) 'authorization': 'Bearer $_token',
    };

    late http.Response response;
    final encoded = body == null ? null : jsonEncode(body);
    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(_timeout);
        case 'POST':
          response =
              await http.post(uri, headers: headers, body: encoded).timeout(_timeout);
        case 'PATCH':
          response =
              await http.patch(uri, headers: headers, body: encoded).timeout(_timeout);
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(_timeout);
        default:
          throw ArgumentError('Unsupported method $method');
      }
    } catch (e) {
      throw ApiException(0, 'NETWORK', 'Could not reach the server. Check your connection.');
    }

    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final status = response.statusCode;
    if (status == 204 || response.body.isEmpty) {
      if (status >= 200 && status < 300) return null;
    }

    dynamic parsed;
    if (response.body.isNotEmpty) {
      try {
        parsed = jsonDecode(response.body);
      } catch (_) {
        parsed = null;
      }
    }

    if (status >= 200 && status < 300) return parsed;

    final error = parsed is Map<String, dynamic> ? parsed['error'] : null;
    final code = error is Map ? (error['code'] as String? ?? 'ERROR') : 'ERROR';
    final message = error is Map
        ? (error['message'] as String? ?? 'Request failed')
        : 'Request failed (HTTP $status)';
    throw ApiException(status, code, message);
  }
}
