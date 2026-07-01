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
///
/// Tab switching pushes named routes onto the root Navigator so the browser
/// URL updates. Each push uses [PageRouteBuilder] with no transition to
/// avoid hero conflicts from multiple scaffold instances. The browser back
/// button naturally pops the route stack, navigating through tab history.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  final _auth = AuthService();
  final _state = AppState();

  bool get _isAdmin => _auth.profile?.isAdmin ?? false;

  /// Route name → tab index mapping
  static int _tabIndexFromRoute(String? route) {
    if (route == null || route == '/' || route == '/my-day') return 0;
    if (route == '/history') return 1;
    if (route == '/overview') return 2;
    if (route == '/admin') return 3;
    return 0;
  }

  static String _routeFromTab(int index) {
    switch (index) {
      case 0: return '/my-day';
      case 1: return '/history';
      case 2: return '/overview';
      case 3: return '/admin';
      default: return '/my-day';
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ModalRoute is only safe to access after initState completes.
    final route = ModalRoute.of(context)?.settings.name;
    final newIndex = _tabIndexFromRoute(route);
    if (newIndex != _currentIndex) {
      setState(() => _currentIndex = newIndex);
    }
  }

  /// Push a named tab route with a silent transition so the browser URL
  /// updates but there is no hero-animation conflict between scaffolds.
  void _pushTabRoute(String routeName) {
    // ignore: prefer_const_constructors
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secondaryAnimation) => const MainShell(),
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) => child,
        settings: RouteSettings(name: routeName),
      ),
    );
  }

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

  void _switchTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pushTabRoute(_routeFromTab(index));
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin;

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home),
        label: 'My Day',
      ),
      const NavigationDestination(
        icon: Icon(Icons.history),
        label: 'History',
      ),
      const NavigationDestination(
        icon: Icon(Icons.bar_chart_rounded),
        label: 'Overview',
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
              const HistoryContent(),
              const OverviewTab(),
              if (isAdmin) const AdminScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => _switchTab(i),
        destinations: destinations,
      ),
    );
  }
}
