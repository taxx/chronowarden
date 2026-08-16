// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:js';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages notification settings and the browser Notification API.
///
/// Settings are persisted in SharedPreferences (localStorage on web).
/// Uses dart:html for notifications (proven working wrapper) and
/// dart:js for Web Audio API (oscillator beep).
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
  bool _permissionGranted = false;
  String? _lastNotifiedDate;

  bool get enabled => _enabled;
  int get thresholdMinutes => _thresholdMinutes;
  bool get soundEnabled => _soundEnabled;
  bool get vibrateEnabled => _vibrateEnabled;
  bool get permissionGranted => _permissionGranted;

  /// Load persisted settings.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kEnabledKey) ?? false;
    _thresholdMinutes = prefs.getInt(_kThresholdKey) ?? 30;
    _soundEnabled = prefs.getBool(_kSoundKey) ?? true;
    _vibrateEnabled = prefs.getBool(_kVibrateKey) ?? true;
    _lastNotifiedDate = prefs.getString('notified_date');
    if (kIsWeb) _checkExistingPermission();
  }

  /// Enable or disable notifications.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (value && kIsWeb && !_permissionGranted) {
      _requestPermissionSync();
    }
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

  // -- Permission -----------------------------------------------------------

  void _checkExistingPermission() {
    try {
      _permissionGranted = html.Notification.permission == 'granted';
    } catch (_) {
      _permissionGranted = false;
    }
  }

  void _requestPermissionSync() {
    try {
      final promise = html.Notification.requestPermission();
      promise.then((result) {
        _permissionGranted = result == 'granted';
      }).catchError((_) {
        _permissionGranted = false;
      });
    } catch (_) {
      _permissionGranted = false;
    }
  }

  // -- Show notification ----------------------------------------------------

  /// Show a browser notification via dart:js (supports all options).
  bool showNotification(String title, String body, {bool isUrgent = false}) {
    if (!_enabled || !kIsWeb) return false;
    try {
      final constructor = context['Notification'] as JsFunction?;
      if (constructor == null) return false;
      final opts = <String, dynamic>{
        'body': body,
        'icon': 'icons/Icon-192.png',
        'tag': 'chronowarden-leave',
        'renotify': true,
      };
      if (isUrgent) {
        opts['requireInteraction'] = true;
      }
      if (_vibrateEnabled) {
        opts['vibrate'] = [200, 100, 200];
      }
      final options = JsObject.jsify(opts);
      // Use apply() to call the constructor with thisArg: null
      constructor.apply([title, options], thisArg: null);
      return true;
    } catch (_) {
      return false;
    }
  }

  // -- Audio alert (Web Audio API via dart:js) --------------------------------

  /// Play a short beep using the Web Audio API.
  /// Uses an OscillatorNode — no audio file needed.
  void playAlertSound({int count = 1}) {
    if (!_soundEnabled || !kIsWeb) return;
    try {
      final audioCtx = context['AudioContext'] as JsFunction?;
      if (audioCtx == null) return;
      final ctx = JsObject(audioCtx, []);
      for (int i = 0; i < count; i++) {
        final startTime = i * 0.5;
        final oscillator = ctx.callMethod('createOscillator', []);
        oscillator['frequency'] = 440;
        final gain = ctx.callMethod('createGain', []);
        final gainNode = gain.callMethod('gain', []);
        gainNode['value'] = 0.3;
        oscillator.callMethod('connect', [gain]);
        gain.callMethod('connect', [ctx['destination']]);
        oscillator.callMethod('start', [startTime]);
        oscillator.callMethod('stop', [startTime + 0.3]);
      }
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
