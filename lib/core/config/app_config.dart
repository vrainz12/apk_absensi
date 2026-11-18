/// Konfigurasi API dan Endpoint Layanan Aplikasi Ruang Magang
/// 
/// Untuk menjalankan aplikasi pada environment produksi atau development pribadi:
/// 1. Masukkan URL dan Anon Key dari Supabase Dashboard -> Project Settings -> API.
/// 2. Masukkan URL Webhook Google Apps Script jika menggunakan integrasi Spreadsheet.
class AppConfig {
  /// URL Project Supabase
  static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';

  /// Supabase Public / Anon Key
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  /// Endpoint Webhook Google Apps Script (Opsional)
  static const String appsScriptUrl = 'https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec';
}
