class AppConfig {
  // TODO: Replace these with your actual Supabase credentials
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
          supabaseUrl != 'YOUR_SUPABASE_URL_HERE' &&
          supabaseAnonKey.isNotEmpty &&
          supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY_HERE';
}