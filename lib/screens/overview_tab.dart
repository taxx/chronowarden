import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/time_log.dart';

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

  @override
  void initState() {
    super.initState();
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
              : _buildContent(theme, filtered),
        ),
      ],
    );
  }

  String _periodLabel() {
    final now = _offsetDate();
    switch (widget.period) {
      case Period.week:
        final weekStart = _weekStart(now);
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${weekStart.day}/${weekStart.month} — ${weekEnd.day}/${weekEnd.month}';
      case Period.month:
        return _monthYearLabel(now);
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
    return logs.where((l) {
      final date = _parseDate(l.date);
      if (date == null) return false;
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

  Widget _buildContent(ThemeData theme, List<TimeLog> filtered) {
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
    if (state.workPeriods.isEmpty || state.travelPresets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings not loaded yet. Try again.')),
      );
      return;
    }

    showDialog<_EditDayResult>(
      context: context,
      builder: (_) => _EditDayDialog(
        log: log,
        workPeriods: state.workPeriods,
        travelPresets: state.travelPresets,
      ),
    ).then((result) {
      if (result == null) return;
      final startStr = '${result.startTime.hour.toString().padLeft(2, '0')}:${result.startTime.minute.toString().padLeft(2, '0')}:00';
      final endStr = result.endTime != null
          ? '${result.endTime!.hour.toString().padLeft(2, '0')}:${result.endTime!.minute.toString().padLeft(2, '0')}:00'
          : null;
      final editedLog = log.copyWith(
        startTime: startStr,
        endTime: endStr,
        expectedMinutes: result.expectedMinutes,
        overheadMinutes: result.overheadMinutes,
        lunchMinutes: result.lunchMinutes,
        note: result.note,
      );
      state.editDay(editedLog);
    });
  }

  // -- Add day dialog for past empty days ---------------------------

  void _showAddDayDialog(DateTime date) {
    final state = _state;
    if (state.workPeriods.isEmpty || state.travelPresets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one work period and one travel preset in Settings.')),
      );
      return;
    }

    showDialog<_AddDayResult>(
      context: context,
      builder: (_) => _AddDayDialog(
        initialDate: date,
        expectedMinutes: state.activePeriod?.expectedMinutes ?? 480,
        overheadMinutes: state.travelPresets.first.defaultOverheadMinutes,
        workPeriods: state.workPeriods,
        travelPresets: state.travelPresets,
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
        overheadMinutes: result.overheadMinutes,
        lunchMinutes: result.lunchMinutes,
        note: result.note,
      );
    });
  }

  // ------------------------------------------------------------------

  Widget _buildCalendar(ThemeData theme, Map<String, TimeLog> logByDate) {
    switch (widget.period) {
      case Period.week:
        return _weekCalendar(context, logByDate, refDate: _offsetDate(), onDayTap: _showEditDayDialog, onEmptyPastDayTap: _showAddDayDialog);
      case Period.month:
        return _monthCalendar(context, logByDate, refDate: _offsetDate(), onDayTap: _showEditDayDialog, onEmptyPastDayTap: _showAddDayDialog);
      case Period.year:
        return _yearCalendar(context, logByDate, refDate: _offsetDate(), onDayTap: _showEditDayDialog, onMonthTap: widget.onMonthSelected);
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
  void Function(TimeLog)? onDayTap,
  void Function(DateTime)? onEmptyPastDayTap,
}) {
  final theme = Theme.of(context);
  final weekStart = refDate.subtract(Duration(days: refDate.weekday - 1));
  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Daily overview', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(7, (i) {
            final day = weekStart.add(Duration(days: i));
            final dateStr = _dateStr(day);
            final log = logByDate[dateStr];
            return _dayCell(theme, dayName: dayNames[i], day: day, log: log, onTap: log != null && onDayTap != null ? () => onDayTap(log) : null, onEmptyPastDayTap: log == null && onEmptyPastDayTap != null ? () => onEmptyPastDayTap(day) : null);
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
      label = '+${ot}min';
    } else {
      bgColor = Colors.green.shade100.withValues(alpha: 0.35);
      label = '${ot}min';
    }
  } else if (log != null && log.endTime == null) {
    bgColor = theme.colorScheme.secondaryContainer.withValues(alpha: 0.35);
    label = 'active';
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Tooltip(
      message: log != null
          ? '${log.date}: ${log.startTime}${log.endTime != null ? ' → ${log.endTime}' : ' → …'}\n${log.expectedMinutes} min work${log.note != null ? '\n📝 ${log.note}' : ''}'
          : '',
      child: InkWell(
        onTap: log != null ? onTap : onEmptyPastDayTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
        width: 80,
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
  void Function(TimeLog)? onDayTap,
  void Function(DateTime)? onEmptyPastDayTap,
}) {
  final theme = Theme.of(context);
  final cellWidth = (MediaQuery.of(context).size.width - 32) / 7;
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
      // Day-of-week header
      Row(
        children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) {
          return SizedBox(
            width: cellWidth,
            child: Text(d, textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          );
        }).toList(),
      ),
      const SizedBox(height: 4),
      // Grid rows
      ..._buildMonthRows(context, cellWidth, logByDate, firstDay, startWeekday, daysInMonth, onDayTap, onEmptyPastDayTap),
    ],
  );
}

List<Widget> _buildMonthRows(BuildContext context, double cellWidth, Map<String, TimeLog> logByDate,
    DateTime firstDay, int startWeekday, int daysInMonth,
    void Function(TimeLog)? onDayTap,
    void Function(DateTime)? onEmptyPastDayTap) {
  final theme = Theme.of(context);
  final cells = <Widget>[];

  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(firstDay.year, firstDay.month, day);
    final dateStr = _dateStr(date);
    final log = logByDate[dateStr];
    final isToday = _isToday(date);

    Color? bgColor;
    if (log != null && log.endTime != null) {
      final ot = log.overtimeMinutes;
      bgColor = ot > 0
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
          : Colors.green.shade100.withValues(alpha: 0.35);
    } else if (log != null && log.endTime == null) {
      bgColor = Colors.amber.shade50;
    }

    final hasNote = log?.note?.isNotEmpty == true;
    cells.add(Container(
      width: cellWidth,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
      ),
      child: InkWell(
        onTap: log != null
            ? (onDayTap != null ? () => onDayTap(log) : null)
            : (onEmptyPastDayTap != null ? () => onEmptyPastDayTap(date) : null),
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: log != null
              ? '${log.date}: ${log.startTime}${log.endTime != null ? ' → ${log.endTime}' : ' → …'}\n${log.expectedMinutes} min work${log.note != null ? '\n📝 ${log.note}' : ''}'
              : '',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$day', style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
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
    ));
  }

  // Build rows of 7
  final rows = <Widget>[];
  final totalCells = startWeekday + daysInMonth;
  final numRows = (totalCells / 7).ceil();

  int cellIdx = 0;
  for (int r = 0; r < numRows; r++) {
    final rowChildren = <Widget>[];
    for (int c = 0; c < 7; c++) {
      if (cellIdx < startWeekday || cellIdx >= startWeekday + daysInMonth) {
        rowChildren.add(SizedBox(width: cellWidth, child: const Text('')));
      } else {
        rowChildren.add(cells[cellIdx - startWeekday]);
      }
      cellIdx++;
    }
    rows.add(Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: rowChildren),
    ));
  }
  return rows;
}

String _overtimeStr(int minutes) {
  if (minutes == 0) return '✓';
  final sign = minutes > 0 ? '+' : '';
  final h = minutes.abs() ~/ 60;
  final m = minutes.abs() % 60;
  if (h == 0) return '$sign${m}min';
  return '$sign${h}h${m}min';
}

// ---------------------------------------------------------------------------
// Year calendar — 3×4 month grid
// ---------------------------------------------------------------------------

Widget _yearCalendar(BuildContext context, Map<String, TimeLog> logByDate, {
  required DateTime refDate,
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

class _EditDayResult {
  final TimeOfDay startTime;
  final TimeOfDay? endTime;
  final int expectedMinutes;
  final int overheadMinutes;
  final int lunchMinutes;
  final String? note;
  _EditDayResult({
    required this.startTime,
    required this.endTime,
    required this.expectedMinutes,
    required this.overheadMinutes,
    required this.lunchMinutes,
    this.note,
  });
}

class _EditDayDialog extends StatefulWidget {
  final TimeLog log;
  final List<dynamic> workPeriods;
  final List<dynamic> travelPresets;

  const _EditDayDialog({
    required this.log,
    required this.workPeriods,
    required this.travelPresets,
  });

  @override
  State<_EditDayDialog> createState() => _EditDayDialogState();
}

class _EditDayDialogState extends State<_EditDayDialog> {
  late TimeOfDay _startTime;
  TimeOfDay? _endTime;
  late dynamic _selectedPeriod;
  late dynamic _selectedPreset;
  late int _lunch;
  late String _note;

  int get _expected => _selectedPeriod.expectedMinutes;
  int get _overhead => _selectedPreset.defaultOverheadMinutes;

  @override
  void initState() {
    super.initState();
    _startTime = _timeOfDayFromStr(widget.log.startTime);
    _endTime = widget.log.endTime != null ? _timeOfDayFromStr(widget.log.endTime!) : null;
    _selectedPeriod = _matchPeriod(widget.workPeriods, widget.log.expectedMinutes);
    _selectedPreset = _matchPreset(widget.travelPresets, widget.log.overheadMinutes);
    _lunch = widget.log.lunchMinutes;
    _note = widget.log.note ?? '';
  }

  TimeOfDay _timeOfDayFromStr(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static dynamic _matchPeriod(List<dynamic> periods, int mins) {
    for (final p in periods) {
      if (p.expectedMinutes == mins) return p;
    }
    return periods.first;
  }

  static dynamic _matchPreset(List<dynamic> presets, int mins) {
    for (final p in presets) {
      if (p.defaultOverheadMinutes == mins) return p;
    }
    return presets.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Edit Day'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Start time', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(context: context, initialTime: _startTime);
                if (picked != null) setState(() => _startTime = picked);
              },
              icon: const Icon(Icons.access_time),
              label: Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}'),
            ),
            const SizedBox(height: 16),
            Text('End time', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(context: context, initialTime: _endTime ?? TimeOfDay.now());
                if (picked != null) setState(() => _endTime = picked);
              },
              icon: const Icon(Icons.access_time),
              label: Text(_endTime != null
                  ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                  : '— not set —'),
            ),
            const SizedBox(height: 16),
            Text('Work period', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField(
              initialValue: _selectedPeriod,
              items: widget.workPeriods.map<DropdownMenuItem>((p) {
                return DropdownMenuItem(value: p, child: Text('${p.name} (${p.expectedMinutes} min)'));
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedPeriod = v); },
            ),
            const SizedBox(height: 16),
            Text('Travel preset', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField(
              initialValue: _selectedPreset,
              items: widget.travelPresets.map<DropdownMenuItem>((p) {
                return DropdownMenuItem(value: p, child: Text('${p.name} (+${p.defaultOverheadMinutes} min)'));
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedPreset = v); },
            ),
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
              controller: TextEditingController(text: _note),
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Optional note...'),
              onChanged: (v) => _note = v,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _EditDayResult(
            startTime: _startTime,
            endTime: _endTime,
            expectedMinutes: _expected,
            overheadMinutes: _overhead,
            lunchMinutes: _lunch,
            note: _note.isEmpty ? null : _note,
          )),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Add day dialog
// ---------------------------------------------------------------------------

class _AddDayResult {
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int expectedMinutes;
  final int overheadMinutes;
  final int lunchMinutes;
  final String? note;
  _AddDayResult({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.expectedMinutes,
    required this.overheadMinutes,
    required this.lunchMinutes,
    this.note,
  });
}

class _AddDayDialog extends StatefulWidget {
  final DateTime initialDate;
  final int expectedMinutes;
  final int overheadMinutes;
  final List<dynamic> workPeriods;
  final List<dynamic> travelPresets;

  const _AddDayDialog({
    required this.initialDate,
    required this.expectedMinutes,
    required this.overheadMinutes,
    required this.workPeriods,
    required this.travelPresets,
  });

  @override
  State<_AddDayDialog> createState() => _AddDayDialogState();
}

class _AddDayDialogState extends State<_AddDayDialog> {
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late dynamic _selectedPeriod;
  late dynamic _selectedPreset;
  int _lunch = 0;
  String _note = '';

  int get _expected => _selectedPeriod.expectedMinutes;
  int get _overhead => _selectedPreset.defaultOverheadMinutes;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _startTime = const TimeOfDay(hour: 8, minute: 0);
    _endTime = const TimeOfDay(hour: 16, minute: 0);
    _selectedPeriod = _matchPeriod(widget.workPeriods, widget.expectedMinutes);
    _selectedPreset = _matchPreset(widget.travelPresets, widget.overheadMinutes);
  }

  static dynamic _matchPeriod(List<dynamic> periods, int mins) {
    for (final p in periods) {
      if (p.expectedMinutes == mins) return p;
    }
    return periods.first;
  }

  static dynamic _matchPreset(List<dynamic> presets, int mins) {
    for (final p in presets) {
      if (p.defaultOverheadMinutes == mins) return p;
    }
    return presets.first;
  }

  int get _overtime {
    final actualMinutes = _endTime.hour * 60 + _endTime.minute -
        (_startTime.hour * 60 + _startTime.minute) -
        _lunch;
    return actualMinutes - _expected - _overhead;
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
            Text('Work period', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField(
              initialValue: _selectedPeriod,
              items: widget.workPeriods.map<DropdownMenuItem>((p) {
                return DropdownMenuItem(value: p, child: Text('${p.name} (${p.expectedMinutes} min)'));
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedPeriod = v); },
            ),
            const SizedBox(height: 16),
            Text('Travel preset', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField(
              initialValue: _selectedPreset,
              items: widget.travelPresets.map<DropdownMenuItem>((p) {
                return DropdownMenuItem(value: p, child: Text('${p.name} (+${p.defaultOverheadMinutes} min)'));
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedPreset = v); },
            ),
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
                      color: _overtime >= 0 ? theme.colorScheme.primary : Colors.orange,
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
            overheadMinutes: _overhead,
            lunchMinutes: _lunch,
            note: _note.isEmpty ? null : _note,
          )),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
