import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/travel_preset.dart';
import '../models/work_config.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../services/user_settings_service.dart';
import '../utils/csv_export.dart';

String _fmtMins(int minutes) {
  final abs = minutes.abs();
  final h = abs ~/ 60;
  final m = abs % 60;
  if (h == 0) return '$m min';
  return '${h}h ${m}m';
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _state = AppState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: _state,
        builder: (context, _) {
          // Show error if any CRUD failed.
          final err = _state.lastError;
          final child = _buildBody(context);
          if (err != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _state.clearLastError();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $err')),
                );
              }
            });
          }
          return child;
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _WorkConfigSection(onEdit: () => _showWorkConfigDialog(context)),
        const SizedBox(height: 24),
        _Section<TravelPreset>(
          title: 'Travel Presets',
          subtitle: 'Commute scenarios with overhead buffer',
          items: _state.travelPresets,
          itemBuilder: (p) => Text('${p.name}: ${p.morningOverheadMinutes}/${p.eveningOverheadMinutes} min overhead, ${p.morningProductiveCommuteMinutes}/${p.eveningProductiveCommuteMinutes} min train work'),
          onEdit: (p) => _showEditPresetDialog(context, p),
          onDelete: (p) => _confirmDeletePreset(context, p),
          onAdd: () => _showAddPresetDialog(context),
        ),
        const SizedBox(height: 24),
        _NotificationSettings(),
        const SizedBox(height: 24),
        _WeekendToggle(),
        const SizedBox(height: 24),
        _DefaultFlexSetting(),
        const SizedBox(height: 24),
        _ExportSection(),
      ],
    );
  }

  // -- Work config section -------------------------------------------

  Future<void> _showWorkConfigDialog(BuildContext ctx) async {
    final cfg = _state.workConfig;
    final dfltCtrl = TextEditingController(text: (cfg?.defaultExpectedMinutes ?? 480).toString());
    final reducedCtrl = TextEditingController(text: cfg?.reducedExpectedMinutes?.toString() ?? '');
    final startWeekCtrl = TextEditingController(text: cfg?.reducedStartWeek?.toString() ?? '');
    final endWeekCtrl = TextEditingController(text: cfg?.reducedEndWeek?.toString() ?? '');

    final result = await showDialog<bool>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Work Hours Configuration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dfltCtrl,
                  decoration: const InputDecoration(labelText: 'Default minutes per day'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text('Reduced period (optional — e.g. summer time)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: reducedCtrl,
                  decoration: const InputDecoration(labelText: 'Reduced minutes per day'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: startWeekCtrl,
                  decoration: const InputDecoration(labelText: 'Start week (ISO, 1-53)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: endWeekCtrl,
                  decoration: const InputDecoration(labelText: 'End week (ISO, 1-53)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Text(
                  'Leave reduced fields empty to disable the reduced period.',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final dflt = int.tryParse(dfltCtrl.text);
                if (dflt == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Default minutes must be a valid number')),
                  );
                  return;
                }
                final hasReduced = reducedCtrl.text.isNotEmpty ||
                    startWeekCtrl.text.isNotEmpty || endWeekCtrl.text.isNotEmpty;
                if (hasReduced) {
                  final r = int.tryParse(reducedCtrl.text);
                  final sw = int.tryParse(startWeekCtrl.text);
                  final ew = int.tryParse(endWeekCtrl.text);
                  if (r == null || sw == null || ew == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All reduced fields must be valid numbers')),
                    );
                    return;
                  }
                  if (sw < 1 || sw > 53 || ew < 1 || ew > 53) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Weeks must be between 1 and 53')),
                    );
                    return;
                  }
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final dflt = int.parse(dfltCtrl.text);
      final hasReduced = reducedCtrl.text.isNotEmpty;
      final cfg = WorkConfig(
        defaultExpectedMinutes: dflt,
        reducedExpectedMinutes: hasReduced ? int.parse(reducedCtrl.text) : null,
        reducedStartWeek: hasReduced ? int.parse(startWeekCtrl.text) : null,
        reducedEndWeek: hasReduced ? int.parse(endWeekCtrl.text) : null,
      );
      await _state.saveWorkConfig(cfg);
      if (ctx.mounted) _showResult(ctx);
    }
  }

  // -- Feedback helper -------------------------------------------------

  /// Show snackbar after a CRUD operation (uses parent context to survive dialog pop).
  void _showResult(BuildContext ctx) {
    if (!ctx.mounted) return;
    final err = _state.lastError;
    if (err != null) {
      _state.clearLastError();
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $err')));
    } else {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('✓ Saved')));
    }
  }

  // -- Travel preset dialogs -----------------------------------------

  Future<void> _showAddPresetDialog(BuildContext ctx) async {
    final result = await _showPresetDialog(ctx);
    if (result != null) {
      await _state.addTravelPreset(result);
      if (ctx.mounted) _showResult(ctx);
    }
  }

  Future<void> _showEditPresetDialog(BuildContext ctx, TravelPreset preset) async {
    final result = await _showPresetDialog(ctx, existing: preset);
    if (result != null) {
      await _state.updateTravelPreset(result);
      if (ctx.mounted) _showResult(ctx);
    }
  }

  Future<TravelPreset?> _showPresetDialog(
    BuildContext ctx, {
    TravelPreset? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final morningOverheadCtrl = TextEditingController(text: existing?.morningOverheadMinutes.toString() ?? '0');
    final morningProductiveCtrl = TextEditingController(text: existing?.morningProductiveCommuteMinutes.toString() ?? '0');
    final eveningOverheadCtrl = TextEditingController(text: existing?.eveningOverheadMinutes.toString() ?? '0');
    final eveningProductiveCtrl = TextEditingController(text: existing?.eveningProductiveCommuteMinutes.toString() ?? '0');

    final result = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Travel Preset' : 'Edit Travel Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: morningOverheadCtrl, decoration: const InputDecoration(labelText: 'Morning overhead (walking to office)'), keyboardType: const TextInputType.numberWithOptions(),),
            const SizedBox(height: 8),
            TextField(controller: morningProductiveCtrl, decoration: const InputDecoration(labelText: 'Morning productive commute (train work)'), keyboardType: const TextInputType.numberWithOptions(),),
            const SizedBox(height: 8),
            TextField(controller: eveningOverheadCtrl, decoration: const InputDecoration(labelText: 'Evening overhead (walking from office)'), keyboardType: const TextInputType.numberWithOptions(),),
            const SizedBox(height: 8),
            TextField(controller: eveningProductiveCtrl, decoration: const InputDecoration(labelText: 'Evening productive commute (train work)'), keyboardType: const TextInputType.numberWithOptions(),),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty &&
                  int.tryParse(morningOverheadCtrl.text) != null &&
                  int.tryParse(morningProductiveCtrl.text) != null &&
                  int.tryParse(eveningOverheadCtrl.text) != null &&
                  int.tryParse(eveningProductiveCtrl.text) != null) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      return TravelPreset(
        id: existing?.id,
        name: nameCtrl.text,
        morningOverheadMinutes: int.parse(morningOverheadCtrl.text),
        morningProductiveCommuteMinutes: int.parse(morningProductiveCtrl.text),
        eveningOverheadMinutes: int.parse(eveningOverheadCtrl.text),
        eveningProductiveCommuteMinutes: int.parse(eveningProductiveCtrl.text),
      );
    }
    return null;
  }

  Future<void> _confirmDeletePreset(BuildContext ctx, TravelPreset p) async {
    final inUse = _state.isPresetInUse(p);
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete Travel Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete "${p.name}"?'),
            if (inUse) ...[
              const SizedBox(height: 12),
              Text(
                '⚠ This preset matches one or more logged days. Deleting it won\'t affect those logs (they store their own copy of the minutes).',
                style: const TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await _state.deleteTravelPreset(p.id!);
    }
  }
}

// ---------------------------------------------------------------------------
// Notification settings card
// ---------------------------------------------------------------------------

class _NotificationSettings extends StatefulWidget {
  @override
  State<_NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<_NotificationSettings> {
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
              _ToggleRow(
                icon: Icons.spatial_audio_outlined,
                label: 'Sound alert',
                value: _notifications.soundEnabled,
                onChanged: (v) async {
                  await _notifications.setSoundEnabled(v);
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 8),
              _ToggleRow(
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

/// Toggle to show/hide weekends in history and overview views.
class _WeekendToggle extends StatefulWidget {
  @override
  State<_WeekendToggle> createState() => _WeekendToggleState();
}

class _WeekendToggleState extends State<_WeekendToggle> {
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
class _DefaultFlexSetting extends StatefulWidget {
  @override
  State<_DefaultFlexSetting> createState() => _DefaultFlexSettingState();
}

class _DefaultFlexSettingState extends State<_DefaultFlexSetting> {
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
    if (mounted) setState(() {
      _flexMinutes = minutes;
      _loading = false;
    });
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
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Default flex time saved')),
                          );
                        }
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

/// Small reusable toggle row used in notification settings.
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Future<void> Function(bool) onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Switch(
          value: value,
          onChanged: (v) async {
            await onChanged(v);
            if (context.mounted) {} // rebuild handled upstream
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Work config card
// ---------------------------------------------------------------------------

class _WorkConfigSection extends StatelessWidget {
  final VoidCallback onEdit;

  const _WorkConfigSection({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final theme = Theme.of(context);
    final cfg = state.workConfig;
    final dflt = cfg?.defaultExpectedMinutes ?? 480;
    final hasReduced = cfg?.hasReducedPeriod ?? false;
    final reducedMinutes = cfg?.reducedExpectedMinutes;
    final reducedStartWeek = cfg?.reducedStartWeek;
    final reducedEndWeek = cfg?.reducedEndWeek;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text('Work Hours', style: theme.textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Configure your expected work time per day.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _statRow(theme, 'Default', '${_fmtMins(dflt)} per day'),
            if (hasReduced) ...[
              _statRow(
                theme,
                'Reduced period',
                '${_fmtMins(reducedMinutes!)} per day',
              ),
              _statRow(
                theme,
                'ISO weeks',
                '$reducedStartWeek – $reducedEndWeek',
              ),
            ] else ...[
              _statRow(theme, 'Reduced period', 'Not configured'),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit configuration'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
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
}

// ---------------------------------------------------------------------------
// Reusable section widget
// ---------------------------------------------------------------------------

class _Section<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final void Function(T) onEdit;
  final void Function(T) onDelete;
  final VoidCallback onAdd;

  const _Section({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.itemBuilder,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        Text(subtitle, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('None configured', style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
          )
        else
          ...items.map((item) => ListTile(
                title: itemBuilder(item),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () => onEdit(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => onDelete(item),
                    ),
                  ],
                ),
              )),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text('Add ${title.split(' ').first.toLowerCase()}'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Export section
// ---------------------------------------------------------------------------

class _ExportSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text('Export / Import', style: theme.textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Download all your time logs as CSV or import from a CSV file.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final csv = timeLogsToCsv(state.allLogs);
                      final dateStr = DateTime.now().toIso8601String().split('T').first;
                      downloadCsv(csv, 'chronowarden_export_$dateStr.csv');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Exported ${state.allLogs.length} logs'),
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Export CSV'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showImportDialog(context, state),
                    icon: const Icon(Icons.file_upload_outlined, size: 18),
                    label: const Text('Import CSV'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImportDialog(BuildContext ctx, AppState state) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Import CSV'),
        content: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paste your CSV data below.', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: 'date,start_time,end_time,expected_minutes,overhead_minutes,lunch_minutes,productive_commute_minutes,note\n...',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      final importResult = await state.importDaysFromCsv(controller.text);

      if (!ctx.mounted) return;

      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${importResult.imported.length} day(s)'
            '${importResult.skipped > 0 ? ', ${importResult.skipped} skipped (duplicates)' : ''}'
            '${importResult.hasErrors ? ', ${importResult.errors.length} error(s)' : ''}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      if (importResult.hasErrors) {
        showDialog(
          context: ctx,
          builder: (_) => AlertDialog(
            title: const Text('Import Errors'),
            content: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: importResult.errors.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(e, style: const TextStyle(fontSize: 13)),
                )).toList(),
              ),
            ),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }
}
