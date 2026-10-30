import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Centralized access to the Supabase client
class AppSupabase {
  static bool _isInitialized = false;

  /// Returns true if Supabase SDK has been successfully initialized
  static bool get isInitialized => _isInitialized;

  /// Initializes Supabase using compile-time or run-time environment variables
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    if (!AppConfig.isSupabaseConfigured) {
      developer.log(
        'Supabase configuration missing: SUPABASE_URL or SUPABASE_ANON_KEY is empty.',
        name: 'AppSupabase',
      );
      return false;
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl.trim(),
        anonKey: AppConfig.supabaseAnonKey.trim(),
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: true,
        ),
      );
      _isInitialized = true;
      developer.log(
        'Supabase initialized successfully (${AppConfig.configurationSummary})',
        name: 'AppSupabase',
      );
      return true;
    } catch (e, stack) {
      developer.log(
        'Failed to initialize Supabase: $e',
        name: 'AppSupabase',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// Authoritative SupabaseClient singleton
  static SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError(
        'Supabase has not been initialized. Ensure AppSupabase.initialize() succeeded before accessing client.',
      );
    }
    return Supabase.instance.client;
  }
}
