import 'package:flutter/material.dart';

import '../models/station_info.dart';

/// Autocomplete text field for SL station search.
///
/// Fetches the full site list once via [onFetchSites], then filters
/// client-side as the user types. No network calls per keystroke.
class StationPicker extends StatefulWidget {
  final String label;
  final String hint;
  final StationInfo? initialValue;
  final ValueChanged<StationInfo?> onSelected;
  final Future<List<StationInfo>?> Function() onFetchSites;

  const StationPicker({
    super.key,
    required this.label,
    this.hint = 'Search station...',
    this.initialValue,
    required this.onSelected,
    required this.onFetchSites,
  });

  @override
  State<StationPicker> createState() => _StationPickerState();
}

class _StationPickerState extends State<StationPicker> {
  final _controller = TextEditingController();
  List<StationInfo>? _allSites;
  List<StationInfo> _filtered = [];
  bool _loading = false;
  StationInfo? _selected;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
    if (_selected != null) {
      _controller.text = _selected!.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Fetch sites if not already cached.
  Future<void> _ensureSites() async {
    if (_allSites != null) return;
    setState(() => _loading = true);
    final sites = await widget.onFetchSites();
    if (!mounted) return;
    setState(() {
      _allSites = sites;
      _loading = false;
    });
  }

  void _onSearchChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _filtered = [];
        _selected = null;
        _showDropdown = false;
      });
      widget.onSelected(null);
      return;
    }

    final sites = _allSites ?? [];
    final lower = value.toLowerCase();
    setState(() {
      _filtered = sites
          .where((s) => s.name.toLowerCase().contains(lower))
          .take(20)
          .toList();
      _showDropdown = true;
      _selected = null;
    });
  }

  void _selectStation(StationInfo station) {
    setState(() {
      _selected = station;
      _controller.text = station.name;
      _showDropdown = false;
    });
    widget.onSelected(station);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: _loading ? 'Loading stations...' : widget.hint,
            suffixIcon: _loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search, size: 18),
                    onPressed: _ensureSites,
                    tooltip: 'Browse stations',
                  ),
          ),
          onChanged: _onSearchChanged,
          onTap: () {
            if (_allSites == null) _ensureSites();
            if (_controller.text.isNotEmpty && _filtered.isNotEmpty) {
              setState(() => _showDropdown = true);
            }
          },
        ),
        if (_showDropdown && _filtered.isNotEmpty) _buildDropdown(theme),
        if (_showDropdown && _filtered.isEmpty && _controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'No stations matching "${_controller.text}"',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdown(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _filtered.map((station) {
            final isSelected = _selected?.id == station.id;
            return InkWell(
              onTap: () => _selectStation(station),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 16,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        station.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                    Text(
                      '${station.id}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
