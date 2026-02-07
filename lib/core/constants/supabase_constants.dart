class SupabaseConstants {
  // Provide via --dart-define:
  // SUPABASE_URL, SUPABASE_ANON_KEY
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static const String studySetsTable = 'study_sets';
  static const String cardProgressTable = 'card_progress';
  static const String reviewLogsTable = 'review_logs';
}
