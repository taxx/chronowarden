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
            children: const [
              _PeriodTab(period: Period.week),
              _PeriodTab(period: Period.month),
              _PeriodTab(period: Period.year),
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
  const _PeriodTab({required this.period});

  @override
  State<_PeriodTab> createState() => _PeriodTabState();
}

class _PeriodTabState extends State<_PeriodTab> {
  int _offset = 0; // 0 = current period, negative = past, positive = future
  final _state = AppState();

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
                onPressed: () => setState(() => _offset--),
                tooltip: 'Previous',
              ),
              Text(label, style: theme.textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => setState(() => _offset++),
                tooltip: 'Next',
              ),
            ],
          ),
        ),
        if (_offset != 0)
          Align(
            child: TextButton(
              onPressed: () => setState(() => _offset = 0),
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
  // ------------------------------------------------------------------

  Widget _buildCalendar(ThemeData theme, Map<String, TimeLog> logByDate) {
    switch (widget.period) {
      case Period.week:
        return _weekCalendar(context, logByDate, refDate: _offsetDate());
      case Period.month:
        return _monthCalendar(context, logByDate, refDate: _offsetDate());
      case Period.year:
        return _yearCalendar(context, logByDate, refDate: _offsetDate());
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
            return _dayCell(theme, dayName: dayNames[i], day: day, log: log);
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
}) {
  final isToday = _isToday(day);
  final isFuture = day.isAfter(DateTime.now().subtract(const Duration(hours: 24)));
  final hasNote = log?.note?.isNotEmpty == true;

  Color? bgColor;
  String? label;
  if (log != null && log.endTime != null) {
    final ot = log.overtimeMinutes;
    if (ot == 0) {
      bgColor = theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35);
      label = '✓';
    } else if (ot > 0) {
      bgColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.35);
      label = '+${ot}min';
    } else {
      bgColor = theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35);
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
                color: bgColor != null ? theme.colorScheme.primary : null,
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
}) {
  final theme = Theme.of(context);
  final cellWidth = (MediaQuery.of(context).size.width - 32) / 7;
  final firstDay = DateTime(refDate.year, refDate.month, 1);
  final lastDay = DateTime(refDate.year, refDate.month + 1, 0);
  final startWeekday = firstDay.weekday % 7; // 0 = Sun, 1 = Mon … 6 = Sat
  final daysInMonth = lastDay.day;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Daily overview', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      // Day-of-week header
      Row(
        children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d) {
          return SizedBox(
            width: cellWidth,
            child: Text(d, textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          );
        }).toList(),
      ),
      const SizedBox(height: 4),
      // Grid rows
      ..._buildMonthRows(context, cellWidth, logByDate, firstDay, startWeekday, daysInMonth),
    ],
  );
}

List<Widget> _buildMonthRows(BuildContext context, double cellWidth, Map<String, TimeLog> logByDate,
    DateTime firstDay, int startWeekday, int daysInMonth) {
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
      bgColor = ot >= 0
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Colors.green.shade50;
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
                  color: log.overtimeMinutes >= 0
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onTertiaryContainer,
                ),
              ),
          ],
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
                        color: totalOt >= 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
}
