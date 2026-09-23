import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/period.dart';
import '../models/time_log.dart';
import '../models/work_config.dart' show isoWeekNumber;
import '../services/preferences_service.dart';
import '../utils/format.dart';
import '../widgets/add_day_dialog.dart';
import '../widgets/edit_day_dialog.dart';
import '../widgets/time_bank_chart.dart';

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
          _summaryCard(theme, 'Total hours worked', formatDurationMinutes(totalActual)),
          _summaryCard(theme, 'Expected work', formatDurationMinutes(totalExpected)),
          _summaryCard(theme, 'Overhead buffer', formatDurationMinutes(totalOverhead)),
          _summaryCard(
            theme,
            'Net overtime',
            formatDurationMinutes(totalOvertime),
            isOvertime: true,
            valueMinutes: totalOvertime,
          ),
          const SizedBox(height: 16),
          // Time bank chart — deviation-from-baseline bar chart
          TimeBankChart(logs: filtered, allLogs: _state.allLogs, period: widget.period, refDate: refDate, showWeekends: _prefs.showWeekends.value),
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

    showDialog<AddDayResult>(
      context: context,
      builder: (_) => AddDayDialog(
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
      label = formatOvertimeStatus(ot);
    } else {
      bgColor = Colors.green.shade100.withValues(alpha: 0.35);
      label = formatOvertimeStatus(ot);
    }
  } else if (log != null && log.endTime == null) {
    bgColor = theme.colorScheme.secondaryContainer.withValues(alpha: 0.35);
    label = 'active';
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Tooltip(
      message: log != null
          ? '${log.date}: ${log.startTime}${log.endTime != null ? ' → ${log.endTime}' : ' → …'}\n${formatMins(log.expectedMinutes)} work${log.note != null ? '\n📝 ${log.note}' : ''}'
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
            ? '${log.date}: ${log.startTime}${log.endTime != null ? ' → ${log.endTime}' : ' → …'}\n${formatMins(log.expectedMinutes)} work${log.note != null ? '\n📝 ${log.note}' : ''}'
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
                formatOvertimeStatus(log.overtimeMinutes),
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
                      formatOvertimeStatus(totalOt),
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



