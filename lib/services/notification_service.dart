import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/web_browser.dart';

/// Which phase of the day an alert belongs to.
enum LeaveAlertKind { wrapUp, overtime }

/// A leave-time alert ready to be displayed.
@immutable
class LeaveAlert {
  final LeaveAlertKind kind;

  /// Minutes until leave (positive) or minutes past leave (negative).
  final double remainingMinutes;

  final String title;
  final String message;
  final bool isUrgent;

  const LeaveAlert({
    required this.kind,
    required this.remainingMinutes,
    required this.title,
    required this.message,
    required this.isUrgent,
  });

  /// Build the "wrap up soon" alert.
  static LeaveAlert wrapUp(double remainingMinutes) {
    final mins = remainingMinutes.round();
    final h = mins ~/ 60;
    final m = mins % 60;
    final timeStr = h > 0 ? '${h}h ${m}m' : '$m min';
    return LeaveAlert(
      kind: LeaveAlertKind.wrapUp,
      remainingMinutes: remainingMinutes,
      title: 'ChronoWarden ⏰',
      message: '⏰ $timeStr left — wrap up and head out!',
      isUrgent: false,
    );
  }

  /// Build the "you're past your leave time" alert.
  static LeaveAlert overtime(double remainingMinutes) {
    final over = remainingMinutes.abs().round();
    return LeaveAlert(
      kind: LeaveAlertKind.overtime,
      remainingMinutes: remainingMinutes,
      title: 'ChronoWarden 🚨',
      message: '🚨 $over min past your time — finish up and stop the day!',
      isUrgent: true,
    );
  }
}

/// Pure decision function: given how much time is left and the user's
/// notification state, return the alert that should be shown (or null).
///
/// Kept free of I/O so the timing rules can be unit-tested directly.
///
/// - [remainingMinutes] is positive before leave time, negative after.
/// - [dismissed] is true once the user has fully dismissed today's alert.
/// - [snoozed] is true while a snooze window is still running.
/// - [alreadyAlerted] is true if an alert was already delivered today and
///   has neither been snoozed nor dismissed (so we don't nag).
LeaveAlert? evaluateLeaveAlert({
  required double remainingMinutes,
  required int thresholdMinutes,
  required bool dismissed,
  required bool snoozed,
  required bool alreadyAlerted,
}) {
  if (dismissed || snoozed || alreadyAlerted) return null;

  // Phase 1 — wrap-up alert (within the configured threshold before leave).
  if (remainingMinutes >= 0 && remainingMinutes <= thresholdMinutes) {
    return LeaveAlert.wrapUp(remainingMinutes);
  }

  // Phase 2 — over-time alert (up to 60 min past leave).
  if (remainingMinutes < 0 && remainingMinutes >= -60) {
    return LeaveAlert.overtime(remainingMinutes);
  }

  return null;
}

/// Manages leave-time alerts using in-app UI + audio + vibration.
///
/// Uses the browser Notification API only for permission (which worked).
/// The actual alert is shown as an in-app overlay + audio beep + vibration,
/// which is more reliable across browsers than the Notification constructor.
///
/// The service is a [ChangeNotifier]: the UI listens for [currentAlert]
/// changes. Per-day state (alerted / snoozed / dismissed) is persisted so a
/// page reload neither re-fires nor forgets a dismissal.
class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  static const _kEnabledKey = 'notifications_enabled';
  static const _kThresholdKey = 'notification_threshold_minutes';
  static const _kSnoozeKey = 'notification_snooze_minutes';
  static const _kSoundKey = 'notification_sound_enabled';
  static const _kVibrateKey = 'notification_vibrate_enabled';
  static const _kAlertedDateKey = 'notified_date';
  static const _kDismissedDateKey = 'notified_dismissed_date';
  static const _kSnoozedUntilKey = 'notified_snoozed_until';

  bool _enabled = false;
  int _thresholdMinutes = 30;
  int _snoozeMinutes = 10;
  bool _soundEnabled = true;
  bool _vibrateEnabled = true;

  LeaveAlert? _currentAlert;
  String? _alertedDate; // date an alert was delivered for
  String? _dismissedDate; // date the user dismissed completely
  DateTime? _snoozedUntil; // snooze window end

  bool get enabled => _enabled;
  int get thresholdMinutes => _thresholdMinutes;
  int get snoozeMinutes => _snoozeMinutes;
  bool get soundEnabled => _soundEnabled;
  bool get vibrateEnabled => _vibrateEnabled;

  /// The alert currently being displayed, if any.
  LeaveAlert? get currentAlert => _currentAlert;

  /// Load persisted settings + per-day state.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kEnabledKey) ?? false;
    _thresholdMinutes = prefs.getInt(_kThresholdKey) ?? 30;
    _snoozeMinutes = prefs.getInt(_kSnoozeKey) ?? 10;
    _soundEnabled = prefs.getBool(_kSoundKey) ?? true;
    _vibrateEnabled = prefs.getBool(_kVibrateKey) ?? true;
    _alertedDate = prefs.getString(_kAlertedDateKey);
    _dismissedDate = prefs.getString(_kDismissedDateKey);
    final snoozeIso = prefs.getString(_kSnoozedUntilKey);
    _snoozedUntil = snoozeIso == null ? null : DateTime.tryParse(snoozeIso);
    // Note: _currentAlert is intentionally left alone — a re-init (e.g. from
    // the Settings screen) must not silently hide a visible alert.
    notifyListeners();
  }

  /// Enable or disable notifications.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (value && kIsWeb) {
      // Call BEFORE any await to preserve browser gesture context
      _requestPermissionIfNeeded();
      ensureAudio();
    }
    // Re-arm so a freshly enabled alert can fire even if one was already
    // delivered or dismissed earlier today.
    _resetTracking();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, value);
    await _persistTracking(prefs);
    notifyListeners();
  }

  Future<void> setThresholdMinutes(int value) async {
    _thresholdMinutes = value.clamp(1, 120);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThresholdKey, _thresholdMinutes);
    notifyListeners();
  }

  Future<void> setSnoozeMinutes(int value) async {
    _snoozeMinutes = value.clamp(1, 60);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSnoozeKey, _snoozeMinutes);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSoundKey, value);
    notifyListeners();
  }

  Future<void> setVibrateEnabled(bool value) async {
    _vibrateEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kVibrateKey, value);
    notifyListeners();
  }

  // -- Alert evaluation ------------------------------------------------------

  /// Evaluate whether an alert should be shown right now.
  ///
  /// Call this on every tick while the day is active. It is idempotent:
  /// once an alert has been delivered it will not sound again until the user
  /// snoozes (and the snooze expires) or dismisses it.
  ///
  /// [leaveTime] is the projected leave moment for [date] (already adjusted
  /// for any overrunning lunch) so all timing decisions stay in one place.
  void check({
    required String date,
    required DateTime leaveTime,
    required DateTime now,
  }) {
    if (!_enabled) {
      clearAlert();
      return;
    }

    // Fully dismissed for today — nothing more to show.
    if (_dismissedDate == date) {
      clearAlert();
      return;
    }

    // A snooze window is running.
    if (_snoozedUntil != null) {
      if (now.isBefore(_snoozedUntil!)) {
        clearAlert();
        return;
      }
      // Snooze expired — re-arm so the alert can fire again.
      _snoozedUntil = null;
      _alertedDate = null;
    }

    final remainingMinutes =
        leaveTime.difference(now).inSeconds / Duration.secondsPerMinute;

    // If an alert is already on screen, keep it fresh: update the countdown,
    // clear it if the user's leave time moved out of range, or promote it to
    // the over-time alert once leave time passes.
    if (_currentAlert != null) {
      final refreshed = evaluateLeaveAlert(
        remainingMinutes: remainingMinutes,
        thresholdMinutes: _thresholdMinutes,
        dismissed: false,
        snoozed: false,
        alreadyAlerted: false,
      );
      if (refreshed == null) {
        // No longer relevant (e.g. flex pushed leave time out) — re-arm.
        _currentAlert = null;
        _alertedDate = null;
        notifyListeners();
        return;
      }
      if (refreshed.kind != _currentAlert!.kind ||
          refreshed.message != _currentAlert!.message) {
        _currentAlert = refreshed;
        notifyListeners();
      }
      return;
    }

    // No alert on screen. Either a fresh delivery, or a previously delivered
    // alert that should be restored (e.g. after a page reload).
    final alert = evaluateLeaveAlert(
      remainingMinutes: remainingMinutes,
      thresholdMinutes: _thresholdMinutes,
      dismissed: false,
      snoozed: false,
      alreadyAlerted: false,
    );
    if (alert == null) return;

    final alreadyDelivered = _alertedDate == date;
    _currentAlert = alert;
    _alertedDate = date;
    _persistTracking();
    // Only sound on a fresh delivery, not when restoring the banner after a
    // page reload.
    if (!alreadyDelivered) {
      if (soundEnabled) playAlertSound(count: alert.isUrgent ? 3 : 1);
      if (vibrateEnabled && kIsWeb) vibrate(200);
    }
    notifyListeners();
  }

  /// Snooze the current alert for [snoozeMinutes]; it re-fires afterwards.
  Future<void> snooze() async {
    if (_currentAlert == null) return;
    _currentAlert = null;
    _snoozedUntil = DateTime.now().add(Duration(minutes: _snoozeMinutes));
    notifyListeners();
    await _persistTracking();
  }

  /// Dismiss the alert completely for today — no further alerts.
  Future<void> dismiss() async {
    _dismissedDate = _alertedDate ?? _dismissedDate;
    _currentAlert = null;
    _snoozedUntil = null;
    notifyListeners();
    await _persistTracking();
  }

  /// Hide the on-screen alert without changing the delivered/snoozed state.
  void clearAlert() {
    if (_currentAlert == null) return;
    _currentAlert = null;
    notifyListeners();
  }

  /// Forget today's alert state (called on sign out / day change).
  Future<void> resetForToday() async {
    _resetTracking();
    notifyListeners();
    await _persistTracking();
  }

  // -- Permission (browser Notification API — proven working) ----------------

  void _requestPermissionIfNeeded() => requestNotificationPermission();

  // -- Audio / vibration -----------------------------------------------------

  /// Show an alert (sound + vibration) and return its body text.
  /// Used by the "Send test" button in settings.
  String alertMessage(String title, String body, {bool isUrgent = false}) {
    if (!_enabled) return '';
    if (_soundEnabled) playAlertSound(count: isUrgent ? 3 : 1);
    if (_vibrateEnabled && kIsWeb) vibrate(200);
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

  // -- Persistence -----------------------------------------------------------

  void _resetTracking() {
    _currentAlert = null;
    _alertedDate = null;
    _dismissedDate = null;
    _snoozedUntil = null;
  }

  Future<void> _persistTracking([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    if (_alertedDate == null) {
      await p.remove(_kAlertedDateKey);
    } else {
      await p.setString(_kAlertedDateKey, _alertedDate!);
    }
    if (_dismissedDate == null) {
      await p.remove(_kDismissedDateKey);
    } else {
      await p.setString(_kDismissedDateKey, _dismissedDate!);
    }
    if (_snoozedUntil == null) {
      await p.remove(_kSnoozedUntilKey);
    } else {
      await p.setString(
        _kSnoozedUntilKey,
        _snoozedUntil!.toIso8601String(),
      );
    }
  }
}
