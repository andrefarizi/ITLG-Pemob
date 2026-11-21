/// Konfigurasi Supabase untuk ITLG Mobile.
///
/// Dapatkan URL dan anonKey dari Dashboard Supabase Anda:
/// Project Settings > API > Project URL & anon (public) key.
class SupabaseConfig {
  /// URL Project Supabase Anda.
  static const String url = 'https://ctdglzvbmhmgrsykikni.supabase.co';

  /// Anon Key (Public) Supabase Anda.
  static const String anonKey =
      'sb_publishable_hX7kM1a1Ym8U9E46LX0Vrg_dUVwR7GE';

  /// Cek apakah kredensial Supabase sudah diisi dengan benar.
  static bool get isConfigured =>
      url.startsWith('https://') &&
      !url.contains('YOUR_PROJECT_REF') &&
      anonKey.isNotEmpty &&
      anonKey != 'YOUR_SUPABASE_ANON_KEY';
}