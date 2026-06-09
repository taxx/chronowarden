import 'package:flutter/material.dart';

import '../app_state.dart';

/// Lists all past logs and shows the cumulative time-bank balance.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _state = AppState();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final theme = Theme.of(context);
        final logs = _state.allLogs;
        final balance = _state.timeBankMinutes;

        return RefreshIndicator(
          onRefresh: () => _state.refresh(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            balance >= 0 ? Icons.savings : Icons.warning_amber_rounded,
                            color: balance >= 0 ? theme.colorScheme.primary : Colors.orange,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Time Bank Balance', style: theme.textTheme.titleSmall),
                                Text(
                                  _formatBalance(balance),
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: balance >= 0 ? null : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (logs.isEmpty)
                const SliverFillRemaining(child: Center(child: Text('No logs yet')))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _LogCard(log: logs[i]),
                    childCount: logs.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatBalance(int minutes) {
    final sign = minutes >= 0 ? '+' : '';
    final h = minutes.abs() ~/ 60;
    final m = minutes.abs() % 60;
    if (h == 0) return '$sign$m min';
    return '$sign${h}h ${m}m';
  }
}

class _LogCard extends StatelessWidget {
  final dynamic log;

  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = log.endTime != null;
    final overtime = log.overtimeMinutes;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted
              ? (overtime >= 0 ? theme.colorScheme.primaryContainer : Colors.green.shade100)
              : theme.colorScheme.secondaryContainer,
          child: Icon(
            isCompleted ? Icons.check : Icons.pending,
            size: 20,
            color: isCompleted
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(log.date),
        subtitle: Text(
          '${log.startTime}${log.endTime != null ? ' → ${log.endTime}' : ' → …'}  ·  ${log.expectedMinutes} min work + ${log.overheadMinutes} min overhead',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          isCompleted ? (overtime == 0 ? '✓' : '$overtime min') : 'active',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isCompleted ? (overtime >= 0 ? theme.colorScheme.primary : Colors.green) : theme.colorScheme.secondary,
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}
