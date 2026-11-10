/// Global application configuration and environment settings
class AppConfig {
  AppConfig._();

  static const String appVersion = '1.0.0+1';
  static const String environment = 'development';

  // Feature Flags
  static const bool enableOfflineMode = false;
  static const bool enablePushNotifications = false;

  // Supabase Configuration Placeholders (to be configured in subsequent phases)
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

