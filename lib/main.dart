import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/app_strings.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';
import 'screens/migration_screen.dart';
import 'screens/passphrase_screen.dart';
import 'screens/pending_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/signup_screen.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';
import 'services/notification_service.dart';
import 'services/pinned_journey_store.dart';
import 'services/theme_service.dart';
import 'app_state.dart';

// Compile-time injection via --dart-define-from-file=secrets.json
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  }

  await ThemeService().init();
  await LocaleService().init();
  await AuthService().init();
  await PinnedJourneyStore().init();

  // Re-read the cross-device language once the DEK is available.
  if (AuthService().dek != null) {
    await LocaleService().syncFromServer();
  }

  // Pre-load app data so the first frame never shows setup screen
  final auth = AuthService();
  if (auth.isAuthenticated && auth.profile?.isApproved == true) {
    await AppState().refresh();
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
    _auth.addListener(_onAuthChanged);
    // Data already loaded in main(), just set up the listener.
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (_auth.isAuthenticated && _auth.profile?.isApproved == true) {
      _state.refresh();
      // Passphrase unlock may have happened after startup — pull the
      // cross-device language now that the DEK is available.
      LocaleService().syncFromServer();
    } else {
      // Clear any in-flight leave alert so it can't linger after sign out.
      NotificationService().resetForToday();
      _state.onSignOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeService(), LocaleService()]),
      builder: (context, _) {
        final ts = ThemeService();
        return MaterialApp(
          title: 'ChronoWarden',
          debugShowCheckedModeBanner: false,
          themeMode: ts.mode,
          locale: LocaleService().locale,
          supportedLocales: const [Locale('en'), Locale('sv')],
          localizationsDelegates: const [
            AppStringsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF1E3A5F),
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: const Color(0xFF1E3A5F),
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          home: SelectionArea(
            child: _buildRoot(),
          ),
        );
      },
    );
  }

  Widget _buildRoot() {
    if (supabaseUrl.isEmpty) {
      return const _NoConfigScreen();
    }

    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        if (_auth.isInitializing) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!_auth.isAuthenticated) {
          return ListenableBuilder(
            listenable: _state,
            builder: (context, _) => _buildUnauthenticated(),
          );
        }

        final profile = _auth.profile;
        if (profile == null) {
          return const LoginScreen();
        }

        if (!profile.isApproved) {
          return const PendingScreen();
        }

        // Check if user needs to migrate to encryption
        if (_auth.needsMigration) {
          return const MigrationScreen();
        }

        // Check if user has encryption but hasn't entered passphrase yet
        if (_auth.needsPassphrase) {
          return const PassphraseScreen();
        }

        return ListenableBuilder(
          listenable: _state,
          builder: (context, _) {
            if (!_state.tablesReady) {
              return const SetupScreen();
            }
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
        if (snapshot.data == null) {
          return const SetupScreen();
        }
        if (snapshot.data == true) {
          return const SignupScreen(isFirstAdmin: true);
        }
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
