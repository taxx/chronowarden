// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:js';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages notification settings and the browser Notification API.
///
/// Settings are persisted in SharedPreferences (localStorage on web).
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  static const _kEnabledKey = 'notifications_enabled';
  static const _kThresholdKey = 'notification_threshold_minutes';

  bool _enabled = false;
  int _thresholdMinutes = 30;
  bool _permissionGranted = false;
  String? _lastNotifiedDate;

  bool get enabled => _enabled;
  int get thresholdMinutes => _thresholdMinutes;
  bool get permissionGranted => _permissionGranted;

  /// Load persisted settings.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kEnabledKey) ?? false;
    _thresholdMinutes = prefs.getInt(_kThresholdKey) ?? 30;
    _lastNotifiedDate = prefs.getString('notified_date');
    if (kIsWeb) _checkExistingPermission();
  }

  /// Enable or disable notifications.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    // Request permission IMMEDIATELY while the user gesture is active.
    if (value && kIsWeb && !_permissionGranted) {
      _requestPermissionSync();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, value);
  }

  /// Set the threshold in minutes.
  Future<void> setThresholdMinutes(int value) async {
    _thresholdMinutes = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThresholdKey, value);
  }

  /// Check current permission without prompting.
  void _checkExistingPermission() {
    try {
      final notif = context['Notification'] as JsObject?;
      if (notif == null) { _permissionGranted = false; return; }
      final permission = notif['permission'];
      _permissionGranted = permission == 'granted';
    } catch (_) {
      _permissionGranted = false;
    }
  }

  /// Request permission synchronously (no awaits) to preserve gesture context.
  void _requestPermissionSync() {
    try {
      final notif = context['Notification'] as JsObject?;
      if (notif == null) return;
      final promise = notif.callMethod('requestPermission', []);
      if (promise is JsObject) {
        promise.callMethod('then', [
          JsFunction.withThis((thisArg, args) {
            final result = args?[0];
            _permissionGranted = result == 'granted';
          })
        ]);
      }
    } catch (_) {
      _permissionGranted = false;
    }
  }

  /// Show a browser notification. Returns true if shown.
  bool showNotification(String title, String body) {
    if (!_enabled || !kIsWeb) return false;
    try {
      final constructor = context['Notification'] as JsFunction?;
      if (constructor == null) return false;
      final options = JsObject.jsify({
        'body': body,
        'icon': 'icons/Icon-192.png',
      });
      JsObject(constructor, [title, options]);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mark today as notified so we don't spam.
  Future<void> markNotified(String date) async {
    _lastNotifiedDate = date;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notified_date', date);
  }

  bool wasNotifiedToday(String date) => _lastNotifiedDate == date;
}
