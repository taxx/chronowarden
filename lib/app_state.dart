import 'package:flutter/foundation.dart';

import 'models/time_log.dart';
import 'models/travel_preset.dart';
import 'models/work_period_setting.dart';
import 'services/time_log_service.dart';
import 'services/travel_preset_service.dart';
import 'services/work_period_service.dart';
import 'services/supabase_service.dart';
import 'utils/csv_import.dart';

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
  bool _tablesReady = false;
  String? _lastError;  // last user-facing error message

  TimeLog? get todayLog => _todayLog;
  List<TimeLog> get allLogs => _allLogs;
  List<WorkPeriodSetting> get workPeriods => _periodsList;
  List<TravelPreset> get travelPresets => _presetsList;
  int get timeBankMinutes => _timeBankMinutes;
  bool get tablesReady => _tablesReady;
  String? get lastError => _lastError;

  /// Clear the last error after the UI has consumed it.
  void clearLastError() => _lastError = null;

  WorkPeriodSetting? get activePeriod {
    final now = DateTime.now();
    for (final p in _periodsList) {
      if (p.isActiveOn(now)) return p;
    }
    return null;
  }

  // -- helpers: is item in use by any time log? ----------------------
  bool isPeriodInUse(WorkPeriodSetting period) {
    return _allLogs.any((l) => l.expectedMinutes == period.expectedMinutes);
  }

  bool isPresetInUse(TravelPreset preset) {
    return _allLogs.any((l) => l.overheadMinutes == preset.defaultOverheadMinutes);
  }

  // -- loading -------------------------------------------------------
  Future<bool> refresh() async {
    try {
      await Future.wait([
        _loadToday(),
        _loadAll(),
        _loadPeriods(),
        _loadPresets(),
        _loadBalance(),
      ]);
      _tablesReady = true;
      _lastError = null;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('could not find the table') || msg.contains('relation')) {
        _tablesReady = false;
      } else {
        if (!_tablesReady) {
          _lastError = e.toString();
        }
      }
    }
    notifyListeners();
    return _tablesReady;
  }

  Future<void> _loadToday() async => _todayLog = await logs.today();
  Future<void> _loadAll() async => _allLogs = await logs.all();
  Future<void> _loadPeriods() async => _periodsList = await periods.all();
  Future<void> _loadPresets() async => _presetsList = await presets.all();
  Future<void> _loadBalance() async => _timeBankMinutes = await logs.totalOvertime();

  // -- work-period CRUD ----------------------------------------------
  Future<void> addWorkPeriod(WorkPeriodSetting p) async {
    try {
      await periods.insert(p);
      await _loadPeriods();
    } catch (e) { _lastError = e.toString(); }
    notifyListeners();
  }

  Future<void> updateWorkPeriod(WorkPeriodSetting p) async {
    try {
      await periods.update(p.id!, p.toJson()..remove('id'));
      await _loadPeriods();
    } catch (e) { _lastError = e.toString(); }
    notifyListeners();
  }

  Future<void> deleteWorkPeriod(String id) async {
    try {
      await periods.delete(id);
      await _loadPeriods();
    } catch (e) { _lastError = e.toString(); }
    notifyListeners();
  }

  // -- travel-preset CRUD --------------------------------------------
  Future<void> addTravelPreset(TravelPreset p) async {
    try {
      await presets.insert(p);
      await _loadPresets();
    } catch (e) { _lastError = e.toString(); }
    notifyListeners();
  }

  Future<void> updateTravelPreset(TravelPreset p) async {
    try {
      await presets.update(p.id!, p.toJson()..remove('id'));
      await _loadPresets();
    } catch (e) { _lastError = e.toString(); }
    notifyListeners();
  }

  Future<void> deleteTravelPreset(String id) async {
    try {
      await presets.delete(id);
      await _loadPresets();
    } catch (e) { _lastError = e.toString(); }
    notifyListeners();
  }

  // -- start today's workday -----------------------------------------
  Future<TimeLog> startDay({
    required String startTime,
    required int expectedMinutes,
    int lunchMinutes = 0,
    int flexMinutes = 0,
    int morningOverheadMinutes = 0,
    int morningProductiveCommuteMinutes = 0,
    int eveningOverheadMinutes = 0,
    int eveningProductiveCommuteMinutes = 0,
  }) async {
    final date = _dateStr(DateTime.now());
    final existing = await logs.activeToday();
    if (existing != null) return existing;

    final newLog = TimeLog(
      date: date,
      startTime: startTime,
      expectedMinutes: expectedMinutes,
      lunchMinutes: lunchMinutes,
      flexMinutes: flexMinutes,
      morningOverheadMinutes: morningOverheadMinutes,
      morningProductiveCommuteMinutes: morningProductiveCommuteMinutes,
      eveningOverheadMinutes: eveningOverheadMinutes,
      eveningProductiveCommuteMinutes: eveningProductiveCommuteMinutes,
      overtimeMinutes: 0,
    );
    final saved = await logs.insert(newLog);
    _todayLog = saved;
    notifyListeners();
    return saved;
  }

  // -- update flex minutes on the active day -------------------------
  Future<void> updateFlexMinutes(int flexMinutes) async {
    final log = _todayLog;
    if (log == null || log.id == null) return;
    await logs.update(log.id!, {'flex_minutes': flexMinutes});
    await _loadToday();
    notifyListeners();
  }

  // -- update lunch on the active day --------------------------------
  Future<void> updateLunchMinutes(int lunchMinutes) async {
    final log = _todayLog;
    if (log == null || log.id == null) return;
    await logs.update(log.id!, {'lunch_minutes': lunchMinutes});
    await _loadToday();
    notifyListeners();
  }

  // -- update commute values on the active day ---------------------
  Future<void> updateCommuteValues({
    required int morningOverheadMinutes,
    required int morningProductiveCommuteMinutes,
    required int eveningOverheadMinutes,
    required int eveningProductiveCommuteMinutes,
  }) async {
    final log = _todayLog;
    if (log == null || log.id == null) return;
    await logs.update(log.id!, {
      'morning_overhead_minutes': morningOverheadMinutes,
      'morning_productive_commute_minutes': morningProductiveCommuteMinutes,
      'evening_overhead_minutes': eveningOverheadMinutes,
      'evening_productive_commute_minutes': eveningProductiveCommuteMinutes,
    });
    await _loadToday();
    notifyListeners();
  }

  // -- edit an existing day ------------------------------------------
  Future<void> editDay(TimeLog log) async {
    final id = log.id;
    if (id == null) return;

    final overtime = log.calculateOvertimeMinutes();
    await logs.update(id, {
      'start_time': log.startTime,
      'end_time': log.endTime,
      'expected_minutes': log.expectedMinutes,
      'overhead_minutes': log.overheadMinutes,
      'lunch_minutes': log.lunchMinutes,
      'overtime_minutes': overtime,
      'productive_commute_minutes': log.productiveCommuteMinutes,
      'note': log.note,
    });

    await Future.wait([_loadToday(), _loadAll(), _loadBalance()]);
    notifyListeners();
  }

  // -- delete a day --------------------------------------------------
  Future<void> deleteDay(String id) async {
    try {
      await logs.delete(id);
      await Future.wait([_loadToday(), _loadAll(), _loadBalance()]);
    } catch (e) { _lastError = e.toString(); }
    notifyListeners();
  }

  // -- add a generic (potentially past) day --------------------------
  Future<TimeLog> addDay({
    required String date,
    required String startTime,
    required String endTime,
    required int expectedMinutes,
    int lunchMinutes = 0,
    int flexMinutes = 0,
    int morningOverheadMinutes = 0,
    int morningProductiveCommuteMinutes = 0,
    int eveningOverheadMinutes = 0,
    int eveningProductiveCommuteMinutes = 0,
    String? note,
  }) async {
    final newLog = TimeLog(
      date: date,
      startTime: startTime,
      endTime: endTime,
      expectedMinutes: expectedMinutes,
      lunchMinutes: lunchMinutes,
      flexMinutes: flexMinutes,
      morningOverheadMinutes: morningOverheadMinutes,
      morningProductiveCommuteMinutes: morningProductiveCommuteMinutes,
      eveningOverheadMinutes: eveningOverheadMinutes,
      eveningProductiveCommuteMinutes: eveningProductiveCommuteMinutes,
      overtimeMinutes: 0,
      note: note,
    );
    final overtime = newLog.calculateOvertimeMinutes();
    final saved = await logs.insert(newLog.copyWith(overtimeMinutes: overtime));
    await Future.wait([_loadToday(), _loadAll(), _loadBalance()]);
    notifyListeners();
    return saved;
  }

  // -- CSV import -----------------------------------------------------

  /// Import days from a CSV string. Each row is parsed, validated, then
  /// inserted as a new [TimeLog]. Existing dates are skipped to prevent
  /// accidental overwrites.
  Future<ImportResult> importDaysFromCsv(String csv) async {
    final userId = _getUserId();
    final existingDates = _allLogs.map((l) => l.date).toSet();
    final result = parseCsvTimeLogs(csv, userId: userId, existingDates: existingDates);

    // Insert each valid log, recalculating overtime
    for (final log in result.imported) {
      final overtime = log.calculateOvertimeMinutes();
      final updated = log.copyWith(overtimeMinutes: overtime);
      try {
        await logs.insert(updated);
      } catch (e) {
        result.errors.add('Failed to insert ${log.date}: $e');
      }
    }

    // Reload fresh data
    await Future.wait([_loadToday(), _loadAll(), _loadBalance()]);
    notifyListeners();
    return result;
  }

  String? _getUserId() {
    final session = SupabaseService.instance.client.auth.currentSession;
    return session?.user.id;
  }

  // -- stop today's workday ------------------------------------------
  Future<void> stopDay(String endTime, {int lunchMinutes = 0, int flexMinutes = 0}) async {
    final log = _todayLog;
    if (log == null) return;

    final computed = log.copyWith(endTime: endTime, lunchMinutes: lunchMinutes, flexMinutes: flexMinutes);
    final overtime = computed.calculateOvertimeMinutes();
    final id = log.id;
    if (id == null) return;

    await logs.update(id, {
      'end_time': endTime,
      'lunch_minutes': lunchMinutes,
      'flex_minutes': flexMinutes,
      'overtime_minutes': overtime,
    });

    await Future.wait([_loadToday(), _loadAll(), _loadBalance()]);
    notifyListeners();
  }

  String _dateStr(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
