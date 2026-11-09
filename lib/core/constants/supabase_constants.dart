class AppConfig {

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ykvyosjmsinhkotvhgbs.supabase.co',
  );

  /// TODO: Replace with your actual Supabase Anon Key
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_OsVbUqdr89sxx2qEu1Klgw_JdLIIrSq',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && 
      supabaseUrl != 'YOUR_SUPABASE_URL_HERE' &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY_HERE';
}
