import 'package:flutter/material.dart';

import '../models/time_log.dart';
import '../models/work_config.dart' show isoWeekNumber;
import '../utils/format.dart';

// ---------------------------------------------------------------------------
// Calendar views — week, month and year grids
// ---------------------------------------------------------------------------

Widget weekCalendar(BuildContext context, Map<String, TimeLog> logByDate, {
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
  // Each dayCell has EdgeInsets.symmetric(horizontal: 4) = 8px padding per cell
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
            return dayCell(theme, dayName: dayNames[i], day: day, log: log, width: cellWidth, onTap: log != null && onDayTap != null ? () => onDayTap(log) : null, onEmptyPastDayTap: log == null && onEmptyPastDayTap != null ? () => onEmptyPastDayTap(day) : null);
          }),
        ),
      ),
    ],
  );
}

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Widget dayCell(ThemeData theme, {
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

Widget monthCalendar(BuildContext context, Map<String, TimeLog> logByDate, {
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
      rowChildren.add(monthCell(
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

Widget monthCell(BuildContext context, double cellWidth, ThemeData theme, {
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

Widget yearCalendar(BuildContext context, Map<String, TimeLog> logByDate, {
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



