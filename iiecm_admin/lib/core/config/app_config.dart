/// Configuration for IIECM Admin application
/// Values are supplied at build or run time via `--dart-define` or `--dart-define-from-file`.
class AppConfig {
  /// Supabase project URL (e.g. https://xyz.supabase.co)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Supabase public publishable/anon key
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
      return 'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.';
    }
    final uri = Uri.tryParse(supabaseUrl);
    final host = uri?.host ?? 'configured-host';
    return 'Connected to $host with anon key (${supabaseAnonKey.length} chars)';
  }
}

