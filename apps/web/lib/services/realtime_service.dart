import 'dart:convert';

import '../utils/web_browser.dart';
import 'api_client.dart';

/// A change published by the API over Server-Sent Events.
class RealtimeEvent {
  final String table;
  final String type; // INSERT | UPDATE | DELETE
  final Map<String, dynamic> row;

  const RealtimeEvent({
    required this.table,
    required this.type,
    required this.row,
  });
}

/// Streams cross-device changes for the signed-in user.
///
/// The API publishes an event over Server-Sent Events whenever one of the
/// user's rows changes, and the app re-fetches the affected data.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService _instance = RealtimeService._();
  factory RealtimeService() => _instance;

  void Function(RealtimeEvent event)? _onEvent;
  bool _running = false;

  bool get isRunning => _running;

  /// Starts (or restarts) the stream for [token].
  void start({
    required String token,
    required void Function(RealtimeEvent event) onEvent,
  }) {
    stop();
    _onEvent = onEvent;
    _running = true;
    startEventStream('${ApiClient().baseUrl}/events?token=$token', _handleMessage);
  }

  void stop() {
    stopEventStream();
    _running = false;
    _onEvent = null;
  }

  void _handleMessage(String data) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) return;
      final table = decoded['table'] as String?;
      final type = decoded['type'] as String?;
      final row = decoded['row'];
      if (table == null || type == null || row is! Map<String, dynamic>) return;
      _onEvent?.call(RealtimeEvent(table: table, type: type, row: row));
    } catch (_) {
      // Ignore malformed keep-alive/comment frames.
    }
  }
}
