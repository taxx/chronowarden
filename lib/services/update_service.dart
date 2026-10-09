import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/build_info.dart';
import '../utils/web_browser.dart';
import '../utils/web_local_storage.dart';

/// Watches for newly deployed builds and lets the app prompt the user to
/// reload into them.
///
/// How it works: the running app knows its own commit (the `build_info.json`
/// asset baked in at build time) and periodically fetches `/version.json`
/// from the server. When the two commits differ, an update is available.
///
/// The check is best-effort: on local/dev builds or when the server file is
/// missing, it stays quiet.
class UpdateService extends ChangeNotifier {
  UpdateService._();
  static final UpdateService _instance = UpdateService._();
  factory UpdateService() => _instance;

  static const String assetPath = 'build_info.json';
  static const String versionUrl = 'version.json';
  static const Duration pollInterval = Duration(minutes: 5);
  static const _dismissedKey = 'update_dismissed_commit';

  Timer? _timer;
  bool _started = false;
  bool _visibilityRegistered = false;
  BuildInfo? _running;
  BuildInfo? _server;
  String? _dismissedCommit;
  bool _updateAvailable = false;

  /// True when a newer build is deployed and not dismissed.
  bool get updateAvailable => _updateAvailable;

  /// Commit the app itself was built from.
  BuildInfo? get runningBuild => _running;

  /// Commit the server is currently serving.
  BuildInfo? get serverBuild => _server;

  /// Begin polling. Safe to call multiple times; only the first starts a timer.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _dismissedCommit = readLocalStorage(_dismissedKey);
    // Re-check as soon as the user returns to a long-lived tab. Register once:
    // start() may run again if the shell is rebuilt (e.g. after sign-in).
    if (!_visibilityRegistered) {
      onPageVisible(check);
      _visibilityRegistered = true;
    }
    await check();
    _timer ??= Timer.periodic(pollInterval, (_) => check());
  }

  /// Stop polling (called when the authenticated shell is disposed).
  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  /// Fetch the server build info and refresh [updateAvailable].
  Future<void> check() async {
    try {
      _running ??= await _loadRunningBuild();
      final raw = await fetchText(
        '$versionUrl?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      if (raw == null) return;
      final server = BuildInfo.parse(raw);
      if (server == null) return;
      _server = server;
      _refresh();
    } catch (_) {
      // Network hiccups must never surface to the user.
    }
  }

  /// Reload the page to pick up the new build.
  void reload() => reloadPage();

  /// Stop prompting for the currently deployed build.
  void dismiss() {
    final server = _server;
    if (server != null) {
      _dismissedCommit = server.commit;
      writeLocalStorage(_dismissedKey, server.commit);
    }
    _refresh();
  }

  void _refresh() {
    final next = isUpdateAvailable(
      running: _running,
      server: _server,
      dismissedCommit: _dismissedCommit,
    );
    final changed = next != _updateAvailable;
    _updateAvailable = next;
    if (changed) notifyListeners();
  }

  Future<BuildInfo?> _loadRunningBuild() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      return BuildInfo.parse(raw);
    } catch (_) {
      return null;
    }
  }
}
