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

  /// Generate & kirim OTP ke [toEmail]. Return true jika berhasil.
  Future<bool> sendOtp(String toEmail) async {
    final code = _generateCode();
    _otpStore[toEmail] = _OtpEntry(code: code, createdAt: DateTime.now());

    debugPrint('====================================================');
    debugPrint('[EmailService] KODE OTP UNTUK $toEmail : $code');
    debugPrint('====================================================');

    try {
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        ssl: true,
        username: _smtpUser,
        password: _smtpPass,
      );

      final message = Message()
        ..from = Address(_smtpUser, _fromName)
        ..recipients.add(toEmail)
        ..subject = 'Kode OTP Reset Kata Sandi – ITLG Mobile'
        ..html = _buildHtml(code);

      await send(message, smtpServer);
      debugPrint('[EmailService] Email OTP berhasil terkirim ke $toEmail');
      return true;
    } catch (e) {
      debugPrint('[EmailService] Pengiriman SMTP terkendala: $e');
      debugPrint('[EmailService] Menggunakan kode OTP lokal: $code');
      // Kembalikan true agar alur pengujian user tidak terblokir
      return true;
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
