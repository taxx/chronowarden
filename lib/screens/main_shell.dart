import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_info.dart';
import '../app_state.dart';
import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';
import '../services/transit_service.dart';
import '../services/update_service.dart';
import '../utils/external_link.dart';
import '../widgets/alert_banner.dart';
import '../widgets/update_banner.dart';
import 'admin_screen.dart';
import 'history_content.dart';
import 'my_day_tab.dart';
import 'overview_tab.dart';
import 'projection_screen.dart';
import 'settings_screen.dart';
import 'transit_screen.dart';

/// Unified shell for all authenticated, approved users.
/// Single Scaffold, single AppBar, single NavigationBar.
///
/// Bottom nav tabs:
///   My Day (0, default)  |  History (1)  |  Overview (2)  |  Admin (3, admin-only)
///
/// Settings accessed via gear icon in AppBar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _auth = AuthService();
  final _state = AppState();
  final _notifications = NotificationService();
  final _updates = UpdateService();

  @override
  void initState() {
    super.initState();
    _updates.start();
  }

  @override
  void dispose() {
    _updates.stop();
    super.dispose();
  }

  /// Quick access to the GitHub issue tracker.
  Widget _reportIssueButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.bug_report),
      tooltip: context.t('Report an issue or request a feature'),
      onPressed: () => openExternalLink(context, AppInfo.issuesUrl),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.t('Sign out')),
        content: Text(context.t('Are you sure you want to sign out?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t('Sign Out')),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_auth, _state, _notifications, _updates]),
      builder: (context, _) {
        final isAdmin = _auth.profile?.isAdmin ?? false;

        final transitEnabled = TransitService().config.enabled;

        final destinations = <NavigationDestination>[
          NavigationDestination(
              icon: const Icon(Icons.home), label: context.t('My Day')),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_rounded),
            label: context.t('Overview'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.trending_down),
            label: context.t('Projection'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: context.t('History'),
          ),
          if (transitEnabled)
            NavigationDestination(
              icon: const Icon(Icons.directions_train),
              label: context.t('Transit'),
            ),
          if (isAdmin)
            NavigationDestination(
              icon: const Icon(Icons.admin_panel_settings),
              label: context.t('Admin'),
            ),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                SvgPicture.asset(
                  'chronowarden.svg',
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                const Text('ChronoWarden'),
              ],
            ),
            actions: [
              _reportIssueButton(context),
              ListenableBuilder(
                listenable: ThemeService(),
                builder: (context, _) {
                  final ts = ThemeService();
                  IconData icon;
                  String tooltip;
                  switch (ts.mode) {
                    case ThemeMode.light:
                      icon = Icons.sunny;
                      tooltip = context.t('Light mode');
                      break;
                    case ThemeMode.dark:
                      icon = Icons.nightlight_round;
                      tooltip = context.t('Dark mode');
                      break;
                    case ThemeMode.system:
                      icon = Icons.brightness_auto;
                      tooltip = context.t('Auto (system)');
                      break;
                  }
                  return IconButton(
                    icon: Icon(icon),
                    tooltip: tooltip,
                    onPressed: () => ts.cycleMode(),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: context.t('Settings'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                tooltip: context.t('Sign out'),
                onPressed: _handleLogout,
              ),
            ],
          ),
          body: Column(
            children: [
              // New-build prompt (reload into the latest deployment).
              if (_updates.updateAvailable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: UpdateBanner(
                    message: _updates.serverBuild?.commit.isNotEmpty == true
                        ? context.t(
                            'A new version ({commit}) is available — reload to update.',
                            {'commit': _updates.serverBuild!.commit},
                          )
                        : context.t(
                            'A new version is available — reload to update.'),
                    onReload: _updates.reload,
                    onDismiss: _updates.dismiss,
                  ),
                ),
              // Leave-time alert is shown globally so it is visible on every tab.
              if (_notifications.currentAlert != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: AlertBanner(
                    message: _notifications.currentAlert!.message,
                    isUrgent: _notifications.currentAlert!.isUrgent,
                    snoozeLabel: context.t(
                      'Snooze {minutes}m',
                      {'minutes': _notifications.snoozeMinutes},
                    ),
                    onSnooze: () => _notifications.snooze(),
                    onDismiss: () => _notifications.dismiss(),
                  ),
                ),
              Expanded(
                child: ListenableBuilder(
                  listenable: _state,
                  builder: (context, _) {
                    final showTransit = TransitService().config.enabled;
                    return IndexedStack(
                      index: _currentIndex,
                      children: [
                        const MyDayTab(),
                        const OverviewTab(),
                        const ProjectionScreen(),
                        const HistoryContent(),
                        if (showTransit) const TransitScreen(),
                        if (isAdmin) const AdminScreen(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            destinations: destinations,
          ),
        );
      },
    );
  }
}
