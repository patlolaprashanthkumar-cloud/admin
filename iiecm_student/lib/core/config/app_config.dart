/// Global application configuration and environment settings for IIECM Student Portal.
/// Values are supplied at build or run time via `--dart-define-from-file=.env.json` or `--dart-define`.
class AppConfig {
  AppConfig._();

  static const String appVersion = '1.0.0+1';
  static const String environment = 'development';

  // Feature Flags
  static const bool enableOfflineMode = false;
  static const bool enablePushNotifications = false;

  /// Supabase project URL (e.g. https://ohflciajrdcrogqdxlvv.supabase.co)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Supabase public anon key (never use or expose service_role key)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Checks if both required Supabase parameters are supplied
  static bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  /// Debug-safe sanitized display of configuration state
  static String get configurationSummary {
    if (!isSupabaseConfigured) {
      return 'Supabase is not configured. Run with --dart-define-from-file=.env.json';
    }
    final uri = Uri.tryParse(supabaseUrl.trim());
    final host = uri?.host ?? 'configured-host';
    return 'Connected to $host with anon key (${supabaseAnonKey.trim().length} chars)';
  }
}
