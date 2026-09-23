import 'package:flutter/material.dart';

import '../models/time_log.dart';
import '../utils/format.dart';

// ---------------------------------------------------------------------------
// Log card — a single past day entry
// ---------------------------------------------------------------------------

class LogCard extends StatelessWidget {
  final TimeLog log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LogCard({
    super.key,
    required this.log,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = log.endTime != null;
    final overtime = log.overtimeMinutes;
    final hasNote = log.note?.isNotEmpty == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isCompleted
                ? (overtime > 0
                    ? theme.colorScheme.errorContainer
                    : overtime < 0
                        ? Colors.green.shade100
                        : theme.colorScheme.tertiaryContainer)
                : theme.colorScheme.secondaryContainer,
            child: Icon(
              isCompleted ? Icons.check : Icons.pending,
              size: 20,
              color: isCompleted
                  ? (overtime > 0
                      ? theme.colorScheme.onErrorContainer
                      : overtime < 0
                          ? Colors.green.shade700
                          : theme.colorScheme.onTertiaryContainer)
                  : theme.colorScheme.onSecondaryContainer,
            ),
          ),
          title: Row(
            children: [
              Text(log.date),
              if (hasNote)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.note_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${log.startTime}${log.endTime != null ? ' → ${log.endTime}' : ' → …'}  ·  ${formatMins(log.expectedMinutes)} work + ${formatMins(log.overheadMinutes)} overhead${log.lunchMinutes > 0 ? ' · ${formatMins(log.lunchMinutes)} lunch' : ''}',
                style: theme.textTheme.bodySmall,
              ),
              if (hasNote)
                Text('📝 ${log.note}', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                )),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCompleted ? (overtime == 0 ? '✓' : formatMins(overtime)) : 'active',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? (overtime > 0
                          ? theme.colorScheme.error
                          : overtime < 0
                              ? Colors.green.shade700
                              : theme.colorScheme.primary)
                      : theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade700),
              ),
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 18, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}
