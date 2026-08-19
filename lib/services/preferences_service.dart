import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's last-selected work period and travel preset IDs
/// so they are pre-selected the next time a day is started or added.
///
/// Uses local device storage — no database calls.
class PreferencesService {
  PreferencesService._();
  static final PreferencesService _instance = PreferencesService._();
  factory PreferencesService() => _instance;

  static const _keyPeriodId = 'last_work_period_id';
  static const _keyPresetId = 'last_travel_preset_id';

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
}
