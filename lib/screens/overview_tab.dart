import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/time_log.dart';
import '../models/work_config.dart' show isoWeekNumber;
import '../services/preferences_service.dart';
import '../widgets/edit_day_dialog.dart';

String _fmtMins(int minutes) {
  final abs = minutes.abs();
  final h = abs ~/ 60;
  final m = abs % 60;
  if (h == 0) return '$m min';
  return '${h}h ${m}m';
}

/// Aggregated overview: week / month / year summaries with period navigation.
class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  // Shared offset state so month/year navigation can sync
  int _monthOffset = 0;
  int _yearOffset = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  /// Called when a month card is tapped in the year view.
  void _navigateToMonth(int year, int month) {
    final now = DateTime.now();
    // Calculate offset relative to current month
    final targetMonths = year * 12 + month;
    final currentMonths = now.year * 12 + now.month;
    _monthOffset = targetMonths - currentMonths;
    _tabCtrl.index = 1; // switch to Month tab
    // Force rebuild — the Month _PeriodTab reads _monthOffset from parent
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Week'),
            Tab(text: 'Month'),
            Tab(text: 'Year'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _PeriodTab(period: Period.week),
              _PeriodTab(period: Period.month, externalOffset: _monthOffset, onOffsetChanged: (v) => _monthOffset = v),
              _PeriodTab(period: Period.year, onMonthSelected: _navigateToMonth, externalOffset: _yearOffset, onOffsetChanged: (v) => _yearOffset = v),
            ],
          ),
        ),
      ],
    );
  }
}

enum Period { week, month, year }

// ---------------------------------------------------------------------------
// Period tab — stateful with offset navigation
// ---------------------------------------------------------------------------

class _PeriodTab extends StatefulWidget {
  final Period period;
  final int? externalOffset;
  final void Function(int)? onOffsetChanged;
  final void Function(int year, int month)? onMonthSelected;

  const _PeriodTab({
    required this.period,
    this.externalOffset,
    this.onOffsetChanged,
    this.onMonthSelected,
  });

  @override
  State<_PeriodTab> createState() => _PeriodTabState();
}

class _PeriodTabState extends State<_PeriodTab> {
  late int _offset;
  final _state = AppState();
  final _prefs = PreferencesService();

  @override
  void initState() {
    super.initState();
    _prefs.init();
    _state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _offset = widget.externalOffset ?? 0;
  }

  @override
  void didUpdateWidget(_PeriodTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalOffset != null && widget.externalOffset != oldWidget.externalOffset) {
      setState(() => _offset = widget.externalOffset!);
    }
  }

  void _updateOffset(int newOffset) {
    setState(() => _offset = newOffset);
    widget.onOffsetChanged?.call(newOffset);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_state, _prefs.showWeekends]),
      builder: (context, _) {
        final theme = Theme.of(context);
        final logs = _state.allLogs;

        final filtered = _filterLogs(logs);
        final label = _periodLabel();

        return Column(
          children: [
            // Navigation header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => _updateOffset(_offset - 1),
                    tooltip: 'Previous',
                  ),
                  Text(label, style: theme.textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => _updateOffset(_offset + 1),
                    tooltip: 'Next',
                  ),
                ],
              ),
            ),
            if (_offset != 0)
              Align(
                child: TextButton(
                  onPressed: () => _updateOffset(0),
                  child: const Text('Back to current'),
                ),
              ),
            // Content
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No logs in this period',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : _buildContent(theme, filtered, _offsetDate()),
            ),
          ],
        );
      },
    );
  }

  String _periodLabel() {
    final now = _offsetDate();
    switch (widget.period) {
      case Period.week:
        final weekStart = _weekStart(now);
        final weekEnd = weekStart.add(const Duration(days: 6));
        return 'Wk ${isoWeekNumber(weekStart)} · ${weekStart.day}/${weekStart.month} — ${weekEnd.day}/${weekEnd.month}';
      case Period.month:
        final firstWeek = isoWeekNumber(DateTime(now.year, now.month, 1));
        final lastWeek = isoWeekNumber(DateTime(now.year, now.month + 1, 0));
        return '${_monthYearLabel(now)} · Wk $firstWeek–$lastWeek';
      case Period.year:
        return '${now.year}';
    }
  }

  String _monthYearLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  /// The reference date shifted by [_offset] periods.
  DateTime _offsetDate() {
    final now = DateTime.now();
    switch (widget.period) {
      case Period.week:
        return now.add(Duration(days: _offset * 7));
      case Period.month:
        return DateTime(now.year, now.month + _offset, 1);
      case Period.year:
        return DateTime(now.year + _offset, 1, 1);
    }
  }

  DateTime _weekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // ------------------------------------------------------------------
  // Filtering
  // ------------------------------------------------------------------

  List<TimeLog> _filterLogs(List<TimeLog> logs) {
    final ref = _offsetDate();
    final showWeekends = _prefs.showWeekends.value;
    return logs.where((l) {
      final date = _parseDate(l.date);
      if (date == null) return false;
      // Filter weekends unless preference says show them
      if (!showWeekends && date.weekday > 5) return false;
      return _dateFallsInPeriod(date, ref);
    }).toList();
  }

  DateTime? _parseDate(String dateStr) {
    return DateTime.tryParse(dateStr);
  }

  bool _dateFallsInPeriod(DateTime date, DateTime ref) {
    switch (widget.period) {
      case Period.week:
        final start = _weekStart(ref);
        final end = start.add(const Duration(days: 6));
        return date.isAfter(start.subtract(const Duration(days: 1))) &&
            date.isBefore(end.add(const Duration(days: 1)));
      case Period.month:
        return date.year == ref.year && date.month == ref.month;
      case Period.year:
        return date.year == ref.year;
    }
  }

  // ------------------------------------------------------------------
  // Content
  // ------------------------------------------------------------------

  Widget _buildContent(ThemeData theme, List<TimeLog> filtered, DateTime refDate) {
    final totalExpected = filtered.fold<int>(0, (sum, l) => sum + l.expectedMinutes);
    final totalOverhead = filtered.fold<int>(0, (sum, l) => sum + l.overheadMinutes);
    final totalActual = filtered.fold<int>(0, (sum, l) => sum + (l.endTime != null ? l.elapsed.inMinutes : 0));
    final totalOvertime = filtered.fold<int>(0, (sum, l) => sum + l.overtimeMinutes);

    // Build a quick lookup: date string → TimeLog
    final logByDate = <String, TimeLog>{};
    for (final l in filtered) {
      logByDate[l.date] = l;
    }

    return RefreshIndicator(
      onRefresh: () => _state.refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryCard(theme, 'Days logged', '${filtered.length}'),
          _summaryCard(theme, 'Total hours worked', _formatMinutes(totalActual)),
          _summaryCard(theme, 'Expected work', _formatMinutes(totalExpected)),
          _summaryCard(theme, 'Overhead buffer', _formatMinutes(totalOverhead)),
          _summaryCard(
            theme,
            'Net overtime',
            _formatMinutes(totalOvertime),
            isOvertime: true,
            valueMinutes: totalOvertime,
          ),
          const SizedBox(height: 16),
          // Time bank chart — deviation-from-baseline bar chart
          _TimeBankChart(logs: filtered, allLogs: _state.allLogs, period: widget.period, refDate: refDate, showWeekends: _prefs.showWeekends.value),
          const SizedBox(height: 16),
          // Calendar view depending on period
          _buildCalendar(theme, logByDate),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Calendar views
  // -- Day edit dialog ----------------------------------------------

  void _showEditDayDialog(TimeLog log) {
    final state = _state;
    if (state.travelPresets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings not loaded yet. Try again.')),
      );
      return;
    }

    final expected = state.expectedMinutesForDate(DateTime.parse(log.date));

    showDialog<EditDayResult>(
      context: context,
      builder: (_) => EditDayDialog(
        log: log,
        expectedMinutes: expected,
        travelPresets: state.travelPresets,
      ),
    ).then((result) {
      if (result == null) return;
      if (result.isDelete) {
        state.deleteDay(log.id!);
      } else {
        final startStr = '${result.startTime.hour.toString().padLeft(2, '0')}:${result.startTime.minute.toString().padLeft(2, '0')}:00';
        final endStr = result.endTime != null
            ? '${result.endTime!.hour.toString().padLeft(2, '0')}:${result.endTime!.minute.toString().padLeft(2, '0')}:00'
            : null;
        final editedLog = log.copyWith(
          startTime: startStr,
          endTime: endStr,
          expectedMinutes: result.expectedMinutes,
          lunchMinutes: result.lunchMinutes,
          morningOverheadMinutes: result.morningOverheadMinutes,
          morningProductiveCommuteMinutes: result.morningProductiveCommuteMinutes,
          eveningOverheadMinutes: result.eveningOverheadMinutes,
          eveningProductiveCommuteMinutes: result.eveningProductiveCommuteMinutes,
          note: result.note,
        );
        state.editDay(editedLog);
      }
    });
  }

  // -- Add day dialog for past empty days ---------------------------

  Future<void> _showAddDayDialog(DateTime date) async {
    final state = _state;
    if (state.travelPresets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one travel preset in Settings.')),
      );
      return;
    }

    final prefs = PreferencesService();
    final lastPresetId = await prefs.getLastTravelPresetId();

    if (!mounted) return;
    final expected = state.expectedMinutesForDate(date);

    showDialog<_AddDayResult>(
      context: context,
      builder: (_) => _AddDayDialog(
        initialDate: date,
        expectedMinutes: expected,
        travelPresets: state.travelPresets,
        initialPresetId: lastPresetId,
      ),
    ).then((result) {
      if (result == null) return;
      final dateStr = '${result.date.year}-${result.date.month.toString().padLeft(2, '0')}-${result.date.day.toString().padLeft(2, '0')}';
      final startStr = '${result.startTime.hour.toString().padLeft(2, '0')}:${result.startTime.minute.toString().padLeft(2, '0')}:00';
      final endStr = '${result.endTime.hour.toString().padLeft(2, '0')}:${result.endTime.minute.toString().padLeft(2, '0')}:00';

      state.addDay(
        date: dateStr,
        startTime: startStr,
        endTime: endStr,
        expectedMinutes: result.expectedMinutes,
        lunchMinutes: result.lunchMinutes,
        morningOverheadMinutes: result.morningOverheadMinutes,
        morningProductiveCommuteMinutes: result.morningProductiveCommuteMinutes,
        eveningOverheadMinutes: result.eveningOverheadMinutes,
        eveningProductiveCommuteMinutes: result.eveningProductiveCommuteMinutes,
        note: result.note,
      ).then((_) {
        // Refresh was triggered by addDay — no extra work needed.
        prefs.setLastTravelPresetId(result.presetId);
      }).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save day: $e')),
          );
        }
      });
    });
  }

  // ------------------------------------------------------------------

  Widget _buildCalendar(ThemeData theme, Map<String, TimeLog> logByDate) {
    final showWeekends = _prefs.showWeekends.value;
    switch (widget.period) {
      case Period.week:
        return _weekCalendar(context, logByDate, refDate: _offsetDate(), showWeekends: showWeekends, onDayTap: _showEditDayDialog, onEmptyPastDayTap: _showAddDayDialog);
      case Period.month:
        return _monthCalendar(context, logByDate, refDate: _offsetDate(), showWeekends: showWeekends, onDayTap: _showEditDayDialog, onEmptyPastDayTap: _showAddDayDialog);
      case Period.year:
        return _yearCalendar(context, logByDate, refDate: _offsetDate(), showWeekends: showWeekends, onDayTap: _showEditDayDialog, onMonthTap: widget.onMonthSelected);
    }
  }

  String _formatMinutes(int minutes) {
    final sign = minutes < 0 ? '-' : '';
    final abs = minutes.abs();
    final h = abs ~/ 60;
    final m = abs % 60;
    if (h == 0) return '$sign$m min';
    return '$sign${h}h ${m}m';
  }

}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

Widget _summaryCard(
  ThemeData theme,
  String label,
  String value, {
  bool isOvertime = false,
  int valueMinutes = 0,
}) {
  final color = isOvertime
      ? (valueMinutes >= 0 ? theme.colorScheme.primary : Colors.orange)
      : null;
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Week calendar — 7 day row
// ---------------------------------------------------------------------------

Widget _weekCalendar(BuildContext context, Map<String, TimeLog> logByDate, {
  required DateTime refDate,
  bool showWeekends = false,
  void Function(TimeLog)? onDayTap,
  void Function(DateTime)? onEmptyPastDayTap,
}) {
  final theme = Theme.of(context);
  final weekStart = refDate.subtract(Duration(days: refDate.weekday - 1));
  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Count visible days
  final visibleDays = showWeekends ? 7 : 5;
  // Available width minus the 16px padding on each side
  final availWidth = MediaQuery.of(context).size.width - 32;
  // Each _dayCell has EdgeInsets.symmetric(horizontal: 4) = 8px padding per cell
  final cellPadding = 8.0;
  final cellWidth = (availWidth - visibleDays * cellPadding) / visibleDays;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Daily overview', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      SizedBox(
        width: availWidth,
        child: Row(
          children: List.generate(7, (i) {
            final day = weekStart.add(Duration(days: i));
            // Skip weekends when toggle is off
            if (!showWeekends && day.weekday > 5) return const SizedBox.shrink();
            final dateStr = _dateStr(day);
            final log = logByDate[dateStr];
            return _dayCell(theme, dayName: dayNames[i], day: day, log: log, width: cellWidth, onTap: log != null && onDayTap != null ? () => onDayTap(log) : null, onEmptyPastDayTap: log == null && onEmptyPastDayTap != null ? () => onEmptyPastDayTap(day) : null);
          }),
        ),
      ),
    ],
  );
}

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Widget _dayCell(ThemeData theme, {
  required String dayName,
  required DateTime day,
  TimeLog? log,
  double width = 80,
  VoidCallback? onTap,
  VoidCallback? onEmptyPastDayTap,
}) {
  final isToday = _isToday(day);
  final isFuture = day.isAfter(DateTime.now().subtract(const Duration(hours: 24)));
  final hasNote = log?.note?.isNotEmpty == true;

  Color? bgColor;
  String? label;
  if (log != null && log.endTime != null) {
    final ot = log.overtimeMinutes;
    if (ot == 0) {
      bgColor = Colors.green.shade100.withValues(alpha: 0.35);
      label = '✓';
    } else if (ot > 0) {
      bgColor = theme.colorScheme.errorContainer.withValues(alpha: 0.35);
      label = _overtimeStr(ot);
    } else {
      bgColor = Colors.green.shade100.withValues(alpha: 0.35);
      label = _overtimeStr(ot);
    }
  } else if (log != null && log.endTime == null) {
    bgColor = theme.colorScheme.secondaryContainer.withValues(alpha: 0.35);
    label = 'active';
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Tooltip(
      message: log != null
          ? '${log.date}: ${log.startTime}${log.endTime != null ? ' → ${log.endTime}' : ' → …'}\n${_fmtMins(log.expectedMinutes)} work${log.note != null ? '\n📝 ${log.note}' : ''}'
          : '',
      child: InkWell(
        onTap: log != null ? onTap : onEmptyPastDayTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
        width: width,
        decoration: BoxDecoration(
          color: bgColor ?? (isToday ? theme.colorScheme.surfaceContainerHigh : null),
          borderRadius: BorderRadius.circular(12),
          border: isToday ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dayName, style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
                if (hasNote)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.note_outlined, size: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${day.day}', style: theme.textTheme.titleMedium),
            if (isFuture && log == null)
              Text('—', style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ))
            else if (label != null)
              Text(label, style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: bgColor != null
                    ? (log != null && log.overtimeMinutes > 0
                        ? theme.colorScheme.error
                        : Colors.green.shade700)
                    : null,
                fontSize: 11,
              ))
            else
              Text('—', style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          ],
        ),
        ),
      ),
    ),
  );
}

bool _isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

// ---------------------------------------------------------------------------
// Month calendar — full grid
// ---------------------------------------------------------------------------

Widget _monthCalendar(BuildContext context, Map<String, TimeLog> logByDate, {
  required DateTime refDate,
  bool showWeekends = false,
  void Function(TimeLog)? onDayTap,
  void Function(DateTime)? onEmptyPastDayTap,
}) {
  final theme = Theme.of(context);
  final numDays = showWeekends ? 7 : 5;
  // Week-number gutter on the left of each row
  final weekGutter = 34.0;
  // Account for 4px gap between cells for visual separation
  final availWidth = MediaQuery.of(context).size.width - 32;
  final cellWidth = (availWidth - weekGutter - (numDays - 1) * 4) / numDays;
  final firstDay = DateTime(refDate.year, refDate.month, 1);
  final lastDay = DateTime(refDate.year, refDate.month + 1, 0);
  // Monday = 0, Tuesday = 1, …, Sunday = 6
  final startWeekday = (firstDay.weekday + 6) % 7;
  final daysInMonth = lastDay.day;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Daily overview', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      // Week-number gutter + day-of-week header with gaps matching grid rows
      Row(
        children: [
          SizedBox(
            width: weekGutter,
            child: Text('Wk', textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              )),
          ),
          ..._buildMonthHeader(showWeekends, cellWidth, theme),
        ],
      ),
      const SizedBox(height: 4),
      // Grid rows
      ..._buildMonthRows(context, cellWidth, logByDate, firstDay, startWeekday, daysInMonth, numDays, showWeekends, onDayTap, onEmptyPastDayTap, weekGutter),
    ],
  );
}

List<Widget> _buildMonthHeader(bool showWeekends, double cellWidth, ThemeData theme) {
  final names = showWeekends
      ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
      : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  final children = <Widget>[];
  for (int i = 0; i < names.length; i++) {
    if (i > 0) children.add(const SizedBox(width: 4));
    children.add(SizedBox(
      width: cellWidth,
      child: Text(names[i], textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
    ));
  }
  return children;
}

List<Widget> _buildMonthRows(BuildContext context, double cellWidth, Map<String, TimeLog> logByDate,
    DateTime firstDay, int startWeekday, int daysInMonth,
    int numDays,
    bool showWeekends,
    void Function(TimeLog)? onDayTap,
    void Function(DateTime)? onEmptyPastDayTap,
    double weekGutter) {
  final theme = Theme.of(context);

  // Monday of the first grid row — may fall in the previous month.
  // Built from components (not Duration) so DST can't shift the date.
  final gridStart = DateTime(firstDay.year, firstDay.month, 1 - startWeekday);

  // Number of full 7-day grid rows needed to cover the month.
  final numRows = ((startWeekday + daysInMonth) / 7).ceil();

  final rows = <Widget>[];
  for (int r = 0; r < numRows; r++) {
    final rowChildren = <Widget>[];
    // Week number of this grid row, taken from its Monday.
    final rowWeek = isoWeekNumber(
        DateTime(gridStart.year, gridStart.month, gridStart.day + r * 7));
    rowChildren.add(SizedBox(
      width: weekGutter,
      child: Text(rowWeek.toString(), textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        )),
    ));

    int rendered = 0;
    // Iterate the full Mon–Sun week; skip weekend columns when hidden.
    for (int col7 = 0; col7 < 7; col7++) {
      if (!showWeekends && col7 >= 5) continue;
      if (rendered > 0) rowChildren.add(const SizedBox(width: 4));
      rendered++;

      final date = DateTime(gridStart.year, gridStart.month, gridStart.day + r * 7 + col7);
      final inMonth = date.month == firstDay.month && date.year == firstDay.year;
      final dateStr = _dateStr(date);
      final log = inMonth ? logByDate[dateStr] : null;
      final isToday = inMonth && _isToday(date);
      rowChildren.add(_monthCell(
        context, cellWidth, theme,
        date: date, inMonth: inMonth, isToday: isToday, log: log,
        onDayTap: onDayTap, onEmptyPastDayTap: onEmptyPastDayTap,
      ));
    }

    rows.add(Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: rowChildren),
    ));
  }
  return rows;
}

Widget _monthCell(BuildContext context, double cellWidth, ThemeData theme, {
  required DateTime date,
  required bool inMonth,
  required bool isToday,
  required TimeLog? log,
  required void Function(TimeLog)? onDayTap,
  required void Function(DateTime)? onEmptyPastDayTap,
}) {
  Color? bgColor;
  if (!inMonth) {
    // Adjacent-month day — dimmed, unclickable.
    bgColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
  } else if (log != null && log.endTime != null) {
    final ot = log.overtimeMinutes;
    bgColor = ot > 0
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
        : Colors.green.shade100.withValues(alpha: 0.35);
  } else if (log != null && log.endTime == null) {
    bgColor = Colors.amber.shade50;
  }

  final hasNote = log?.note?.isNotEmpty == true;
  final tap = !inMonth
      ? null
      : (log != null
          ? (onDayTap != null ? () => onDayTap(log) : null)
          : (onEmptyPastDayTap != null ? () => onEmptyPastDayTap(date) : null));

  final dayStyle = inMonth
      ? theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)
      : theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

  return Container(
    width: cellWidth,
    height: 48,
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      border: isToday ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
    ),
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: log != null
            ? '${log.date}: ${log.startTime}${log.endTime != null ? ' → ${log.endTime}' : ' → …'}\n${_fmtMins(log.expectedMinutes)} work${log.note != null ? '\n📝 ${log.note}' : ''}'
            : '',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${date.day}', style: dayStyle),
                if (hasNote)
                  Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Icon(Icons.note_outlined, size: 10, color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
            if (log != null && log.endTime != null)
              Text(
                _overtimeStr(log.overtimeMinutes),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: log.overtimeMinutes > 0
                      ? theme.colorScheme.error
                      : Colors.green.shade700,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

String _overtimeStr(int minutes) {
  if (minutes == 0) return '✓';
  final sign = minutes > 0 ? '+' : '';
  final h = minutes.abs() ~/ 60;
  final m = minutes.abs() % 60;
  if (h == 0) return '$sign$m min';
  return '$sign${h}h ${m}min';
}

// ---------------------------------------------------------------------------
// Year calendar — 3×4 month grid
// ---------------------------------------------------------------------------

Widget _yearCalendar(BuildContext context, Map<String, TimeLog> logByDate, {
  required DateTime refDate,
  bool showWeekends = false,
  void Function(TimeLog)? onDayTap,
  void Function(int year, int month)? onMonthTap,
}) {
  final theme = Theme.of(context);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Monthly overview', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      // 3×4 grid
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 12,
        itemBuilder: (ctx, i) {
          final monthStr = '${refDate.year}-${(i+1).toString().padLeft(2, '0')}';
          final logsThisMonth = logByDate.entries
              .where((e) => e.key.startsWith(monthStr))
              .map((e) => e.value)
              .toList();
          final totalOt = logsThisMonth.fold<int>(0, (s, l) => s + l.overtimeMinutes);
          final daysLogged = logsThisMonth.length;

          return Card(
            child: InkWell(
              onTap: onMonthTap != null ? () => onMonthTap(refDate.year, i + 1) : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(months[i], style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
                  const SizedBox(height: 4),
                  Text('$daysLogged days', style: theme.textTheme.bodySmall),
                  if (daysLogged > 0)
                    Text(
                      _overtimeStr(totalOt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: totalOt > 0
                            ? theme.colorScheme.error
                            : Colors.green.shade700,
                      ),
                    ),
                ],
              ),
              ),
            ),
          );
        },
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Edit day dialog (shared with history screen)
// ---------------------------------------------------------------------------



// ---------------------------------------------------------------------------
// Add day dialog
// ---------------------------------------------------------------------------

class _AddDayResult {
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int expectedMinutes;
  final int lunchMinutes;
  final int flexMinutes;
  final int morningOverheadMinutes;
  final int morningProductiveCommuteMinutes;
  final int eveningOverheadMinutes;
  final int eveningProductiveCommuteMinutes;
  final String? note;
  final String? presetId;
  _AddDayResult({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.expectedMinutes,
    required this.lunchMinutes,
    this.flexMinutes = 0,
    required this.morningOverheadMinutes,
    required this.morningProductiveCommuteMinutes,
    required this.eveningOverheadMinutes,
    required this.eveningProductiveCommuteMinutes,
    this.note,
    this.presetId,
  });
}

class _AddDayDialog extends StatefulWidget {
  final DateTime initialDate;
  final int expectedMinutes;
  final List<dynamic> travelPresets;
  final String? initialPresetId;

  const _AddDayDialog({
    required this.initialDate,
    required this.expectedMinutes,
    required this.travelPresets,
    this.initialPresetId,
  });

  @override
  State<_AddDayDialog> createState() => _AddDayDialogState();
}

class _AddDayDialogState extends State<_AddDayDialog> {
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late dynamic _selectedPreset;
  int _lunch = 0;
  String _note = '';

  int get _expected => widget.expectedMinutes;
  int get _morningOverhead => _selectedPreset.morningOverheadMinutes;
  int get _morningProductive => _selectedPreset.morningProductiveCommuteMinutes;
  int get _eveningOverhead => _selectedPreset.eveningOverheadMinutes;
  int get _eveningProductive => _selectedPreset.eveningProductiveCommuteMinutes;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _startTime = const TimeOfDay(hour: 8, minute: 0);
    _endTime = const TimeOfDay(hour: 16, minute: 0);
    _selectedPreset = _initialPreset();
  }

  dynamic _initialPreset() {
    if (widget.initialPresetId != null) {
      for (final p in widget.travelPresets) {
        if (p.id == widget.initialPresetId) return p;
      }
    }
    return widget.travelPresets.first;
  }


  int get _overtime {
    final actualMinutes = _endTime.hour * 60 + _endTime.minute -
        (_startTime.hour * 60 + _startTime.minute) -
        _lunch;
    return actualMinutes - _expected - (_morningOverhead + _eveningOverhead);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Add a past day'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  locale: const Locale('en', 'GB'),
                );
                if (picked != null) setState(() => _date = picked);
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start time', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      FilledButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: _startTime);
                          if (picked != null) setState(() => _startTime = picked);
                        },
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('End time', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      FilledButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: _endTime);
                          if (picked != null) setState(() => _endTime = picked);
                        },
                        icon: const Icon(Icons.stop, size: 18),
                        label: Text('${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Expected work', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_fmtMins(widget.expectedMinutes)} per day',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text('Travel preset', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField(
              initialValue: _selectedPreset,
              items: widget.travelPresets.map<DropdownMenuItem>((p) {
                return DropdownMenuItem(value: p, child: Text('${p.name} (+${_fmtMins(p.defaultOverheadMinutes)})'));
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedPreset = v); },
            ),
            _commuteSummary(theme),
            const SizedBox(height: 16),
            Text('Lunch break', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _lunch.toDouble(),
                    min: 0,
                    max: 240,
                    divisions: 48,
                    label: '$_lunch min',
                    onChanged: (v) => setState(() => _lunch = v.round()),
                  ),
                ),
                Text('$_lunch min', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Note', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            TextField(
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Optional note...'),
              onChanged: (v) => _note = v,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Overtime', style: theme.textTheme.titleSmall),
                  Text(
                    _overtime == 0 ? '✓ exactly on target' : '${_overtime > 0 ? '+' : ''}$_overtime min',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _overtime > 0 ? theme.colorScheme.error : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _AddDayResult(
            date: _date,
            startTime: _startTime,
            endTime: _endTime,
            expectedMinutes: _expected,
            lunchMinutes: _lunch,
            flexMinutes: 0,
            morningOverheadMinutes: _morningOverhead,
            morningProductiveCommuteMinutes: _morningProductive,
            eveningOverheadMinutes: _eveningOverhead,
            eveningProductiveCommuteMinutes: _eveningProductive,
            note: _note.isEmpty ? null : _note,
            presetId: _selectedPreset?.id,
          )),
          child: const Text('Add'),
        ),
      ],
    );
  }
  Widget _commuteSummary(ThemeData theme) {
    final morningTotal = _morningOverhead + _morningProductive;
    final eveningTotal = _eveningOverhead + _eveningProductive;
    final totalCommute = morningTotal + eveningTotal;
    if (totalCommute == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Commute breakdown', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('Morning: $_morningOverhead min walk, $_morningProductive min train work', style: theme.textTheme.bodySmall),
          Text('Evening: $_eveningOverhead min walk, $_eveningProductive min train work', style: theme.textTheme.bodySmall),
          Text('Total: $totalCommute min commute', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Time Bank Chart — deviation-from-baseline bar chart with cumulative overlay
// ---------------------------------------------------------------------------

class _TimeBankChart extends StatefulWidget {
  final List<TimeLog> logs;       // filtered logs for this period
  final List<TimeLog> allLogs;    // all logs (unfiltered) for baseline calc
  final Period period;
  final DateTime refDate;
  final bool showWeekends;

  const _TimeBankChart({
    required this.logs,
    required this.allLogs,
    required this.period,
    required this.refDate,
    this.showWeekends = false,
  });

  @override
  State<_TimeBankChart> createState() => _TimeBankChartState();
}

class _TimeBankChartState extends State<_TimeBankChart> {
  final _prefs = PreferencesService();
  late bool _showTrend;

  @override
  void initState() {
    super.initState();
    _showTrend = _prefs.showTrend.value;
  }

  void _toggleTrend(bool v) {
    setState(() => _showTrend = v);
    _prefs.setShowTrend(v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = _buildData();
    if (data.deltas.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Time Bank', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text('Trend', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(width: 4),
                Switch(
                  value: _showTrend,
                  onChanged: _toggleTrend,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Daily overtime relative to your time bank — green bars mean you earned time back.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              width: double.infinity,
              child: CustomPaint(painter: _BarChartPainter(
                deltas: data.deltas,
                cumulative: data.cumulative,
                labels: data.labels,
                baseline: data.baseline,
                positiveBarColor: Colors.red.shade700,
                negativeBarColor: Colors.green.shade700,
                lineColor: data.netChange >= 0 ? Colors.red.shade700 : Colors.green.shade700,
                baselineColor: theme.colorScheme.onSurfaceVariant,
                gridColor: theme.dividerColor,
                labelColor: theme.dividerColor,
                isDark: isDark,
                showTrend: _showTrend,
              )),
            ),
            const SizedBox(height: 8),
            _balanceLabel(theme, data),
          ],
        ),
      ),
    );
  }

  Widget _balanceLabel(ThemeData theme, _ChartData data) {
    if (data.deltas.isEmpty) return const SizedBox.shrink();

    final baseline = data.baseline;
    final endBalance = data.cumulative.last;
    final netChange = endBalance - baseline;

    final baselineStr = _fmtMins(baseline);
    final endStr = _fmtMins(endBalance);
    final changeSign = netChange >= 0 ? '+' : '';
    final changeH = netChange.abs() ~/ 60;
    final changeM = netChange.abs() % 60;
    final changeStr = changeH > 0 ? '${changeH}h ${changeM}m' : '$changeM min';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Started with ', style: theme.textTheme.bodyMedium),
            Text(
              baselineStr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(' in the bank', style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Period total: ', style: theme.textTheme.bodySmall),
            Text(
              '$changeSign$changeStr',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: netChange >= 0 ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
            Icon(
              netChange >= 0 ? Icons.trending_up : Icons.trending_down,
              size: 16,
              color: netChange >= 0 ? Colors.red.shade700 : Colors.green.shade700,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Ends with ', style: theme.textTheme.bodySmall),
            Text(
              endStr,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  _ChartData _buildData() {
    final logByDate = <String, TimeLog>{};
    for (final l in widget.logs) {
      logByDate[l.date] = l;
    }

    switch (widget.period) {
      case Period.week:
        return _buildWeekData(logByDate);
      case Period.month:
        return _buildMonthData(logByDate);
      case Period.year:
        return _buildYearData(logByDate);
    }
  }

  /// Compute the time bank balance at the start of [periodStart].
  int _baselineBefore(DateTime periodStart) {
    int sum = 0;
    for (final l in widget.allLogs) {
      final date = DateTime.tryParse(l.date);
      if (date != null && date.isBefore(periodStart)) {
        sum += l.overtimeMinutes;
      }
    }
    return sum;
  }

  _ChartData _buildWeekData(Map<String, TimeLog> logByDate) {
    final weekStart = widget.refDate.subtract(Duration(days: widget.refDate.weekday - 1));
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final deltas = <int>[];
    final labels = <String>[];

    final baseline = _baselineBefore(weekStart);

    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      if (!widget.showWeekends && day.weekday > 5) continue;
      final dateStr = _dateStr(day);
      final log = logByDate[dateStr];
      if (log == null || log.endTime == null) continue;
      deltas.add(log.overtimeMinutes);
      labels.add(dayNames[i]);
    }

    return _ChartData(
      deltas: deltas,
      cumulative: _buildCumulative(baseline, deltas),
      labels: labels,
      baseline: baseline,
    );
  }

  _ChartData _buildMonthData(Map<String, TimeLog> logByDate) {
    final ref = DateTime(widget.refDate.year, widget.refDate.month, 1);
    final daysInMonth = DateTime(widget.refDate.year, widget.refDate.month + 1, 0).day;
    final deltas = <int>[];
    final labels = <String>[];

    final baseline = _baselineBefore(ref);

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(widget.refDate.year, widget.refDate.month, day);
      if (!widget.showWeekends && date.weekday > 5) continue;
      final dateStr = _dateStr(date);
      final log = logByDate[dateStr];
      if (log == null || log.endTime == null) continue;
      deltas.add(log.overtimeMinutes);
      // Label every 5th day or first/last
      if (day == 1 || day == daysInMonth || day % 5 == 0) {
        labels.add('$day');
      } else {
        labels.add('');
      }
    }

    return _ChartData(
      deltas: deltas,
      cumulative: _buildCumulative(baseline, deltas),
      labels: labels,
      baseline: baseline,
    );
  }

  _ChartData _buildYearData(Map<String, TimeLog> logByDate) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final deltas = <int>[];
    final labels = <String>[];

    final baseline = _baselineBefore(DateTime(widget.refDate.year, 1, 1));

    for (int i = 0; i < 12; i++) {
      final monthStr = '${widget.refDate.year}-${(i+1).toString().padLeft(2, '0')}';
      final logsThisMonth = logByDate.entries
          .where((e) => e.key.startsWith(monthStr))
          .map((e) => e.value)
          .toList();
      final monthOt = logsThisMonth.fold<int>(0, (s, l) => s + l.overtimeMinutes);
      deltas.add(monthOt);
      labels.add(months[i]);
    }

    return _ChartData(
      deltas: deltas,
      cumulative: _buildCumulative(baseline, deltas),
      labels: labels,
      baseline: baseline,
    );
  }

  /// Build cumulative running total starting from [baseline].
  List<int> _buildCumulative(int baseline, List<int> deltas) {
    final cum = <int>[];
    var running = baseline;
    for (final d in deltas) {
      running += d;
      cum.add(running);
    }
    return cum;
  }
}

class _ChartData {
  final List<int> deltas;          // per-period overtime (bar heights)
  final List<int> cumulative;      // running total for overlay line
  final List<String> labels;       // X-axis labels
  final int baseline;              // time bank at start of period

  int get netChange => cumulative.last - baseline;

  const _ChartData({
    required this.deltas,
    required this.cumulative,
    required this.labels,
    required this.baseline,
  });
}

// ---------------------------------------------------------------------------
// CustomPainter for the bar chart + cumulative trend line (optional dashed)
// ---------------------------------------------------------------------------

class _BarChartPainter extends CustomPainter {
  final List<int> deltas;
  final List<int> cumulative;
  final List<String> labels;
  final int baseline;
  final Color positiveBarColor;
  final Color negativeBarColor;
  final Color lineColor;
  final Color baselineColor;
  final Color gridColor;
  final Color labelColor;
  final bool isDark;
  final bool showTrend;

  _BarChartPainter({
    required this.deltas,
    required this.cumulative,
    required this.labels,
    required this.baseline,
    required this.positiveBarColor,
    required this.negativeBarColor,
    required this.lineColor,
    required this.baselineColor,
    required this.gridColor,
    required this.labelColor,
    this.isDark = false,
    this.showTrend = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (deltas.isEmpty) return;

    const leftPad = 44.0;
    const bottomPad = 18.0;
    const topPad = 8.0;
    const rightPad = 12.0;
    final barWidth = (size.width - leftPad - rightPad) / deltas.length * 0.6;

    final graphWidth = size.width - leftPad - rightPad;
    final graphHeight = size.height - topPad - bottomPad;
    final stepX = graphWidth / deltas.length;

    // ---- Determine Y range centered on baseline ----
    final maxBarDev = deltas.fold<double>(0, (s, d) => s > d.abs() ? s : d.abs().toDouble());
    double yRange;
    if (showTrend && cumulative.isNotEmpty) {
      // When trend is shown, scale to accommodate both bars and cumulative line
      final maxCumDev = cumulative.fold<double>(0, (s, v) {
        final dev = (v - baseline).abs().toDouble();
        return s > dev ? s : dev;
      });
      yRange = (maxBarDev > maxCumDev ? maxBarDev : maxCumDev).clamp(1.0, double.infinity) * 1.3;
    } else {
      yRange = maxBarDev.clamp(1.0, double.infinity) * 1.3;
    }
    final paddedRange = yRange;

    /// Maps a deviation value (relative to baseline) to pixel Y.
    /// deviation=0 → center of graph.
    double yOf(double deviation) {
      return topPad + graphHeight / 2 - (deviation / paddedRange) * graphHeight / 2;
    }

    final baselineY = yOf(0);

    // ---- Y-axis deviation labels ----
    void drawYLabel(String text, double y) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(fontSize: 10, color: labelColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 4, y - tp.height / 2));
    }

    final halfRange = (paddedRange / 2).round();
    final fullRange = paddedRange.round();
    drawYLabel('+${_fmtShort(fullRange)}', topPad);
    drawYLabel('+${_fmtShort(halfRange)}', topPad + graphHeight / 4);
    drawYLabel('0', baselineY);
    drawYLabel('-${_fmtShort(halfRange)}', topPad + graphHeight * 0.75);
    drawYLabel('-${_fmtShort(fullRange)}', topPad + graphHeight);

    // ---- Grid lines ----
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = topPad + (graphHeight * i / 4);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);
    }

    // ---- Baseline reference line (dashed) ----
    final dashPaint = Paint()
      ..color = baselineColor
      ..strokeWidth = 1.5;
    const dashWidth = 6.0;
    const gapWidth = 4.0;
    double x0 = leftPad;
    while (x0 < size.width - rightPad) {
      final x1 = (x0 + dashWidth).clamp(leftPad, size.width - rightPad);
      canvas.drawLine(Offset(x0, baselineY), Offset(x1, baselineY), dashPaint);
      x0 = x1 + gapWidth;
    }

    // ---- Baseline value label (top-left of dashed line) ----
    final baselineLabel = TextPainter(
      text: TextSpan(
        text: 'bank: ${_fmtShort(baseline)}',
        style: TextStyle(fontSize: 9, color: baselineColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    baselineLabel.paint(
      canvas,
      Offset(leftPad + 2, baselineY - baselineLabel.height - 2),
    );

    // ---- Bars ----
    for (int i = 0; i < deltas.length; i++) {
      final delta = deltas[i];
      final x = leftPad + i * stepX + (stepX - barWidth) / 2;
      final barHeight = (delta.abs().toDouble() / paddedRange) * graphHeight / 2;
      final yTop = delta >= 0
          ? baselineY - barHeight
          : baselineY;
      final yBottom = delta >= 0
          ? baselineY
          : baselineY + barHeight;

      final isPositive = delta > 0;
      final barColor = isPositive ? positiveBarColor : negativeBarColor;

      // Bar fill
      final barPaint = Paint()
        ..color = barColor.withValues(alpha: isDark ? 0.5 : 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTRB(x, yTop, x + barWidth, yBottom), barPaint);

      // Bar outline + top edge accent
      final outlinePaint = Paint()
        ..color = barColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRect(Rect.fromLTRB(x, yTop, x + barWidth, yBottom), outlinePaint);

      // Deviation label above/below bar
      final devLabel = TextPainter(
        text: TextSpan(
          text: delta >= 0 ? '+${_fmtShort(delta)}' : '-${_fmtShort(delta.abs())}',
          style: TextStyle(fontSize: 9, color: barColor, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final devY = delta >= 0
          ? yTop - devLabel.height - 2
          : yBottom + 2;
      final devX = x + (barWidth - devLabel.width) / 2;
      if (devY >= topPad && devY <= size.height - bottomPad) {
        devLabel.paint(canvas, Offset(
          devX.clamp(leftPad, size.width - rightPad - devLabel.width),
          devY,
        ));
      }
    }

    // ---- Cumulative trend line (dashed, no fill, only when showTrend is on) ----
    if (showTrend && cumulative.length > 1) {
      final trendPaint = Paint()
        ..color = lineColor.withValues(alpha: isDark ? 0.6 : 0.7)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;

      // Draw dashed line connecting cumulative points
      const dashLen = 8.0;
      const gapLen = 5.0;

      for (int i = 0; i < cumulative.length; i++) {
        if (i == 0) continue;
        final x1 = leftPad + (i - 1) * stepX + stepX / 2;
        final y1 = yOf((cumulative[i - 1] - baseline).toDouble());
        final x2 = leftPad + i * stepX + stepX / 2;
        final y2 = yOf((cumulative[i] - baseline).toDouble());

        // Dash the segment between (x1,y1) and (x2,y2)
        final dx = x2 - x1;
        final dy = y2 - y1;
        final length = sqrt(dx * dx + dy * dy);
        final steps = (length / (dashLen + gapLen)).ceil().clamp(1, 100);

        for (int s = 0; s < steps; s++) {
          final t = s / steps;
          final tNext = (s + 0.5) / steps;
          final sx1 = x1 + dx * t;
          final sy1 = y1 + dy * t;
          final sx2 = x1 + dx * tNext;
          final sy2 = y1 + dy * tNext;
          if (s % 2 == 0) {
            canvas.drawLine(Offset(sx1, sy1), Offset(sx2, sy2), trendPaint);
          }
        }
      }

      // Small translucent dots at each cumulative point
      final dotPaint = Paint()
        ..color = lineColor.withValues(alpha: isDark ? 0.5 : 0.4)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < cumulative.length; i++) {
        final x = leftPad + i * stepX + stepX / 2;
        final devFromBaseline = (cumulative[i] - baseline).toDouble();
        final y = yOf(devFromBaseline);
        canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
      }
    }

    // ---- X-axis labels ----
    for (int i = 0; i < labels.length; i++) {
      final label = labels[i];
      if (label.isEmpty) continue;
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(fontSize: 10, color: labelColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = (leftPad + i * stepX + stepX / 2 - tp.width / 2)
          .clamp(leftPad, size.width - rightPad - tp.width);
      tp.paint(canvas, Offset(x, size.height - bottomPad + 4));
    }
  }

  /// Format a deviation value as "Xh Ym" or "X min" (no sign — caller adds +/-).
  String _fmtShort(int mins) {
    final abs = mins.abs();
    final h = abs ~/ 60;
    final m = abs % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => true;
}
