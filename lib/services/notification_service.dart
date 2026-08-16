// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:js';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages leave-time alerts using in-app UI + audio + vibration.
///
/// Uses the browser Notification API only for permission (which worked).
/// The actual alert is shown as an in-app overlay + audio beep + vibration,
/// which is more reliable across browsers than the Notification constructor.
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  static const _kEnabledKey = 'notifications_enabled';
  static const _kThresholdKey = 'notification_threshold_minutes';
  static const _kSoundKey = 'notification_sound_enabled';
  static const _kVibrateKey = 'notification_vibrate_enabled';

  bool _enabled = false;
  int _thresholdMinutes = 30;
  bool _soundEnabled = true;
  bool _vibrateEnabled = true;
  String? _lastNotifiedDate;

  bool get enabled => _enabled;
  int get thresholdMinutes => _thresholdMinutes;
  bool get soundEnabled => _soundEnabled;
  bool get vibrateEnabled => _vibrateEnabled;

  /// Load persisted settings.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kEnabledKey) ?? false;
    _thresholdMinutes = prefs.getInt(_kThresholdKey) ?? 30;
    _soundEnabled = prefs.getBool(_kSoundKey) ?? true;
    _vibrateEnabled = prefs.getBool(_kVibrateKey) ?? true;
    // Reset notified state so alerts can fire fresh during testing
    _lastNotifiedDate = null;
  }

  /// Enable or disable notifications.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (value && kIsWeb) {
      _requestPermissionIfNeeded();
      ensureAudio();
    }
    // Reset notified state on toggle so alerts can fire fresh
    _lastNotifiedDate = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, value);
  }

  Future<void> setThresholdMinutes(int value) async {
    _thresholdMinutes = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThresholdKey, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSoundKey, value);
  }

  Future<void> setVibrateEnabled(bool value) async {
    _vibrateEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kVibrateKey, value);
  }

  // -- Permission (browser Notification API — proven working) ----------------

  void _requestPermissionIfNeeded() {
    try {
      if (html.Notification.permission != 'granted') {
        html.Notification.requestPermission().then((result) {
          // Permission granted or denied — we don't need it for our alerts.
        }).catchError((_) {});
      }
    } catch (_) {}
  }

  // -- Alert (in-app + audio + vibration) -----------------------------------

  /// Show an in-app alert. Returns a message string that the UI can display.
  /// The actual display is handled by the caller (snackbar, overlay, etc.).
  String alertMessage(String title, String body, {bool isUrgent = false}) {
    if (!_enabled) return '';
    // Play audio regardless of UI state
    if (_soundEnabled) {
      playAlertSound(count: isUrgent ? 3 : 1);
    }
    // Vibration via Navigator (mobile browsers)
    if (_vibrateEnabled && kIsWeb) {
      _vibrate();
    }
    return body;
  }

  JsObject? _audioCtx;
  bool _audioInitialized = false;

  /// Create a persistent AudioContext during a user gesture.
  void ensureAudio() {
    if (_audioInitialized || !kIsWeb) return;
    try {
      final audioCtxCtor = context['AudioContext'] as JsFunction?;
      if (audioCtxCtor == null) return;
      _audioCtx = JsObject(audioCtxCtor, []);
      _audioInitialized = true;
    } catch (_) {}
  }

  /// Play a short beep using Web Audio API via dart:js (correct property access).
  void playAlertSound({int count = 1}) {
    if (!_soundEnabled || !kIsWeb) return;
    if (_audioCtx == null) return;
    try {
      final ctx = _audioCtx!;
      for (int i = 0; i < count; i++) {
        final startTime = i * 0.5;
        final osc = ctx.callMethod('createOscillator', []);
        osc['frequency']['value'] = 440;
        final gain = ctx.callMethod('createGain', []);
        gain['gain']['value'] = 0.3;
        osc.callMethod('connect', [gain]);
        gain.callMethod('connect', [ctx['destination']]);
        osc.callMethod('start', [startTime]);
        osc.callMethod('stop', [startTime + 0.3]);
      }
    } catch (_) {}
  }

  /// Trigger a short vibration via the Navigator API (no permission needed).
  void _vibrate() {
    try {
      final navigator = context['navigator'] as JsObject?;
      if (navigator == null) return;
      navigator.callMethod('vibrate', [200]);
    } catch (_) {}
  }

  // -- Tracking -------------------------------------------------------------

  Future<void> markNotified(String date) async {
    _lastNotifiedDate = date;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notified_date', date);
  }

  bool wasNotifiedToday(String date) => _lastNotifiedDate == date;
}
