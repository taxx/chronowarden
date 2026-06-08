import 'package:flutter/foundation.dart';

import 'models/time_log.dart';
import 'models/travel_preset.dart';
import 'models/work_period_setting.dart';
import 'services/time_log_service.dart';
import 'services/travel_preset_service.dart';
import 'services/work_period_service.dart';

/// Central app state — singleton ChangeNotifier holding all data + actions.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState _instance = AppState._();
  factory AppState() => _instance;

  // Lazily initialised — only accessed after Supabase is ready.
  TimeLogService? _logs;
  WorkPeriodService? _periods;
  TravelPresetService? _presets;

  TimeLogService get logs => _logs ??= TimeLogService();
  WorkPeriodService get periods => _periods ??= WorkPeriodService();
  TravelPresetService get presets => _presets ??= TravelPresetService();

  // -- cached data ---------------------------------------------------
  TimeLog? _todayLog;
  List<TimeLog> _allLogs = [];
  List<WorkPeriodSetting> _periodsList = [];
  List<TravelPreset> _presetsList = [];
  int _timeBankMinutes = 0;

  TimeLog? get todayLog => _todayLog;
  List<TimeLog> get allLogs => _allLogs;
  List<WorkPeriodSetting> get workPeriods => _periodsList;
  List<TravelPreset> get travelPresets => _presetsList;
  int get timeBankMinutes => _timeBankMinutes;

  WorkPeriodSetting? get activePeriod {
    final now = DateTime.now();
    for (final p in _periodsList) {
      if (p.isActiveOn(now)) return p;
    }
    return null;
  }

  // -- loading -------------------------------------------------------
  Future<void> refresh() async {
    try {
      await Future.wait([
        _loadToday(),
        _loadAll(),
        _loadPeriods(),
        _loadPresets(),
        _loadBalance(),
      ]);
    } catch (_) {
      // Supabase not connected — keep empty state.
    }
    notifyListeners();
  }

  Future<void> _loadToday() async => _todayLog = await logs.today();
  Future<void> _loadAll() async => _allLogs = await logs.all();
  Future<void> _loadPeriods() async => _periodsList = await periods.all();
  Future<void> _loadPresets() async => _presetsList = await presets.all();
  Future<void> _loadBalance() async => _timeBankMinutes = await logs.totalOvertime();

  // -- work-period CRUD ----------------------------------------------
  Future<void> addWorkPeriod(WorkPeriodSetting p) async {
    await periods.insert(p);
    await _loadPeriods();
    notifyListeners();
  }

  Future<void> deleteWorkPeriod(String id) async {
    await periods.delete(id);
    await _loadPeriods();
    notifyListeners();
  }

  // -- travel-preset CRUD --------------------------------------------
  Future<void> addTravelPreset(TravelPreset p) async {
    await presets.insert(p);
    await _loadPresets();
    notifyListeners();
  }

  Future<void> deleteTravelPreset(String id) async {
    await presets.delete(id);
    await _loadPresets();
    notifyListeners();
  }

  // -- start today's workday -----------------------------------------
  Future<TimeLog> startDay({
    required String startTime,
    required int expectedMinutes,
    required int overheadMinutes,
  }) async {
    final date = _dateStr(DateTime.now());
    final existing = await logs.activeToday();
    if (existing != null) return existing;

    final newLog = TimeLog(
      date: date,
      startTime: startTime,
      expectedMinutes: expectedMinutes,
      overheadMinutes: overheadMinutes,
      overtimeMinutes: 0,
    );
    final saved = await logs.insert(newLog);
    _todayLog = saved;
    notifyListeners();
    return saved;
  }

  // -- stop today's workday ------------------------------------------
  Future<void> stopDay(String endTime) async {
    final log = _todayLog;
    if (log == null) return;

    final computed = log.copyWith(endTime: endTime);
    final overtime = computed.calculateOvertimeMinutes();
    final id = log.id;
    if (id == null) return;

    await logs.update(id, {
      'end_time': endTime,
      'overtime_minutes': overtime,
    });

    await Future.wait([_loadToday(), _loadAll(), _loadBalance()]);
    notifyListeners();
  }

  String _dateStr(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
