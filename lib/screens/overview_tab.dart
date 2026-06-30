import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/time_log.dart';

/// Aggregated overview: week / month / year summaries.
class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _state = AppState();

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
    final theme = Theme.of(context);
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

class _PeriodTab extends StatelessWidget {
  final Period period;

  const _PeriodTab({required this.period});

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final logs = state.allLogs;
    final theme = Theme.of(context);

    final filtered = _filterLogs(logs, period);
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No logs in this period',
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final totalExpected = filtered.fold<int>(0, (sum, l) => sum + l.expectedMinutes);
    final totalOverhead = filtered.fold<int>(0, (sum, l) => sum + l.overheadMinutes);
    final totalActual = filtered.fold<int>(0, (sum, l) => sum + (l.endTime != null ? l.elapsed.inMinutes : 0));
    final totalOvertime = filtered.fold<int>(0, (sum, l) => sum + l.overtimeMinutes);
    final avgActual = filtered.length > 0 ? totalActual ~/ filtered.length : 0;
    final avgOvertime = filtered.length > 0 ? totalOvertime ~/ filtered.length : 0;

    return RefreshIndicator(
      onRefresh: () => state.refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(theme, 'Days logged', '${filtered.length}'),
          _SummaryCard(theme, 'Total hours worked', _formatMinutes(totalActual)),
          _SummaryCard(theme, 'Expected work', _formatMinutes(totalExpected)),
          _SummaryCard(theme, 'Overhead buffer', _formatMinutes(totalOverhead)),
          _SummaryCard(
            theme,
            'Net overtime',
            _formatMinutes(totalOvertime),
            isOvertime: true,
            valueMinutes: totalOvertime,
          ),
          _SummaryCard(theme, 'Avg hours / day', _formatMinutes(avgActual)),
          _SummaryCard(
            theme,
            'Avg overtime / day',
            _formatMinutes(avgOvertime),
            isOvertime: true,
            valueMinutes: avgOvertime,
          ),
          const SizedBox(height: 16),
          Text('Daily breakdown', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...filtered.reversed.map((log) => _DayMiniCard(log, theme)),
        ],
      ),
    );
  }

  List<TimeLog> _filterLogs(List<TimeLog> logs, Period period) {
    final now = DateTime.now();
    return logs.where((l) {
      final date = _parseDate(l.date);
      if (date == null) return false;
      return _dateFallsInPeriod(date, now, period);
    }).toList();
  }

  DateTime? _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return null;
    return DateTime.tryParse(dateStr);
  }

  bool _dateFallsInPeriod(DateTime date, DateTime now, Period period) {
    switch (period) {
      case Period.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            date.isBefore(weekEnd.add(const Duration(days: 1)));
      case Period.month:
        return date.year == now.year && date.month == now.month;
      case Period.year:
        return date.year == now.year;
    }
  }

  String _formatMinutes(int minutes) {
    final sign = minutes < 0 ? '-' : '';
    final abs = minutes.abs();
    final h = abs ~/ 60;
    final m = abs % 60;
    if (h == 0) return '${sign}${m} min';
    return '${sign}${h}h ${m}m';
  }
}

Widget _SummaryCard(
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

Widget _DayMiniCard(TimeLog log, ThemeData theme) {
  final isCompleted = log.endTime != null;
  final overtime = log.overtimeMinutes;
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
    child: ListTile(
      dense: true,
      leading: Icon(
        isCompleted ? Icons.check_circle : Icons.pending,
        size: 18,
        color: isCompleted
            ? (overtime >= 0 ? theme.colorScheme.primary : Colors.green)
            : theme.colorScheme.secondary,
      ),
      title: Text(log.date, style: theme.textTheme.bodySmall),
      subtitle: Text(
        '${log.startTime}${log.endTime != null ? ' → ${log.endTime}' : ' → …'}  ·  ${log.expectedMinutes} min work',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: Text(
        isCompleted
            ? (overtime == 0 ? '✓' : '${overtime > 0 ? '+' : ''}$overtime min')
            : 'active',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: isCompleted
              ? (overtime >= 0 ? theme.colorScheme.primary : Colors.green)
              : theme.colorScheme.secondary,
        ),
      ),
    ),
  );
}
