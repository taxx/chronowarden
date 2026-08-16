// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

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
    // Check current permission state
    if (kIsWeb) _checkExistingPermission();
  }

  /// Enable or disable notifications.
  /// Requests browser permission synchronously (before any awaits) so the
  /// user-gesture chain required by browsers is preserved.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    // Request permission IMMEDIATELY while the user gesture is active.
    // Browser gesture activation is lost if we await anything first.
    if (value && kIsWeb && !_permissionGranted) {
      _requestPermissionSync();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, value);
  }

  /// Request permission synchronously (no awaits) to preserve gesture context.
  void _requestPermissionSync() {
    try {
      final state = html.Notification.requestPermission();
      // requestPermission returns a Future, but we need to check the result.
      // We'll handle the async result separately.
      state.then((result) {
        _permissionGranted = result == 'granted';
      }).catchError((_) {
        _permissionGranted = false;
      });
    } catch (_) {
      _permissionGranted = false;
    }
  }

  /// Set the threshold in minutes.
  Future<void> setThresholdMinutes(int value) async {
    _thresholdMinutes = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThresholdKey, value);
  }

  /// Check if permission is already granted without prompting.
  void _checkExistingPermission() {
    try {
      _permissionGranted = html.Notification.permission == 'granted';
    } catch (_) {
      _permissionGranted = false;
    }
  }

  /// Show a browser notification. Returns true if shown.
  bool showNotification(String title, String body) {
    if (!_enabled || !kIsWeb) return false;
    try {
      html.Notification(title, body: body, icon: 'icons/Icon-192.png');
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
