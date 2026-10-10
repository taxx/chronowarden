import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_strings.dart';
import '../models/travel_preset.dart';
import '../models/work_config.dart';
import '../widgets/about_app_section.dart';
import '../widgets/encryption_settings_section.dart';
import '../widgets/export_settings_section.dart';
import '../widgets/language_setting.dart';
import '../widgets/notification_settings.dart';
import '../widgets/personal_settings.dart';
import '../widgets/section_card.dart';
import '../widgets/transit_config_section.dart';
import '../widgets/work_config_section.dart';

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
      appBar: AppBar(title: Text(context.t('Settings'))),
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
                  SnackBar(content: Text(context.t('Error: {error}', {'error': err}))),
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
        WorkConfigSection(onEdit: () => _showWorkConfigDialog(context)),
        const SizedBox(height: 24),
        SectionCard<TravelPreset>(
          title: 'Travel Presets',
          subtitle: 'Commute scenarios with overhead buffer',
          items: _state.travelPresets,
          itemBuilder: (p) => Text(context.t(
            '{name}: {amOverhead}/{pmOverhead} min overhead, {amProductive}/{pmProductive} min train work',
            {
              'name': p.name,
              'amOverhead': p.morningOverheadMinutes,
              'pmOverhead': p.eveningOverheadMinutes,
              'amProductive': p.morningProductiveCommuteMinutes,
              'pmProductive': p.eveningProductiveCommuteMinutes,
            },
          )),
          onEdit: (p) => _showEditPresetDialog(context, p),
          onDelete: (p) => _confirmDeletePreset(context, p),
          onAdd: () => _showAddPresetDialog(context),
        ),
        const SizedBox(height: 24),
        TransitConfigSection(),
        const SizedBox(height: 24),
        NotificationSettings(),
        const SizedBox(height: 24),
        WeekendToggle(),
        const SizedBox(height: 24),
        DefaultFlexSetting(),
        const SizedBox(height: 24),
        SliderIntervalSetting(),
        const SizedBox(height: 24),
        LanguageSetting(),
        const SizedBox(height: 24),
        ExportSection(),
        const SizedBox(height: 24),
        EncryptionSection(),
        const SizedBox(height: 24),
        AboutAppSection(),
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
          title: Text(context.t('Work Hours Configuration')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dfltCtrl,
                  decoration: InputDecoration(labelText: context.t('Default minutes per day')),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Text(context.t('Reduced period (optional — e.g. summer time)'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: reducedCtrl,
                  decoration: InputDecoration(labelText: context.t('Reduced minutes per day')),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: startWeekCtrl,
                  decoration: InputDecoration(labelText: context.t('Start week (ISO, 1-53)')),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: endWeekCtrl,
                  decoration: InputDecoration(labelText: context.t('End week (ISO, 1-53)')),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Text(
                  context.t('Leave reduced fields empty to disable the reduced period.'),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('Cancel'))),
            FilledButton(
              onPressed: () {
                final dflt = int.tryParse(dfltCtrl.text);
                if (dflt == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.t('Default minutes must be a valid number'))),
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
                      SnackBar(content: Text(context.t('All reduced fields must be valid numbers'))),
                    );
                    return;
                  }
                  if (sw < 1 || sw > 53 || ew < 1 || ew > 53) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.t('Weeks must be between 1 and 53'))),
                    );
                    return;
                  }
                }
                Navigator.pop(ctx, true);
              },
              child: Text(context.t('Save')),
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
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(ctx.t('Error: {error}', {'error': err}))));
    } else {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(ctx.t('✓ Saved'))));
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

    CommuteMode commuteMode = existing?.commuteMode ?? CommuteMode.none;

    final result = await showDialog<bool>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null
              ? context.t('Add Travel Preset')
              : context.t('Edit Travel Preset')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: context.t('Name'))),
              const SizedBox(height: 8),
              TextField(controller: morningOverheadCtrl, decoration: InputDecoration(labelText: context.t('Morning overhead (walking to office)')), keyboardType: const TextInputType.numberWithOptions(),),
              const SizedBox(height: 8),
              TextField(controller: morningProductiveCtrl, decoration: InputDecoration(labelText: context.t('Morning productive commute (train work)')), keyboardType: const TextInputType.numberWithOptions(),),
              const SizedBox(height: 8),
              TextField(controller: eveningOverheadCtrl, decoration: InputDecoration(labelText: context.t('Evening overhead (walking from office)')), keyboardType: const TextInputType.numberWithOptions(),),
              const SizedBox(height: 8),
              TextField(controller: eveningProductiveCtrl, decoration: InputDecoration(labelText: context.t('Evening productive commute (train work)')), keyboardType: const TextInputType.numberWithOptions(),),
              const SizedBox(height: 12),
              DropdownButton<CommuteMode>(
                value: commuteMode,
                isExpanded: true,
                items: CommuteMode.values.map((mode) {
                  final label = switch (mode) {
                    CommuteMode.none => context.t('No commute (work from home)'),
                    CommuteMode.transit => context.t('Public transit (train/bus)'),
                    CommuteMode.car => context.t('Car (coming soon)'),
                    CommuteMode.vespa => context.t('🛵 Vespa (coming soon)'),
                  };
                  return DropdownMenuItem(
                    value: mode,
                    child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => commuteMode = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('Cancel'))),
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
              child: Text(existing == null ? context.t('Add') : context.t('Save')),
            ),
          ],
        ),
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
        commuteMode: commuteMode,
      );
    }
    return null;
  }

  Future<void> _confirmDeletePreset(BuildContext ctx, TravelPreset p) async {
    final inUse = _state.isPresetInUse(p);
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(ctx.t('Delete Travel Preset')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ctx.t('Delete "{name}"?', {'name': p.name})),
            if (inUse) ...[
              const SizedBox(height: 12),
              Text(
                ctx.t('⚠ This preset matches one or more logged days. Deleting it won\'t affect those logs (they store their own copy of the minutes).'),
                style: const TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: Text(ctx.t('Delete'))),
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

