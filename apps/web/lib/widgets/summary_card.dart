import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

Widget summaryCard(
  ThemeData theme,
  String label,
  String value, {
  bool isOvertime = false,
  int valueMinutes = 0,
}) {
  final color = isOvertime
      ? (valueMinutes >= 0 ? theme.colorScheme.primary : Colors.orange)
      : null;
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Week calendar — 7 day row
// ---------------------------------------------------------------------------

