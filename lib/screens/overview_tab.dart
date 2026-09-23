import 'package:flutter/material.dart';

import '../models/period.dart';
import '../widgets/period_tab.dart';

/// Aggregated overview: week / month / year summaries with period navigation.
class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  // Shared offset state so month/year navigation can sync
  int _monthOffset = 0;
  int _yearOffset = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  /// Called when a month card is tapped in the year view.
  void _navigateToMonth(int year, int month) {
    final now = DateTime.now();
    // Calculate offset relative to current month
    final targetMonths = year * 12 + month;
    final currentMonths = now.year * 12 + now.month;
    _monthOffset = targetMonths - currentMonths;
    _tabCtrl.index = 1; // switch to Month tab
    // Force rebuild — the Month PeriodTab reads _monthOffset from parent
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Week'),
            Tab(text: 'Month'),
            Tab(text: 'Year'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              PeriodTab(period: Period.week),
              PeriodTab(period: Period.month, externalOffset: _monthOffset, onOffsetChanged: (v) => _monthOffset = v),
              PeriodTab(period: Period.year, onMonthSelected: _navigateToMonth, externalOffset: _yearOffset, onOffsetChanged: (v) => _yearOffset = v),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Period tab — stateful with offset navigation
// ---------------------------------------------------------------------------

