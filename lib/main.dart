import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Compile-time injection via --dart-define-from-file=secrets.json
// (String.fromEnvironment is const-only; empty at runtime if not passed).
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    runApp(const MissingConfigApp());
    return;
  }

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

  runApp(const ChronoWardenApp());
}

// Shown when secrets are missing — tells the user exactly what to do.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
      ),
    );
  }
}

class ChronoWardenApp extends StatelessWidget {
  const ChronoWardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChronoWarden',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1E3A5F),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('ChronoWarden')),
      ),
    );
  }
}
