import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_strings.dart';
import '../models/period.dart';
import '../models/time_log.dart';
import '../models/work_config.dart' show isoWeekNumber;
import '../services/preferences_service.dart';
import '../utils/format.dart';
import 'add_day_dialog.dart';
import 'calendar_views.dart';
import 'edit_day_dialog.dart';
import 'summary_card.dart';
import 'time_bank_chart.dart';

// ---------------------------------------------------------------------------
// Period tab — week / month / year view with offset navigation
// ---------------------------------------------------------------------------

class PeriodTab extends StatefulWidget {
  final Period period;
  final int? externalOffset;
  final void Function(int)? onOffsetChanged;
  final void Function(int year, int month)? onMonthSelected;

  const PeriodTab({
    super.key,
    required this.period,
    this.externalOffset,
    this.onOffsetChanged,
    this.onMonthSelected,
  });

  @override
  State<PeriodTab> createState() => _PeriodTabState();
}

class _PeriodTabState extends State<PeriodTab> {
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
  void didUpdateWidget(PeriodTab oldWidget) {
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
        final label = _periodLabel(context);

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
                    tooltip: context.t('Previous'),
                  ),
                  Text(label, style: theme.textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => _updateOffset(_offset + 1),
                    tooltip: context.t('Next'),
                  ),
                ],
              ),
            ),
            if (_offset != 0)
              Align(
                child: TextButton(
                  onPressed: () => _updateOffset(0),
                  child: Text(context.t('Back to current')),
                ),
              ),
            // Content
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        context.t('No logs in this period'),
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

  String _periodLabel(BuildContext context) {
    final now = _offsetDate();
    switch (widget.period) {
      case Period.week:
        final weekStart = _weekStart(now);
        final weekEnd = weekStart.add(const Duration(days: 6));
        return context.t('Wk {week} · {start} — {end}', {
          'week': isoWeekNumber(weekStart),
          'start': '${weekStart.day}/${weekStart.month}',
          'end': '${weekEnd.day}/${weekEnd.month}',
        });
      case Period.month:
        final firstWeek = isoWeekNumber(DateTime(now.year, now.month, 1));
        final lastWeek = isoWeekNumber(DateTime(now.year, now.month + 1, 0));
        return context.t('{month} · Wk {first}–{last}', {
          'month': MaterialLocalizations.of(context).formatMonthYear(now),
          'first': firstWeek,
          'last': lastWeek,
        });
      case Period.year:
        return '${now.year}';
    }
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
          summaryCard(theme, context.t('Days logged'), '${filtered.length}'),
          summaryCard(theme, context.t('Total hours worked'), formatDurationMinutes(totalActual)),
          summaryCard(theme, context.t('Expected work'), formatDurationMinutes(totalExpected)),
          summaryCard(theme, context.t('Overhead buffer'), formatDurationMinutes(totalOverhead)),
          summaryCard(
            theme,
            context.t('Net overtime'),
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
        SnackBar(content: Text(context.t('Settings not loaded yet. Try again.'))),
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
        SnackBar(content: Text(context.t('Add at least one travel preset in Settings.'))),
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
            SnackBar(content: Text(context.t('Failed to save day: {error}', {'error': e}))),
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
        return weekCalendar(context, logByDate, refDate: _offsetDate(), showWeekends: showWeekends, onDayTap: _showEditDayDialog, onEmptyPastDayTap: _showAddDayDialog);
      case Period.month:
        return monthCalendar(context, logByDate, refDate: _offsetDate(), showWeekends: showWeekends, onDayTap: _showEditDayDialog, onEmptyPastDayTap: _showAddDayDialog);
      case Period.year:
        return yearCalendar(context, logByDate, refDate: _offsetDate(), showWeekends: showWeekends, onDayTap: _showEditDayDialog, onMonthTap: widget.onMonthSelected);
    }
  }

}
