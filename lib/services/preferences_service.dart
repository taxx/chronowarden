import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's last-selected work period and travel preset IDs,
/// and other local preferences.
///
/// Uses local device storage — no database calls.
/// Exposes [ValueNotifier]s so UI can react to changes without polling.
class PreferencesService {
  PreferencesService._();
  static final PreferencesService _instance = PreferencesService._();
  factory PreferencesService() => _instance;

  static const _keyPeriodId = 'last_work_period_id';
  static const _keyPresetId = 'last_travel_preset_id';
  static const _keyShowWeekends = 'show_weekends';

  // -- Reactive notifiers ---------------------------------------------------
  final showWeekends = ValueNotifier<bool>(false);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    showWeekends.value = prefs.getBool(_keyShowWeekends) ?? false;
  }

  // -- Last-used period/preset ----------------------------------------------

  Future<String?> getLastWorkPeriodId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPeriodId);
  }

  Future<void> setLastWorkPeriodId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_keyPeriodId);
    } else {
      await prefs.setString(_keyPeriodId, id);
    }
  }

  Future<String?> getLastTravelPresetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPresetId);
  }

  Future<void> setLastTravelPresetId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_keyPresetId);
    } else {
      await prefs.setString(_keyPresetId, id);
    }
  }

  // -- Weekend visibility ---------------------------------------------------

  Future<bool> getShowWeekends() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowWeekends) ?? false;
  }

  Future<void> setShowWeekends(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowWeekends, show);
    showWeekends.value = show;
  }
}
