import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_state.dart';
import 'screens/home_screen.dart';
import 'screens/setup_screen.dart';

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
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ready = await _state.refresh();
    setState(() {
      _initialised = true;
      _tablesReady = ready;
    });
  }

  bool _tablesReady = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChronoWarden',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1E3A5F),
        useMaterial3: true,
      ),
      home: ListenableBuilder(
        listenable: _state,
        builder: (context, _) {
          if (!_initialised) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (supabaseUrl.isEmpty) {
            return const _NoConfigScreen();
          }
          if (!_tablesReady) {
            return const SetupScreen();
          }
          return const HomeScreen();
        },
      ),
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
