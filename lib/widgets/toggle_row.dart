import 'package:flutter/material.dart';

/// Small reusable toggle row used in settings sections.
class ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Future<void> Function(bool) onChanged;

  const ToggleRow({
    super.key,
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

