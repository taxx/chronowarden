import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_strings.dart';
import '../models/station_info.dart';
import '../models/transit_config.dart';
import '../services/transit_service.dart';
import 'station_picker.dart';

// ---------------------------------------------------------------------------
// Transit config section
// ---------------------------------------------------------------------------

class TransitConfigSection extends StatefulWidget {
  const TransitConfigSection({super.key});

  @override
  State<TransitConfigSection> createState() => _TransitConfigSectionState();
}

class _TransitConfigSectionState extends State<TransitConfigSection> {
  final _transit = TransitService();
  TransitConfig? _cfg;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _transit.loadConfig();
    if (mounted) {
      setState(() {
        _cfg = _transit.config;
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

    final cfg = _cfg!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.train, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(context.t('Transit Integration'),
                      style: theme.textTheme.titleLarge),
                ),
                Switch(
                  value: cfg.enabled,
                  onChanged: (value) => _update(cfg.copyWith(enabled: value)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.t('Journey planning between home and work stations.'),
              style: theme.textTheme.bodySmall,
            ),
            if (cfg.enabled) ...[ 
              const SizedBox(height: 16),
              _StationField(
                label: context.t('Work station'),
                initialValue: cfg.hasWork
                    ? StationInfo(id: cfg.workStopId, name: cfg.workStopName)
                    : null,
                onSelected: (station) {
                  if (station != null) {
                    _update(cfg.copyWith(
                      workStopId: station.id,
                      workStopName: station.name,
                    ));
                  }
                },
              ),
              const SizedBox(height: 12),
              _StationField(
                label: context.t('Home station'),
                initialValue: cfg.hasHome
                    ? StationInfo(id: cfg.homeStopId, name: cfg.homeStopName)
                    : null,
                onSelected: (station) {
                  if (station != null) {
                    _update(cfg.copyWith(
                      homeStopId: station.id,
                      homeStopName: station.name,
                    ));
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(context.t('Walk home↔station'), style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: cfg.walkHomeMinutes.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: context.t('{minutes} min', {'minutes': cfg.walkHomeMinutes}),
                      onChanged: (v) => _update(
                        cfg.copyWith(walkHomeMinutes: v.round())),
                    ),
                  ),
                  Text(context.t('{minutes} min', {'minutes': cfg.walkHomeMinutes}),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              Text(context.t('Walk station↔work'), style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: cfg.walkWorkMinutes.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: context.t('{minutes} min', {'minutes': cfg.walkWorkMinutes}),
                      onChanged: (v) => _update(
                        cfg.copyWith(walkWorkMinutes: v.round())),
                    ),
                  ),
                  Text(context.t('{minutes} min', {'minutes': cfg.walkWorkMinutes}),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  context.t('Departure data provided by Trafiklab.se (CC-BY 4.0)'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ]
        ),
      ),
    );
  }

  void _update(TransitConfig updated) {
    setState(() => _cfg = updated);
    // AppState owns the apply + persist + notify flow so dependent UI
    // (nav visibility, My Day transit card) stays in sync.
    AppState().saveTransitConfig(updated);
  }
}

/// A station picker field used inside [TransitConfigSection].
class _StationField extends StatelessWidget {
  final String label;
  final StationInfo? initialValue;
  final ValueChanged<StationInfo?> onSelected;

  const _StationField({
    required this.label,
    this.initialValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return StationPicker(
      label: label,
      hint: context.t('Type to search SL stations...'),
      initialValue: initialValue,
      onSelected: onSelected,
      onFetchStops: (query) => TransitService().fetchStops(query),
    );
  }
}
