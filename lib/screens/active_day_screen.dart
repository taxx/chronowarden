import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/notification_service.dart';

/// Full-screen overlay shown while the day is actively running.
class ActiveDayScreen extends StatefulWidget {
  const ActiveDayScreen({super.key});

  @override
  State<ActiveDayScreen> createState() => _ActiveDayScreenState();
}

class _ActiveDayScreenState extends State<ActiveDayScreen> with SingleTickerProviderStateMixin {
  late Timer _ticker;
  final _state = AppState();
  final _notifications = NotificationService();

  @override
  void initState() {
    super.initState();
    _notifications.init();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _checkNotification();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  /// Check if we should fire a notification.
  /// Two-phase: wrap-up alert before leave, over-time alert after leave.
  void _checkNotification() {
    final log = _state.todayLog;
    if (log == null || log.endTime != null) return;
    if (!_notifications.enabled) return;

    final dateStr = log.date;
    if (_notifications.wasNotifiedToday(dateStr)) return;

    final now = DateTime.now();
    final leaveTime = log.leaveTime;
    final remaining = leaveTime.difference(now);
    final threshold = _notifications.thresholdMinutes;

    // Phase 1 — wrap-up alert (before leave time)
    if (!remaining.isNegative && remaining.inMinutes <= threshold) {
      final h = remaining.inHours;
      final m = remaining.inMinutes % 60;
      final timeStr = h > 0 ? '${h}h ${m}m' : '$m min';
      final msg = _notifications.alertMessage(
        'ChronoWarden ⏰',
        '⏰ $timeStr left — wrap up and head out!',
      );
      if (msg.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _notifications.markNotified(dateStr);
      return;
    }

    // Phase 2 — over-time alert (past leave time, day still active)
    if (remaining.isNegative && remaining.inMinutes.abs() <= 60) {
      final over = remaining.inMinutes.abs();
      final msg = _notifications.alertMessage(
        'ChronoWarden 🚨',
        '🚨 $over min past your time — finish up and stop the day!',
        isUrgent: true,
      );
      if (msg.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _notifications.markNotified(dateStr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = _state.todayLog;
    final theme = Theme.of(context);

    if (log == null || log.endTime != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Day')),
        body: Center(child: Text('No active day', style: theme.textTheme.titleLarge)),
      );
    }

    final elapsed = log.elapsed;
    final leaveTime = log.leaveTime;
    final now = DateTime.now();
    final remaining = leaveTime.difference(now);
    final isPast = remaining.isNegative;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Day'),
        actions: [
          FilledButton.tonalIcon(
            onPressed: () => _showStopDialog(context),
            icon: const Icon(Icons.stop),
            label: const Text('STOP'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _state.refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              Text('Elapsed', style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
              const SizedBox(height: 8),
              Text(
                _formatHMS(elapsed),
                style: theme.textTheme.displayLarge?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 48),
              Card(
                color: isPast ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(children: [
                        Icon(isPast ? Icons.check_circle_rounded : Icons.timer_outlined,
                            color: isPast ? theme.colorScheme.onErrorContainer : theme.colorScheme.primary, size: 28),
                        const SizedBox(width: 12),
                        Text(isPast ? "You're free to go!" : 'Projected leave time', style: theme.textTheme.titleLarge),
                      ]),
                      const SizedBox(height: 12),
                      Text(
                        '${leaveTime.hour.toString().padLeft(2, '0')}:${leaveTime.minute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: isPast ? theme.colorScheme.onErrorContainer : theme.colorScheme.primary,
                        ),
                      ),
                      if (!isPast) ...[
                        const SizedBox(height: 8),
                        Text('$_remainingText remaining', style: theme.textTheme.bodyLarge),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _statCard(theme, 'Expected', '${log.expectedMinutes} min'),
              const SizedBox(height: 8),
              _statCard(theme, 'Overhead', '${log.overheadMinutes} min'),
              const SizedBox(height: 8),
              _statCard(theme, 'Total', '${log.expectedMinutes + log.overheadMinutes} min'),
            ],
          ),
        ),
      ),
    );
  }

  String get _remainingText {
    final log = _state.todayLog;
    if (log == null) return '—';
    final remaining = log.leaveTime.difference(DateTime.now());
    if (remaining.isNegative) return '0:00:00';
    return _formatHMS(remaining);
  }

  Widget _statCard(ThemeData theme, String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyLarge),
            Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  String _formatHMS(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _showStopDialog(BuildContext ctx) async {
    final picked = await showDialog<TimeOfDay>(context: ctx, builder: (_) => const _StopDialog());
    if (picked != null) {
      final endStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
      await _state.stopDay(endStr);
      if (mounted) Navigator.pop(context);
    }
  }
}

class _StopDialog extends StatefulWidget {
  const _StopDialog();

  @override
  State<_StopDialog> createState() => _StopDialogState();
}

class _StopDialogState extends State<_StopDialog> {
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _time = TimeOfDay.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Stop Day'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: () async {
              final picked = await showTimePicker(context: context, initialTime: _time);
              if (picked != null) setState(() => _time = picked);
            },
            icon: const Icon(Icons.access_time),
            label: Text('${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _time), child: const Text('Stop')),
      ],
    );
  }
}
