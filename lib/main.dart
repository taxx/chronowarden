import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final url = String.fromEnvironment('SUPABASE_URL');
  final anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  await Supabase.initialize(url: url, publishableKey: anonKey);

  runApp(const ChronoWardenApp());
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
