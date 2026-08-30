import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/time_log.dart';
import 'models/travel_preset.dart';
import 'models/work_config.dart';
import 'services/time_log_service.dart';
import 'services/travel_preset_service.dart';
import 'services/work_config_service.dart';
import 'services/supabase_service.dart';
import 'services/transit_service.dart';
import 'models/departure_info.dart';
import 'models/transit_config.dart';
import 'utils/csv_import.dart';

/// Central app state — singleton ChangeNotifier holding all data + actions.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState _instance = AppState._();
  factory AppState() => _instance;

  // Lazily initialised — only accessed after Supabase is ready.
  TimeLogService? _logs;
  WorkConfigService? _config;
  TravelPresetService? _presets;

  TimeLogService get logs => _logs ??= TimeLogService();
  WorkConfigService get config => _config ??= WorkConfigService();
  TravelPresetService get presets => _presets ??= TravelPresetService();
  TransitService get transit => TransitService();

  // -- cached data ---------------------------------------------------
  TimeLog? _todayLog;
  RealtimeChannel? _rtChannel;
  List<TimeLog> _allLogs = [];
  WorkConfig? _workConfig;
  List<TravelPreset> _presetsList = [];
  int _timeBankMinutes = 0;
  bool _tablesReady = false;
  String? _lastError;  // last user-facing error message

  // -- lunch timer state (in-memory only, not persisted) ------------
  DateTime? _lunchStartTime;
  DateTime? _lunchEndTime;

  DateTime? get lunchStartTime => _lunchStartTime;
  DateTime? get lunchEndTime => _lunchEndTime;

  /// True when lunch timer is running (started but not stopped).
  bool get lunchActive => _lunchStartTime != null && _lunchEndTime == null;

  /// Record the moment lunch started. Clears any previous stop time.
  void startLunch() {
    _lunchStartTime = DateTime.now();
    _lunchEndTime = null;
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

    await logs.update(log.id!, {'lunch_minutes': lunchMinutes});
    await _loadToday();

    _lunchStartTime = null;
    _lunchEndTime = null;
    notifyListeners();
  }

  /// Reset lunch timer without saving (e.g., user cancelled).
  void resetLunchTimer() {
    _lunchStartTime = null;
    _lunchEndTime = null;
    notifyListeners();
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

  /// Transit config (loaded lazily).
  TransitConfig get transitConfig => transit.config;

  /// Cached upcoming departures.
  List<DepartureInfo>? get upcomingDepartures => transit.cachedDepartures;

  /// Refresh transit data if enabled.
  Future<void> refreshTransit() async {
    final cfg = transit.config;
    if (!cfg.enabled) return;
    await transit.fetchDepartures(cfg.departureSiteId);
    notifyListeners();
  }

  /// Returns the expected work minutes for [date], derived from the
  /// work config (default vs reduced period by ISO week).
  int expectedMinutesForDate(DateTime date) {
    if (_workConfig != null) {
      return _workConfig!.expectedMinutesForDate(date);
    }
    return 480; // fallback default
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
        _loadConfig(),
        _loadPresets(),
        _loadBalance(),
        _loadTransitConfig(),
      ]);
      _tablesReady = true;
      _lastError = null;

      // Subscribe to realtime changes for the current user's time logs
      _subscribeRealtime();
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

  // -- realtime sync ------------------------------------------------

  /// Subscribe to changes on the user's time_logs via Supabase Realtime.
  ///
  /// When another device starts/stops a day, the subscription fires and
  /// we re-fetch the affected row without needing a page reload.
  void _subscribeRealtime() {
    final session = SupabaseService.instance.client.auth.currentSession;
    final userId = session?.user.id;
    if (userId == null) return;

    // Unsubscribe any existing channel before creating a new one
    _unsubscribeRealtime();

    final client = SupabaseService.instance.client;
    _rtChannel = client.channel(
      'public:time_logs',
      opts: RealtimeChannelConfig(
        ack: true,
      ),
    );

    // Listen for INSERT, UPDATE, DELETE on time_logs filtered by user_id
    _rtChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'time_logs',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        _onRealtimeEvent(payload);
      },
    );

    _rtChannel!.subscribe();
  }

  /// Handle a Realtime event — re-fetch today's log if the changed row
  /// matches today's date.
  void _onRealtimeEvent(PostgresChangePayload payload) {
    final newRecord = payload.newRecord;
    if (newRecord.isEmpty) return;

    final newDate = newRecord['date'] as String?;
    final todayStr = _dateStr(DateTime.now());
    if (newDate == todayStr) {
      // Today's row changed — re-fetch todayLog
      _loadToday().then((_) => notifyListeners());
    }

    // Always re-fetch balance since overtime might have changed
    _loadBalance().then((_) => notifyListeners());
  }

  /// Unsubscribe from Realtime and release the channel.
  void _unsubscribeRealtime() {
    _rtChannel?.unsubscribe();
    _rtChannel = null;
  }

  /// Called when the user signs out — clean up the Realtime subscription.
  void onSignOut() {
    _unsubscribeRealtime();
    _todayLog = null;
    _allLogs = [];
    _workConfig = null;
    _presetsList = [];
    _timeBankMinutes = 0;
    _tablesReady = false;
    _lunchStartTime = null;
    _lunchEndTime = null;
    transit.onLogout();
    notifyListeners();
  }

  Future<void> _loadToday() async => _todayLog = await logs.today();
  Future<void> _loadAll() async => _allLogs = await logs.all();
  Future<void> _loadConfig() async => _workConfig = await config.get();
  Future<void> _loadPresets() async => _presetsList = await presets.all();
  Future<void> _loadBalance() async => _timeBankMinutes = await logs.totalOvertime();
  Future<void> _loadTransitConfig() async => await transit.loadConfig();

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
  Future<void> stopDay(String endTime, {int lunchMinutes = 0}) async {
    final log = _todayLog;
    if (log == null) return;

    final computed = log.copyWith(endTime: endTime, lunchMinutes: lunchMinutes);
    final overtime = computed.calculateOvertimeMinutes();
    final id = log.id;
    if (id == null) return;

    await logs.update(id, {
      'end_time': endTime,
      'lunch_minutes': lunchMinutes,
      'overtime_minutes': overtime,
    });

    await Future.wait([_loadToday(), _loadAll(), _loadBalance()]);
    notifyListeners();
  }

  String _dateStr(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
