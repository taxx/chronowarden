import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_state.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';
import 'screens/pending_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/signup_screen.dart';
import 'services/auth_service.dart';

// Compile-time injection via --dart-define-from-file=secrets.json
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  }

  runApp(const ChronoWardenApp());
}

class ChronoWardenApp extends StatefulWidget {
  const ChronoWardenApp({super.key});

  @override
  State<ChronoWardenApp> createState() => _ChronoWardenAppState();
}

class _ChronoWardenAppState extends State<ChronoWardenApp> {
  final _state = AppState();
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Listen for auth state changes so we refresh app data after login.
    _auth.addListener(_onAuthChanged);
    // Initialise auth first, then app data.
    await _auth.init();
    if (_auth.isAuthenticated && _auth.profile?.isApproved == true) {
      await _state.refresh();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// Called whenever AuthService notifies — refresh app data after login.
  void _onAuthChanged() {
    if (_auth.isAuthenticated && _auth.profile?.isApproved == true) {
      _state.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: MaterialApp(
        title: 'ChronoWarden',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF1E3A5F),
          useMaterial3: true,
        ),
        home: _buildRoot(),
      ),
    );
  }

  Widget _buildRoot() {
    if (supabaseUrl.isEmpty) {
      return const _NoConfigScreen();
    }

    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        // Still checking session…
        if (_auth.isInitializing) {
          return const Center(child: CircularProgressIndicator());
        }

        // Not logged in → decide between login, signup (first admin), or setup.
        // Also listen to _state so the DB verification in SetupScreen triggers a rebuild.
        if (!_auth.isAuthenticated) {
          return ListenableBuilder(
            listenable: _state,
            builder: (context, _) => _buildUnauthenticated(),
          );
        }

        // Logged in — check profile status.
        final profile = _auth.profile;
        if (profile == null) {
          return const LoginScreen();
        }

        // Pending approval.
        if (!profile.isApproved) {
          return const PendingScreen();
        }

        // Approved — show the main app (check if tables exist).
        return ListenableBuilder(
          listenable: _state,
          builder: (context, _) {
            if (!_state.tablesReady) {
              return const SetupScreen();
            }
            // Unified shell — My Day | History | Admin (admin-only tab).
            return const MainShell();
          },
        );
      },
    );
  }

  Widget _buildUnauthenticated() {
    return FutureBuilder<bool?>(
      future: _auth.checkDatabaseState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Tables don't exist yet → must run SQL setup first.
        if (snapshot.data == null) {
          return const SetupScreen();
        }
        // Tables exist, no profiles → first admin signup.
        if (snapshot.data == true) {
          return const SignupScreen(isFirstAdmin: true);
        }
        // Tables exist with users → normal login.
        return const LoginScreen();
      },
    );
  }
}

class _NoConfigScreen extends StatelessWidget {
  const _NoConfigScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Supabase credentials not found.\n\n'
            'Copy secrets.json.template → secrets.json, fill in your '
            'SUPABASE_URL and SUPABASE_ANON_KEY, then run:\n\n'
            'flutter run --dart-define-from-file=secrets.json',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
