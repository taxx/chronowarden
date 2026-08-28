import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';

int _sliderDivisions(double min, double max) {
  final interval = PreferencesService().sliderInterval.value;
  return ((max - min) / interval).round();
}

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
  String? _alertMessage;

  @override
  void initState() {
    super.initState();
    _initTicker();
  }

  Future<void> _initTicker() async {
    await _notifications.init();
    if (!mounted) return;
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
      _alertMessage = msg;
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
      _alertMessage = msg;
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
              if (_alertMessage != null)
                _AlertBanner(message: _alertMessage!, onDismiss: () {
                  setState(() => _alertMessage = null);
                }),
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
              _statCard(theme, 'Expected', _fmtMins(log.expectedMinutes)),
              const SizedBox(height: 8),
              _statCard(theme, 'Overhead', _fmtMins(log.overheadMinutes)),
              const SizedBox(height: 8),
              _statCard(theme, 'Total', _fmtMins(log.expectedMinutes + log.overheadMinutes)),
              const SizedBox(height: 16),
              // Lunch timer section
              _LunchTimerSection(
                lunchMinutes: log.lunchMinutes,
                lunchStartTime: _state.lunchStartTime,
                lunchEndTime: _state.lunchEndTime,
                lunchActive: _state.lunchActive,
                onStartLunch: () => _state.startLunch(),
                onStopLunch: () => _showStopLunchDialog(context),
                onEditLunch: () => _showEditLunchDialog(context, log.lunchMinutes),
                theme: theme,
              ),
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

  String _fmtMins(int minutes) {
    final abs = minutes.abs();
    final h = abs ~/ 60;
    final m = abs % 60;
    if (h == 0) return '$m min';
    return '${h}h ${m}m';
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

  Future<void> _showEditLunchDialog(BuildContext ctx, int currentLunch) async {
    int lunch = currentLunch;
    await showDialog<void>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adjust lunch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: lunch.toDouble(),
                min: 0,
                max: 120,
                divisions: _sliderDivisions(0, 120),
                label: '$lunch min',
                onChanged: (v) {
                  lunch = v.round();
                  setDialogState(() {});
                },
              ),
              const SizedBox(height: 4),
              Text('$lunch min', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _state.updateLunchMinutes(lunch);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog shown after pressing "Stop Lunch" — shows calculated duration
  /// and allows fine-tuning before saving.
  Future<void> _showStopLunchDialog(BuildContext ctx) async {
    final start = _state.lunchStartTime;
    if (start == null) return;

    final end = DateTime.now();
    final calculatedMinutes = end.difference(start).inMinutes;

    int lunch = calculatedMinutes.clamp(0, 240);
    await showDialog<void>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Lunch stopped'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Started: ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                   style: Theme.of(ctx).textTheme.bodyMedium),
              Text('Ended:   ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                   style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text('Duration: $calculatedMinutes min',
                   style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Adjust if needed:', style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: lunch.toDouble(),
                      min: 0,
                      max: 240,
                      divisions: _sliderDivisions(0, 240),
                      label: '$lunch min',
                      onChanged: (v) {
                        lunch = v.round();
                        setDialogState(() {});
                      },
                    ),
                  ),
                  Text('$lunch min', style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _state.resetLunchTimer();
                Navigator.pop(ctx);
              },
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _state.stopLunch(lunch);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
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

/// Lunch timer section — Start/Stop buttons plus elapsed display.
class _LunchTimerSection extends StatelessWidget {
  final int lunchMinutes;
  final DateTime? lunchStartTime;
  final DateTime? lunchEndTime;
  final bool lunchActive;
  final VoidCallback onStartLunch;
  final VoidCallback onStopLunch;
  final VoidCallback onEditLunch;
  final ThemeData theme;

  const _LunchTimerSection({
    required this.lunchMinutes,
    required this.lunchStartTime,
    required this.lunchEndTime,
    required this.lunchActive,
    required this.onStartLunch,
    required this.onStopLunch,
    required this.onEditLunch,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (lunchActive) {
      // Timer is running — show elapsed + Stop button
      final elapsed = DateTime.now().difference(lunchStartTime!);
      final mins = elapsed.inMinutes;
      final secs = elapsed.inSeconds % 60;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.restaurant, size: 16, color: theme.colorScheme.tertiary),
            const SizedBox(width: 4),
            Text('Lunch  ', style: theme.textTheme.bodyMedium),
            Text(
              '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
            const Spacer(),
            _SmallButton(
              onPressed: onStopLunch,
              backgroundColor: theme.colorScheme.tertiary,
              foregroundColor: theme.colorScheme.onTertiary,
              label: 'Stop',
            ),
          ],
        ),
      );
    }

    // Timer not running — show stored lunch minutes + Start button
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.restaurant, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('Lunch: $lunchMinutes min', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (lunchEndTime != null)
            Text(' (timer)', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
          const Spacer(),
          _SmallButton(
            onPressed: onStartLunch,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            label: 'Start',
          ),
          const SizedBox(width: 4),
          _SmallButton(
            onPressed: onEditLunch,
            backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            label: 'Edit',
          ),
        ],
      ),
    );
  }
}

/// A compact button with label, used in _LunchTimerSection.
class _SmallButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final String label;

  const _SmallButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: const TextStyle(fontSize: 12),
        ),
        child: Text(label),
      ),
    );
  }
}

/// A colored banner that appears at the top when an alert fires.
class _AlertBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _AlertBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrgent = message.contains('🚨');
    return Card(
      color: isUrgent ? theme.colorScheme.errorContainer : theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              isUrgent ? Icons.warning_rounded : Icons.info_outlined,
              color: isUrgent ? theme.colorScheme.onErrorContainer : theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
