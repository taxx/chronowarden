import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService _instance = SupabaseService._();
  factory SupabaseService() => _instance;

  static SupabaseService get instance => _instance;

  SupabaseClient get client => Supabase.instance.client;
}
