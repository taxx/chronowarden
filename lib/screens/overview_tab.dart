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
        return monthYearLabel(now);
      case Period.year:
        return '${now.year}';
    }
  }

  String monthYearLabel(DateTime date) {
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
    final avgActual = filtered.length > 0 ? totalActual ~/ filtered.length : 0;
    final avgOvertime = filtered.length > 0 ? totalOvertime ~/ filtered.length : 0;

    return RefreshIndicator(
      onRefresh: () => _state.refresh(),
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

  String _formatMinutes(int minutes) {
    final sign = minutes < 0 ? '-' : '';
    final abs = minutes.abs();
    final h = abs ~/ 60;
    final m = abs % 60;
    if (h == 0) return '${sign}${m} min';
    return '${sign}${h}h ${m}m';
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

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
