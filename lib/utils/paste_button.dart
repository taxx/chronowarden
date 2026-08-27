import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A paste button that works on Flutter web (iOS Safari).
///
/// iOS Safari doesn't fire paste events to Flutter's canvas-rendered
/// TextFields. This button reads from [Clipboard] directly and inserts
/// the content into [controller].
class PasteButton extends StatelessWidget {
  final TextEditingController controller;
  final double size;

  const PasteButton({
    super.key,
    required this.controller,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.content_paste, size: size),
      onPressed: () => _paste(),
      tooltip: 'Paste',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      // Insert at cursor position, or append if no selection
      final start = controller.selection.start;
      final end = controller.selection.end;
      if (start >= 0 && end >= 0) {
        controller.text = controller.text.replaceRange(
          start < end ? start : end,
          start < end ? end : start,
          data.text!,
        );
        final newPos = (start < end ? start : end) + data.text!.length;
        controller.selection = TextSelection.collapsed(offset: newPos);
      } else {
        final old = controller.text.length;
        controller.text = controller.text + data.text!;
        controller.selection = TextSelection.collapsed(offset: old + data.text!.length);
      }
    }
  }
}
