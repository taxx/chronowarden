import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/auth_service.dart';
import 'admin_screen.dart';
import 'home_screen.dart';

/// Admin shell: User Management | ChronoWarden tabs + logout.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;
  final _auth = AuthService();

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChronoWarden'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: AppState(),
        builder: (context, _) {
          return IndexedStack(
            index: _currentIndex,
            children: const [
              AdminScreen(),
              HomeScreen(showSettings: true, showLogout: false),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.group_outlined), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.home), label: 'My Day'),
        ],
      ),
    );
  }
}
