import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'admin_screen.dart';
import 'history_content.dart';
import 'my_day_tab.dart';
import 'overview_tab.dart';
import 'settings_screen.dart';

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

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out')),
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
      listenable: _auth,
      builder: (context, _) {
        final isAdmin = _auth.profile?.isAdmin ?? false;

        final destinations = <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.home),
            label: 'My Day',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Overview',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
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
              ListenableBuilder(
                listenable: ThemeService(),
                builder: (context, _) {
                  final ts = ThemeService();
                  IconData icon;
                  String tooltip;
                  switch (ts.mode) {
                    case ThemeMode.light:
                      icon = Icons.sunny;
                      tooltip = 'Light mode';
                      break;
                    case ThemeMode.dark:
                      icon = Icons.nightlight_round;
                      tooltip = 'Dark mode';
                      break;
                    case ThemeMode.system:
                      icon = Icons.brightness_auto;
                      tooltip = 'Auto (system)';
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
                tooltip: 'Settings',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                tooltip: 'Sign out',
                onPressed: _handleLogout,
              ),
            ],
          ),
          body: ListenableBuilder(
            listenable: _state,
            builder: (context, _) {
              return IndexedStack(
                index: _currentIndex,
                children: [
                  const MyDayTab(),
                  const OverviewTab(),
                  const HistoryContent(),
                  if (isAdmin) const AdminScreen(),
                ],
              );
            },
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
