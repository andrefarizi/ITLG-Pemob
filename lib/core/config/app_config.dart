/// Konfigurasi dan kredensial aplikasi ITLG Mobile.
/// Kredensial sensitif disensor demi keamanan repositori.
/// Kredensial dapat dioverride melalui --dart-define saat build atau secara lokal.
class AppConfig {
  AppConfig._();

  // ── SMTP Gmail (Kirim OTP Lupa Password) ──────────────────────────────────
  static const String smtpHost = 'smtp.gmail.com';
  static const int smtpPort = 465;
  static const String smtpUser = String.fromEnvironment(
    'SMTP_USER',
    defaultValue: '0andre.alfa.com@gmail.com',
  );

  /// Sandi aplikasi Gmail (disensor di repositori)
  static const String smtpPass = String.fromEnvironment(
    'SMTP_PASS',
    defaultValue: 'YOUR_SMTP_APP_PASSWORD',
  );

  // ── Google Maps API Key ───────────────────────────────────────────────────
  /// Kunci API Google Maps (disensor di repositori)
  static const String googleMapsApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: 'YOUR_GOOGLE_MAPS_API_KEY',
  );
}
