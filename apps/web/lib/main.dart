import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
import 'services/preferences_service.dart';
import 'services/theme_service.dart';
import 'app_state.dart';

/// Kept alive for the lifetime of the app when semantics are force-enabled:
/// disposing the handle would switch the accessibility tree back off.
// ignore: unused_element
SemanticsHandle? _semanticsHandle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // End-to-end tests (Playwright) drive the app through the accessibility
  // semantics tree, which Flutter only materialises in the DOM when enabled.
  // Off by default so production builds are unaffected.
  if (const bool.fromEnvironment('ENABLE_SEMANTICS')) {
    _semanticsHandle = SemanticsBinding.instance.ensureSemantics();
  }

  // The API base URL defaults to the same-origin `/api/v1`. Local development
  // can override it with --dart-define=API_URL=http://localhost:8080/api/v1.
  await ThemeService().init();
  await LocaleService().init();
  await AuthService().init();
  await PinnedJourneyStore().init();
  await PreferencesService().init();

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

  bool _audioPrimed = false;

  /// Unlock the alert audio on the first user gesture — browsers keep the
  /// Web Audio context suspended otherwise, making the alert beep silent.
  void _primeAudioOnce() {
    if (_audioPrimed) return;
    _audioPrimed = true;
    NotificationService().primeAudio();
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
          // Capture the first pointer-down anywhere to unlock alert audio.
          builder: (context, child) => Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _primeAudioOnce(),
            child: child ?? const SizedBox.shrink(),
          ),
          home: SelectionArea(
            child: _buildRoot(),
          ),
        );
      },
    );
  }

  Widget _buildRoot() {
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
