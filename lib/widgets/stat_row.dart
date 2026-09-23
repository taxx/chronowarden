import 'package:flutter/material.dart';

/// A label/value row used inside summary cards.
///
/// Two layouts match the existing screens:
/// - default: label on the left, bold value on the right (`spaceBetween`)
/// - [expanded]: label, then a bold value that fills the remaining width
///   (used where the value can be long, e.g. the transit tab)
///
/// [verticalPadding] defaults to 2; the My Day card uses 4.
class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final double verticalPadding;
  final bool expanded;

  /// Optional colour for the value text (e.g. red for overtime, green for
  /// undertime). Defaults to the row's normal text colour.
  final Color? valueColor;

  const StatRow({
    super.key,
    required this.label,
    required this.value,
    this.verticalPadding = 2,
    this.expanded = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (expanded) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Row(
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }
}
