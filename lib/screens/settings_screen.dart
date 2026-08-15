import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/travel_preset.dart';
import '../models/work_period_setting.dart';

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
        _Section<WorkPeriodSetting>(
          title: 'Work Periods',
          subtitle: 'Seasonal work-day lengths',
          items: _state.workPeriods,
          itemBuilder: (p) => Text('${p.name}: ${p.expectedMinutes} min (${p.startDate} → ${p.endDate})'),
          onEdit: (p) => _showEditPeriodDialog(context, p),
          onDelete: (p) => _confirmDeletePeriod(context, p),
          onAdd: () => _showAddPeriodDialog(context),
        ),
        const SizedBox(height: 24),
        _Section<TravelPreset>(
          title: 'Travel Presets',
          subtitle: 'Commute scenarios with overhead buffer',
          items: _state.travelPresets,
          itemBuilder: (p) => Text('${p.name}: +${p.defaultOverheadMinutes} min overhead${p.productiveCommuteMinutes > 0 ? ', +${p.productiveCommuteMinutes} min productive commute' : ''}'),
          onEdit: (p) => _showEditPresetDialog(context, p),
          onDelete: (p) => _confirmDeletePreset(context, p),
          onAdd: () => _showAddPresetDialog(context),
        ),
      ],
    );
  }

  // -- Work period dialogs -------------------------------------------

  Future<void> _showAddPeriodDialog(BuildContext ctx) async {
    final result = await _showPeriodDialog(ctx);
    if (result != null) {
      await _state.addWorkPeriod(result);
      if (ctx.mounted) _showResult(ctx);
    }
  }

  Future<void> _showEditPeriodDialog(BuildContext ctx, WorkPeriodSetting period) async {
    final result = await _showPeriodDialog(ctx, existing: period);
    if (result != null) {
      await _state.updateWorkPeriod(result);
      if (ctx.mounted) _showResult(ctx);
    }
  }

  Future<WorkPeriodSetting?> _showPeriodDialog(
    BuildContext ctx, {
    WorkPeriodSetting? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final startCtrl = TextEditingController(text: existing?.startDate ?? '');
    final endCtrl = TextEditingController(text: existing?.endDate ?? '');
    final minsCtrl = TextEditingController(text: existing?.expectedMinutes.toString() ?? '480');

    final result = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Work Period' : 'Edit Work Period'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start (YYYY-MM-DD)'), keyboardType: TextInputType.datetime),
              const SizedBox(height: 8),
              TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End (YYYY-MM-DD)'), keyboardType: TextInputType.datetime),
              const SizedBox(height: 8),
              TextField(controller: minsCtrl, decoration: const InputDecoration(labelText: 'Expected minutes'), keyboardType: const TextInputType.numberWithOptions()),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && startCtrl.text.isNotEmpty && endCtrl.text.isNotEmpty && int.tryParse(minsCtrl.text) != null) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      return WorkPeriodSetting(
        id: existing?.id,
        name: nameCtrl.text,
        startDate: startCtrl.text,
        endDate: endCtrl.text,
        expectedMinutes: int.parse(minsCtrl.text),
      );
    }
    return null;
  }

  Future<void> _confirmDeletePeriod(BuildContext ctx, WorkPeriodSetting p) async {
    final inUse = _state.isPeriodInUse(p);
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete Work Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete "${p.name}"?'),
            if (inUse) ...[
              const SizedBox(height: 12),
              Text(
                '⚠ This period matches one or more logged days. Deleting it won\'t affect those logs (they store their own copy of the minutes).',
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
      await _state.deleteWorkPeriod(p.id!);
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
    final minsCtrl = TextEditingController(text: existing?.defaultOverheadMinutes.toString() ?? '60');
    final commuteCtrl = TextEditingController(text: existing?.productiveCommuteMinutes.toString() ?? '0');

    final result = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Travel Preset' : 'Edit Travel Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: minsCtrl, decoration: const InputDecoration(labelText: 'Overhead minutes (walking, prep)'), keyboardType: const TextInputType.numberWithOptions()),
            const SizedBox(height: 8),
            TextField(controller: commuteCtrl, decoration: const InputDecoration(labelText: 'Productive commute minutes (train work)'), keyboardType: const TextInputType.numberWithOptions(),),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && int.tryParse(minsCtrl.text) != null && int.tryParse(commuteCtrl.text) != null) {
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
        defaultOverheadMinutes: int.parse(minsCtrl.text),
        productiveCommuteMinutes: int.parse(commuteCtrl.text),
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
