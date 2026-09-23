import 'package:flutter/material.dart';

import '../services/preferences_service.dart';
import '../services/user_settings_service.dart';

/// Toggle to show/hide weekends in history and overview views.
class WeekendToggle extends StatefulWidget {
  const WeekendToggle({super.key});

  @override
  State<WeekendToggle> createState() => _WeekendToggleState();
}

class _WeekendToggleState extends State<WeekendToggle> {
  final _prefs = PreferencesService();
  bool? _show;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final show = await _prefs.getShowWeekends();
    if (mounted) setState(() => _show = show);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_show == null) {
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
                Icon(Icons.calendar_month, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text('Weekend days', style: theme.textTheme.titleLarge)),
                Switch(
                  value: _show!,
                  onChanged: (value) async {
                    await _prefs.setShowWeekends(value);
                    if (mounted) setState(() => _show = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _show! ? 'Weekend days are shown in history and overview.' : 'Weekend days are hidden from history and overview.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}


/// Default flex minutes setting — banked overtime spent on personal time.
class DefaultFlexSetting extends StatefulWidget {
  const DefaultFlexSetting({super.key});

  @override
  State<DefaultFlexSetting> createState() => _DefaultFlexSettingState();
}

class _DefaultFlexSettingState extends State<DefaultFlexSetting> {
  final _settings = UserSettingsService();
  int _flexMinutes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final minutes = await _settings.getDefaultFlexMinutes();
    if (mounted) {
      setState(() {
        _flexMinutes = minutes;
        _loading = false;
      });
    }
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
                Icon(Icons.schedule, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text('Default flex time', style: theme.textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Banked overtime you take as personal time each day.\nLeave time and overtime calculations adjust automatically.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Minutes: '),
                Expanded(
                  child: Slider(
                    value: _flexMinutes.toDouble(),
                    min: 0,
                    max: 120,
                    divisions: 24,
                    label: '$_flexMinutes min',
                    onChanged: (v) => setState(() => _flexMinutes = v.round()),
                  ),
                ),
                Text('$_flexMinutes min', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        await _settings.setDefaultFlexMinutes(_flexMinutes);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Default flex time saved')),
                        );
                      },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Slider interval setting — step size for lunch/flex sliders.
class SliderIntervalSetting extends StatefulWidget {
  const SliderIntervalSetting({super.key});

  @override
  State<SliderIntervalSetting> createState() => _SliderIntervalSettingState();
}

class _SliderIntervalSettingState extends State<SliderIntervalSetting> {
  final _prefs = PreferencesService();
  int _interval = 5;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final interval = await _prefs.getSliderInterval();
    if (mounted) {
      setState(() {
        _interval = interval;
        _loading = false;
      });
    }
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
                Icon(Icons.tune, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Slider step size',
                      style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Interval between slider ticks for lunch and flex time.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Minutes: '),
                Expanded(
                  child: Slider(
                    value: _interval.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    label: '$_interval min',
                    onChanged: (v) =>
                        setState(() => _interval = v.round()),
                  ),
                ),
                Text('$_interval min',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        await _prefs.setSliderInterval(_interval);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Slider interval saved'),
                          ),
                        );
                      },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

