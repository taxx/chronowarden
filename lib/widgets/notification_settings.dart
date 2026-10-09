import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import 'toggle_row.dart';

/// Notification preferences section.
class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  final _notifications = NotificationService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _notifications.init();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text('Notifications', style: theme.textTheme.titleLarge)),
                Switch(
                  value: _notifications.enabled,
                  onChanged: (value) async {
                    await _notifications.setEnabled(value);
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Get notified before it\'s time to leave work.',
              style: theme.textTheme.bodySmall,
            ),
            if (_notifications.enabled) ...[
              const SizedBox(height: 16),
              _thresholdSlider(theme),
              const SizedBox(height: 16),
              _snoozeSlider(theme),
              const SizedBox(height: 16),
              ToggleRow(
                icon: Icons.spatial_audio_outlined,
                label: 'Sound alert',
                value: _notifications.soundEnabled,
                onChanged: (v) async {
                  await _notifications.setSoundEnabled(v);
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 8),
              ToggleRow(
                icon: Icons.vibration_rounded,
                label: 'Vibration',
                value: _notifications.vibrateEnabled,
                onChanged: (v) async {
                  await _notifications.setVibrateEnabled(v);
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _notifications.ensureAudio();
                  _notifications.alertMessage(
                    'ChronoWarden ⏰',
                    'Test alert — you\'d be notified here!',
                    isUrgent: true,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Test alert fired — check for sound & vibration'),
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('Send test'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _snoozeSlider(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Snooze duration', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _notifications.snoozeMinutes.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                label: '${_notifications.snoozeMinutes} min',
                onChanged: (v) {
                  final value = v.round();
                  _notifications.setSnoozeMinutes(value);
                  setState(() {});
                },
              ),
            ),
            Text('${_notifications.snoozeMinutes} min',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _thresholdSlider(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Minutes before leave', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _notifications.thresholdMinutes.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                label: '${_notifications.thresholdMinutes} min',
                onChanged: (v) {
                  final value = v.round();
                  _notifications.setThresholdMinutes(value);
                  setState(() {});
                },
              ),
            ),
            Text('${_notifications.thresholdMinutes} min',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

