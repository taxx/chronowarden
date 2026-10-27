import 'dart:async';

import 'package:flutter/widgets.dart';

import 'models/time_log.dart';
import 'models/travel_preset.dart';
import 'models/work_config.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/realtime_service.dart';
import 'services/time_log_service.dart';
import 'services/travel_preset_service.dart';
import 'services/work_config_service.dart';
import 'services/transit_service.dart';
import 'services/user_settings_service.dart';
import 'models/transit_config.dart';
import 'utils/csv_import.dart';

/// Central app state — singleton ChangeNotifier holding all data + actions.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState _instance = AppState._();
  factory AppState() => _instance;

  // Lazily initialised — only accessed once the API session is ready.
  TimeLogService? _logs;
  WorkConfigService? _config;
  TravelPresetService? _presets;

  TimeLogService get logs => _logs ??= TimeLogService();
  WorkConfigService get config => _config ??= WorkConfigService();
  TravelPresetService get presets => _presets ??= TravelPresetService();
  TransitService get transit => TransitService();

  // -- cached data ---------------------------------------------------
  TimeLog? _todayLog;
  List<TimeLog> _allLogs = [];
  WorkConfig? _workConfig;
  List<TravelPreset> _presetsList = [];
  int _timeBankMinutes = 0;
  bool _tablesReady = false;
  String? _lastError;  // last user-facing error message

  // -- lunch timer state (persisted via encrypted_data for cross-device sync)
  DateTime? _lunchStartTime;
  DateTime? _lunchEndTime;
  bool _observerAdded = false;

  DateTime? get lunchStartTime => _lunchStartTime;
  DateTime? get lunchEndTime => _lunchEndTime;

  /// True when lunch timer is running (started but not stopped).
  bool get lunchActive => _lunchStartTime != null && _lunchEndTime == null;

  /// Record the moment lunch started and persist to DB for cross-device sync.
  void startLunch() {
    _lunchStartTime = DateTime.now();
    _lunchEndTime = null;
    _persistLunchStarted();
    notifyListeners();
  }

  /// Record the moment lunch stopped, calculate duration, update stored
  /// lunch minutes, and reset timer state.
  Future<void> stopLunch([int? overrideMinutes]) async {
    final log = _todayLog;
    if (log == null || log.id == null) {
      _lunchStartTime = null;
      _lunchEndTime = null;
      notifyListeners();
      return;
    }

    if (_lunchStartTime == null) return;

    _lunchEndTime = DateTime.now();
    final calculatedMinutes =
        _lunchEndTime!.difference(_lunchStartTime!).inMinutes;
    final lunchMinutes = overrideMinutes ?? calculatedMinutes;

    await logs.update(log.id!, {
      'lunch_minutes': lunchMinutes,
      'lunch_started_at': null,  // clear cross-device lunch state
    });
    await _loadToday();

    _lunchStartTime = null;
    _lunchEndTime = null;
    notifyListeners();
  }

  /// Reset lunch timer without saving (e.g., user cancelled).
  /// Also clears the persisted lunch_started_at so other devices don't
  /// see a stale active lunch.
  void resetLunchTimer() {
    final log = _todayLog;
    if (log?.id != null) {
      logs.update(log!.id!, {'lunch_started_at': null});
    }
    _lunchStartTime = null;
    _lunchEndTime = null;
    notifyListeners();
  }

  // -- non-work (errands) timer state --------------------------------
  DateTime? _nonWorkStartTime;
  DateTime? _nonWorkEndTime;
  bool _nonWorkEnabled = true;

  DateTime? get nonWorkStartTime => _nonWorkStartTime;
  DateTime? get nonWorkEndTime => _nonWorkEndTime;

  /// True when the non-work timer is running (started but not stopped).
  bool get nonWorkActive => _nonWorkStartTime != null && _nonWorkEndTime == null;

  /// Whether the non-work-time feature is enabled (Settings; default on).
  bool get nonWorkEnabled => _nonWorkEnabled;

  /// Record the moment non-work time started and persist for cross-device sync.
  void startNonWork() {
    _nonWorkStartTime = DateTime.now();
    _nonWorkEndTime = null;
    _persistNonWorkStarted();
    notifyListeners();
  }

  /// Record the moment non-work time stopped, calculate the duration, update
  /// the stored minutes, and reset the timer state.
  Future<void> stopNonWork([int? overrideMinutes]) async {
    final log = _todayLog;
    if (log == null || log.id == null) {
      _nonWorkStartTime = null;
      _nonWorkEndTime = null;
      notifyListeners();
      return;
    }

    if (_nonWorkStartTime == null) return;

    _nonWorkEndTime = DateTime.now();
    final calculatedMinutes =
        _nonWorkEndTime!.difference(_nonWorkStartTime!).inMinutes;
    final nonWorkMinutes = overrideMinutes ?? calculatedMinutes;

    await logs.update(log.id!, {
      'non_work_minutes': nonWorkMinutes,
      'non_work_started_at': null, // clear cross-device timer state
    });
    await _loadToday();

    _nonWorkStartTime = null;
    _nonWorkEndTime = null;
    notifyListeners();
  }

  /// Reset the non-work timer without saving (e.g. user cancelled).
  void resetNonWorkTimer() {
    final log = _todayLog;
    if (log?.id != null) {
      logs.update(log!.id!, {'non_work_started_at': null});
    }
    _nonWorkStartTime = null;
    _nonWorkEndTime = null;
    notifyListeners();
  }

  /// Enable/disable the non-work-time feature (persisted cross-device).
  Future<void> setNonWorkEnabled(bool value) async {
    _nonWorkEnabled = value;
    notifyListeners();
    await UserSettingsService().setNonWorkEnabled(value);
  }

  TimeLog? get todayLog => _todayLog;
  List<TimeLog> get allLogs => _allLogs;
  WorkConfig? get workConfig => _workConfig;
  List<TravelPreset> get travelPresets => _presetsList;
  int get timeBankMinutes => _timeBankMinutes;
  bool get tablesReady => _tablesReady;
  String? get lastError => _lastError;

  /// Clear the last error after the UI has consumed it.
  void clearLastError() => _lastError = null;

  /// Projected leave time for [log], adjusted for a lunch break that is
  /// currently running.
  ///
  /// The stored [TimeLog.lunchMinutes] only updates when the timer stops, so
  /// while lunch is active we take whichever is longer: the planned lunch or
  /// the lunch elapsed so far. Without this an overrunning break would make
  /// the UI (and the wrap-up notification) point at an obsolete leave time.
  DateTime effectiveLeaveTime(TimeLog log) {
    final now = DateTime.now();
    var lunch = log.lunchMinutes;
    var nonWork = log.nonWorkMinutes;
    if (lunchActive && _lunchStartTime != null) {
      final elapsed = now.difference(_lunchStartTime!).inMinutes;
      if (elapsed > lunch) lunch = elapsed;
    }
    if (nonWorkActive && _nonWorkStartTime != null) {
      final elapsed = now.difference(_nonWorkStartTime!).inMinutes;
      if (elapsed > nonWork) nonWork = elapsed;
    }
    return log.leaveTimeWithBreaks(
      lunchMinutes: lunch,
      nonWorkMinutes: nonWork,
    );
  }

  /// Transit config (loaded lazily).
  TransitConfig get transitConfig => transit.config;

  /// Apply a transit config change immediately (so nav visibility and the
  /// My Day transit card update at once), then persist it to encrypted
  /// user_settings. Keeps all transit writes flowing through AppState.
  Future<void> saveTransitConfig(TransitConfig cfg) async {
    transit.applyConfig(cfg);
    notifyListeners();
    await transit.saveConfig(cfg);
    notifyListeners();
  }

  // Legacy departure methods removed — using journey planner API instead
  // Cached journey plans accessed via TransitService().cachedJourneys

  /// Returns the expected work minutes for [date], derived from the
  /// work config (default vs reduced period by ISO week).
  int expectedMinutesForDate(DateTime date) {
    if (_workConfig != null) {
      return _workConfig!.expectedMinutesForDate(date);
    }
    return 480; // fallback default
  }

  /// Best-effort check for whether any logged day matches [preset].
  ///
  /// Logs don't store a preset id, so we compare the full per-direction
  /// commute profile. Comparing only the (rounded) total overhead produced
  /// false positives when two presets happened to share the same total.
  bool isPresetInUse(TravelPreset preset) {
    return _allLogs.any((l) =>
        l.morningOverheadMinutes == preset.morningOverheadMinutes &&
        l.morningProductiveCommuteMinutes ==
            preset.morningProductiveCommuteMinutes &&
        l.eveningOverheadMinutes == preset.eveningOverheadMinutes &&
        l.eveningProductiveCommuteMinutes ==
            preset.eveningProductiveCommuteMinutes);
  }

  /// The travel preset whose commute profile matches [log], if any.
  ///
  /// Day logs don't store a preset id; matching the commute values lets an
  /// active day map back to its preset across devices (the log is synced, the
  /// last-used preset id is per-device).
  TravelPreset? presetMatchingLog(TimeLog log) =>
      findPresetForLog(_presetsList, log);

  // -- loading -------------------------------------------------------
  Future<bool> refresh() async {
    try {
      await Future.wait([
        _loadToday(),
        _loadAllAndBalance(),
        _loadConfig(),
        _loadPresets(),
        _loadTransitConfig(),
        _loadNonWorkEnabled(),
      ]);
      _tablesReady = true;
      _lastError = null;

      // Subscribe to realtime changes for the current user's time logs
      _subscribeRealtime();

      // Register app lifecycle observer (only once)
      if (!_observerAdded) {
        _LifecycleObserver._register(this);
        _observerAdded = true;
      }
    } catch (e) {
      _lastError = e is ApiException ? e.message : e.toString();
    }
    notifyListeners();
    return _tablesReady;
  }

  // -- realtime sync ------------------------------------------------

  /// Subscribe to changes on the user's time_logs via the API's SSE stream.
  ///
  /// When another device starts/stops a day, an event arrives and we re-fetch
  /// the affected data without needing a page reload.
  void _subscribeRealtime() {
    final token = ApiClient().token;
    if (_getUserId() == null || token == null) return;

    RealtimeService().start(token: token, onEvent: _onRealtimeEvent);
  }

  /// Handle a realtime event — re-fetch affected data so all views
  /// (My Day, Overview, History) update without a page reload.
  void _onRealtimeEvent(RealtimeEvent event) {
    if (event.table != 'time_logs') return;

    final newDate = event.row['date'] as String?;
    final todayStr = _dateStr(DateTime.now());

    // Always re-fetch the full log list so Overview/History refresh
    Future.wait([
      if (newDate == todayStr) _loadToday(),
      _loadAllAndBalance(),
    ]).then((_) {
      // Restore lunch timer state from the decrypted todayLog
      _restoreLunchFromLog();
      notifyListeners();
    });
  }

  /// Stop the realtime stream.
  void _unsubscribeRealtime() {
    RealtimeService().stop();
  }

  /// Called when the user signs out — clean up the Realtime subscription.
  void onSignOut() {
    _unsubscribeRealtime();
    if (_observerAdded) {
      _LifecycleObserver._unregister();
      _observerAdded = false;
    }
    _todayLog = null;
    _allLogs = [];
    _workConfig = null;
    _presetsList = [];
    _timeBankMinutes = 0;
    _tablesReady = false;
    _lunchStartTime = null;
    _lunchEndTime = null;
    _nonWorkStartTime = null;
    _nonWorkEndTime = null;
    transit.onLogout();
    notifyListeners();
  }

  Future<void> _loadToday() async {
    _todayLog = await logs.today();
    _restoreLunchFromLog();
  }
  /// Fetch all logs once and derive the time-bank balance from them.
  /// Previously `_loadAll()` + `_loadBalance()` each fetched + decrypted the
  /// full table, doubling the work on every refresh and realtime event.
  Future<void> _loadAllAndBalance() async {
    _allLogs = await logs.all();
    _timeBankMinutes = _allLogs.fold<int>(0, (sum, l) => sum + l.overtimeMinutes);
  }

  Future<void> _loadConfig() async => _workConfig = await config.get();
  Future<void> _loadPresets() async => _presetsList = await presets.all();
  Future<void> _loadTransitConfig() async => await transit.loadConfig();

  /// Load the non-work-time feature toggle (defaults to enabled on error).
  Future<void> _loadNonWorkEnabled() async {
    try {
      _nonWorkEnabled = await UserSettingsService().getNonWorkEnabled();
    } catch (_) {
      _nonWorkEnabled = true;
    }
  }

  /// Persist lunch_started_at to encrypted_data so other devices
  /// see the active lunch state via Realtime.
  void _persistLunchStarted() {
    final log = _todayLog;
    final id = log?.id;
    if (id == null) return;
    final iso = _lunchStartTime!.toUtc().toIso8601String();
    logs.update(id, {'lunch_started_at': iso});
  }

  /// Persist non_work_started_at to encrypted_data so other devices
  /// see the active non-work state via Realtime.
  void _persistNonWorkStarted() {
    final log = _todayLog;
    final id = log?.id;
    if (id == null) return;
    final iso = _nonWorkStartTime!.toUtc().toIso8601String();
    logs.update(id, {'non_work_started_at': iso});
  }

  /// Restore in-memory break-timer state from the decrypted [_todayLog].
  /// Called after loading today's log or receiving a Realtime update.
  void _restoreLunchFromLog() {
    final log = _todayLog;
    if (log?.lunchStartedAt == null || log!.lunchStartedAt!.isEmpty) {
      _lunchStartTime = null;
      _lunchEndTime = null;
    } else {
      _lunchStartTime = DateTime.parse(log.lunchStartedAt!).toLocal();
      _lunchEndTime = null;
    }
    if (log?.nonWorkStartedAt == null || log!.nonWorkStartedAt!.isEmpty) {
      _nonWorkStartTime = null;
      _nonWorkEndTime = null;
    } else {
      _nonWorkStartTime = DateTime.parse(log.nonWorkStartedAt!).toLocal();
      _nonWorkEndTime = null;
    }
  }

  // -- work-config CRUD ----------------------------------------------
  Future<void> saveWorkConfig(WorkConfig c) async {
    try {
      await config.save(c);
      await _loadConfig();
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
    int nonWorkMinutes = 0,
    int flexMinutes = 0,
    int morningOverheadMinutes = 0,
    int morningProductiveCommuteMinutes = 0,
    int eveningOverheadMinutes = 0,
    int eveningProductiveCommuteMinutes = 0,
    String? note,
  }) async {
    final date = _dateStr(DateTime.now());
    final existing = await logs.activeToday();
    if (existing != null) return existing;

    final newLog = TimeLog(
      date: date,
      startTime: startTime,
      expectedMinutes: expectedMinutes,
      lunchMinutes: lunchMinutes,
      nonWorkMinutes: nonWorkMinutes,
      flexMinutes: flexMinutes,
      morningOverheadMinutes: morningOverheadMinutes,
      morningProductiveCommuteMinutes: morningProductiveCommuteMinutes,
      eveningOverheadMinutes: eveningOverheadMinutes,
      eveningProductiveCommuteMinutes: eveningProductiveCommuteMinutes,
      overtimeMinutes: 0,
      note: note,
    );
    final saved = await logs.insert(newLog);
    _todayLog = saved;
    notifyListeners();
    return saved;
  }

  // -- update lunch on the active day --------------------------------
  Future<void> updateLunchMinutes(int lunchMinutes) async {
    final log = _todayLog;
    if (log == null || log.id == null) return;
    await logs.update(log.id!, {'lunch_minutes': lunchMinutes});
    await _loadToday();
    notifyListeners();
  }

  // -- update non-work time on the active day -----------------------
  Future<void> updateNonWorkMinutes(int nonWorkMinutes) async {
    final log = _todayLog;
    if (log == null || log.id == null) return;
    await logs.update(log.id!, {'non_work_minutes': nonWorkMinutes});
    await _loadToday();
    notifyListeners();
  }

  // -- update banked-time (flex) withdrawal on the active day ------
  /// Adjusts how much banked overtime the user plans to withdraw as
  /// personal time. A live projection only — flex is intentionally NOT
  /// used in edit-day / add-day calculations.
  Future<void> updateFlexMinutes(int flexMinutes) async {
    final log = _todayLog;
    if (log == null || log.id == null) return;
    await logs.update(log.id!, {'flex_minutes': flexMinutes});
    await _loadToday();
    notifyListeners();
  }

  // -- update the note on the active day ----------------------------
  Future<void> updateNote(String? note) async {
    final log = _todayLog;
    if (log == null || log.id == null) return;
    final trimmed = note?.trim();
    await logs.update(log.id!, {
      'note': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    });
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
      'non_work_minutes': log.nonWorkMinutes,
      'overtime_minutes': overtime,
      'productive_commute_minutes': log.productiveCommuteMinutes,
      'note': log.note,
    });

    await Future.wait([_loadToday(), _loadAllAndBalance()]);
    notifyListeners();
  }

  // -- delete a day --------------------------------------------------
  Future<void> deleteDay(String id) async {
    try {
      await logs.delete(id);
      await Future.wait([_loadToday(), _loadAllAndBalance()]);
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
    int nonWorkMinutes = 0,
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
      nonWorkMinutes: nonWorkMinutes,
      morningOverheadMinutes: morningOverheadMinutes,
      morningProductiveCommuteMinutes: morningProductiveCommuteMinutes,
      eveningOverheadMinutes: eveningOverheadMinutes,
      eveningProductiveCommuteMinutes: eveningProductiveCommuteMinutes,
      overtimeMinutes: 0,
      note: note,
    );
    final overtime = newLog.calculateOvertimeMinutes();
    final saved = await logs.insert(newLog.copyWith(overtimeMinutes: overtime));
    await Future.wait([_loadToday(), _loadAllAndBalance()]);
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
    await Future.wait([_loadToday(), _loadAllAndBalance()]);
    notifyListeners();
    return result;
  }

  String? _getUserId() => AuthService().profile?.id;

  // -- stop today's workday ------------------------------------------
  Future<void> stopDay(String endTime, {int lunchMinutes = 0, int nonWorkMinutes = 0}) async {
    final log = _todayLog;
    if (log == null) return;

    final computed = log.copyWith(
      endTime: endTime,
      lunchMinutes: lunchMinutes,
      nonWorkMinutes: nonWorkMinutes,
    );
    final overtime = computed.calculateOvertimeMinutes();
    final id = log.id;
    if (id == null) return;

    await logs.update(id, {
      'end_time': endTime,
      'lunch_minutes': lunchMinutes,
      'non_work_minutes': nonWorkMinutes,
      'overtime_minutes': overtime,
    });

    await Future.wait([_loadToday(), _loadAllAndBalance()]);
    notifyListeners();
  }

  String _dateStr(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Lightweight app lifecycle observer — refreshes AppState when the app comes
// to the foreground so My Day, Overview, etc. don't show stale data.
// ---------------------------------------------------------------------------

class _LifecycleObserver with WidgetsBindingObserver {
  static final _LifecycleObserver _instance = _LifecycleObserver._();
  _LifecycleObserver._();

  static void _register(AppState state) {
    WidgetsBinding.instance.addObserver(_instance);
    _instance._state = state;
  }

  static void _unregister() {
    WidgetsBinding.instance.removeObserver(_instance);
    _instance._state = null;
  }

  AppState? _state;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _state?.refresh();
    }
  }
}
