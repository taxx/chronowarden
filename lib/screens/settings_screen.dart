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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section<WorkPeriodSetting>(
                title: 'Work Periods',
                subtitle: 'Seasonal work-day lengths',
                items: _state.workPeriods,
                itemBuilder: (p) => Text('${p.name}: ${p.expectedMinutes} min (${p.startDate} → ${p.endDate})'),
                deleteItem: (p) => _state.deleteWorkPeriod(p.id!),
                addCallback: () => _showAddPeriodDialog(context),
              ),
              const SizedBox(height: 24),
              _Section<TravelPreset>(
                title: 'Travel Presets',
                subtitle: 'Commute scenarios with overhead buffer',
                items: _state.travelPresets,
                itemBuilder: (p) => Text('${p.name}: +${p.defaultOverheadMinutes} min overhead'),
                deleteItem: (p) => _state.deleteTravelPreset(p.id!),
                addCallback: () => _showAddPresetDialog(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddPeriodDialog(BuildContext ctx) async {
    final nameCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final minsCtrl = TextEditingController(text: '480');

    await showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Add Work Period'),
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
              final period = WorkPeriodSetting(
                name: nameCtrl.text,
                startDate: startCtrl.text,
                endDate: endCtrl.text,
                expectedMinutes: int.tryParse(minsCtrl.text) ?? 480,
              );
              Navigator.pop(ctx);
              _state.addWorkPeriod(period);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPresetDialog(BuildContext ctx) async {
    final nameCtrl = TextEditingController();
    final minsCtrl = TextEditingController(text: '60');

    await showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Add Travel Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: minsCtrl, decoration: const InputDecoration(labelText: 'Overhead minutes'), keyboardType: const TextInputType.numberWithOptions()),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final preset = TravelPreset(
                name: nameCtrl.text,
                defaultOverheadMinutes: int.tryParse(minsCtrl.text) ?? 60,
              );
              Navigator.pop(ctx);
              _state.addTravelPreset(preset);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _Section<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final void Function(T) deleteItem;
  final VoidCallback addCallback;

  const _Section({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.itemBuilder,
    required this.deleteItem,
    required this.addCallback,
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
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => deleteItem(item),
                ),
              )),
        FilledButton.icon(
          onPressed: addCallback,
          icon: const Icon(Icons.add),
          label: Text('Add ${title.split(' ').first.toLowerCase()}'),
        ),
      ],
    );
  }
}
