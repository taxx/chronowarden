import 'package:flutter/material.dart';

/// A titled list section with edit/delete actions and an add button.
class SectionCard<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final void Function(T) onEdit;
  final void Function(T) onDelete;
  final VoidCallback onAdd;

  const SectionCard({
    super.key,
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


