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

  static const _keyPresetId = 'last_travel_preset_id';
  static const _keyShowWeekends = 'show_weekends';
  static const _keySliderInterval = 'slider_interval_minutes';
  static const _keyShowTrend = 'show_trend_in_timebank';

  // -- Reactive notifiers ---------------------------------------------------
  final showWeekends = ValueNotifier<bool>(false);
  final sliderInterval = ValueNotifier<int>(5);
  final showTrend = ValueNotifier<bool>(false);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    showWeekends.value = prefs.getBool(_keyShowWeekends) ?? false;
    sliderInterval.value = prefs.getInt(_keySliderInterval) ?? 5;
    showTrend.value = prefs.getBool(_keyShowTrend) ?? false;
  }

  // -- Last-used preset ----------------------------------------------

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

  // -- Slider interval -----------------------------------------------------

  Future<int> getSliderInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySliderInterval) ?? 5;
  }

  Future<void> setSliderInterval(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySliderInterval, minutes);
    sliderInterval.value = minutes;
  }

  // -- Trend line visibility -----------------------------------------------

  Future<bool> getShowTrend() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowTrend) ?? false;
  }

  Future<void> setShowTrend(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowTrend, show);
    showTrend.value = show;
  }
}
