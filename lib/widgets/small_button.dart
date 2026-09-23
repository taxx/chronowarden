import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Compact labelled button
// ---------------------------------------------------------------------------

/// A compact button with label, used in _LunchTimerSection.
class SmallButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final String label;

  const SmallButton({
    super.key,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: const TextStyle(fontSize: 12),
        ),
        child: Text(label),
      ),
    );
  }
}

