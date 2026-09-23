import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/web_browser.dart';

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
      // Call BEFORE any await to preserve browser gesture context
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

  void _requestPermissionIfNeeded() => requestNotificationPermission();

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

  bool _audioInitialized = false;

  /// Register the JS beep helper (Web Audio API).
  void ensureAudio() {
    if (_audioInitialized || !kIsWeb) return;
    initBeepBridge();
    _audioInitialized = true;
  }

  /// Play a short beep via the JS beep helper.
  void playAlertSound({int count = 1}) {
    if (!_soundEnabled || !kIsWeb) return;
    playBeep(count);
  }

  /// Trigger a short vibration via the Navigator API (no permission needed).
  void _vibrate() {
    vibrate(200);
  }

  // -- Tracking -------------------------------------------------------------

  Future<void> markNotified(String date) async {
    _lastNotifiedDate = date;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notified_date', date);
  }

  bool wasNotifiedToday(String date) => _lastNotifiedDate == date;
}
