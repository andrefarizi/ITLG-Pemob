import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../config/app_config.dart';

/// Service untuk pengiriman email OTP via SMTP Gmail.
class EmailService {
  static final EmailService instance = EmailService._internal();
  EmailService._internal();

  // SMTP credentials
  static const String _smtpHost = AppConfig.smtpHost;
  static const int _smtpPort = AppConfig.smtpPort;
  static const String _smtpUser = AppConfig.smtpUser;
  static const String _smtpPass = AppConfig.smtpPass;
  static const String _fromName = 'ITLG Mobile';

  // OTP store (in-memory)
  final Map<String, _OtpEntry> _otpStore = {};

  static const Duration _otpTtl = Duration(minutes: 60);

  /// Pesan galat terakhir untuk ditampilkan ke pengguna (null = berhasil).
  String? lastError;

  static String get _cleanUser => _smtpUser.trim();
  static String get _cleanPass => _smtpPass.replaceAll(RegExp(r'\s+'), '');

  /// SMTP siap bila email & sandi aplikasi Gmail diisi lewat
  /// `--dart-define` / `--dart-define-from-file` (bukan nilai contoh).
  static bool get isConfigured =>
      _cleanUser.contains('@') &&
      _cleanPass.isNotEmpty &&
      !_cleanPass.startsWith('YOUR_');

  /// Generate & kirim OTP ke [toEmail]. Return true hanya bila email benar-benar
  /// terkirim. Kode OTP tidak pernah dicetak ke log.
  Future<bool> sendOtp(String toEmail) async {
    lastError = null;
    if (!isConfigured) {
      lastError = 'Pengiriman email belum dikonfigurasi (SMTP). '
          'Hubungi admin laboratorium.';
      debugPrint('[EmailService] SMTP_PASS belum diisi. Jalankan aplikasi dengan '
          '--dart-define-from-file=dart_defines.json (lihat README).');
      return false;
    }

    final code = _generateCode();
    _otpStore[toEmail] = _OtpEntry(code: code, createdAt: DateTime.now());

    try {
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        ssl: true,
        username: _cleanUser,
        password: _cleanPass,
      );

      final message = Message()
        ..from = Address(_cleanUser, _fromName)
        ..recipients.add(toEmail)
        ..subject = 'Kode OTP Reset Kata Sandi – ITLG Mobile'
        ..html = _buildHtml(code);

      await send(message, smtpServer);
      debugPrint('[EmailService] Email OTP terkirim.');
      return true;
    } catch (e) {
      // OTP yang tidak terkirim tidak boleh bisa dipakai.
      _otpStore.remove(toEmail);
      final auth = e.toString().contains('535') ||
          e.toString().contains('Authentication');
      lastError = auth
          ? 'Server email menolak login (sandi aplikasi Gmail salah/kedaluwarsa). '
              'Hubungi admin laboratorium.'
          : 'Gagal mengirim email. Periksa koneksi internet lalu coba lagi.';
      debugPrint('[EmailService] Pengiriman SMTP gagal: $e');
      return false;
    }
  }

  /// Validasi OTP yang dimasukkan user. Return true jika cocok & belum expired.
  bool verifyOtp(String email, String code) {
    final trimmed = code.trim();
    final entry = _otpStore[email];
    if (entry == null) return false;
    final expired = DateTime.now().difference(entry.createdAt) > _otpTtl;
    if (expired) {
      _otpStore.remove(email);
      return false;
    }
    final valid = entry.code == trimmed;
    if (valid) _otpStore.remove(email); // sekali pakai
    return valid;
  }

  /// Hapus OTP untuk email tertentu (misalnya saat user kembali ke halaman 1).
  void clearOtp(String email) => _otpStore.remove(email);

  // Private helpers

  String _generateCode() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }

  String _buildHtml(String code) => '''
<!DOCTYPE html>
<html>
<body style="font-family:sans-serif;background:#f5f5f5;padding:24px;">
  <div style="max-width:480px;margin:auto;background:#fff;border-radius:16px;padding:32px;">
    <h2 style="color:#8B1A1A;margin-bottom:4px;">ITLG Mobile</h2>
    <p style="color:#555;font-size:14px;">Kode OTP Reset Kata Sandi</p>
    <hr style="border:none;border-top:1px solid #eee;margin:16px 0;">
    <p style="font-size:14px;color:#333;">
      Gunakan kode berikut untuk mereset kata sandi akun Anda.
      Kode berlaku selama <strong>60 menit</strong> dan hanya dapat digunakan sekali.
    </p>
    <div style="text-align:center;margin:24px 0;">
      <span style="
        display:inline-block;
        background:#8B1A1A;
        color:#fff;
        font-size:36px;
        font-weight:700;
        letter-spacing:12px;
        padding:16px 32px;
        border-radius:12px;
      ">$code</span>
    </div>
    <p style="font-size:12px;color:#999;">
      Jika Anda tidak meminta reset kata sandi, abaikan email ini.
    </p>
  </div>
</body>
</html>
''';
}

class _OtpEntry {
  final String code;
  final DateTime createdAt;
  const _OtpEntry({required this.code, required this.createdAt});
}
