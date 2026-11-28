import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Layanan pengiriman dan verifikasi OTP pemulihan kata sandi via Supabase Auth.
class EmailService {
  static final EmailService instance = EmailService._internal();
  EmailService._internal();

  /// Pesan galat terakhir untuk ditampilkan ke pengguna (null = berhasil).
  String? lastError;

  /// Kirim email kode OTP pemulihan kata sandi melalui Supabase Auth.
  Future<bool> sendOtp(String toEmail) async {
    lastError = null;
    final cleanEmail = toEmail.trim().toLowerCase();
    final client = SupabaseService.instance.client;

    if (client == null) {
      lastError = 'Layanan autentikasi belum terhubung. Periksa koneksi internet.';
      return false;
    }

    try {
      await client.auth.resetPasswordForEmail(cleanEmail);
      debugPrint('[EmailService] Permintaan OTP pemulihan dikirim via Supabase Auth.');
      return true;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('rate limit') ||
          msg.contains('security purposes') ||
          e.statusCode == '429') {
        lastError =
            'Terlalu banyak permintaan OTP. Tunggu sebentar lalu coba lagi.';
      } else if (msg.contains('not authorized') || msg.contains('smtp')) {
        lastError =
            'Pengiriman email ditolak server. Pastikan Custom SMTP di Dashboard Supabase sudah aktif.';
      } else {
        lastError = 'Gagal mengirim kode OTP: ${e.message}';
      }
      debugPrint('[EmailService] Supabase resetPasswordForEmail gagal: ${e.message}');
      return false;
    } catch (e) {
      lastError = 'Gagal mengirim kode OTP. Periksa koneksi internet Anda.';
      debugPrint('[EmailService] Error sendOtp: $e');
      return false;
    }
  }

  /// Verifikasi kode OTP 6-digit pemulihan kata sandi ke Supabase Auth.
  Future<bool> verifyOtp(String email, String code) async {
    lastError = null;
    final cleanEmail = email.trim().toLowerCase();
    final trimmed = code.trim();
    final client = SupabaseService.instance.client;

    if (client == null) {
      lastError = 'Layanan autentikasi belum terhubung.';
      return false;
    }

    try {
      final res = await client.auth.verifyOTP(
        email: cleanEmail,
        token: trimmed,
        type: OtpType.recovery,
      );
      final ok = res.session != null || res.user != null;
      if (!ok) {
        lastError = 'Kode OTP salah atau sudah kedaluwarsa';
      }
      return ok;
    } on AuthException catch (e) {
      lastError = 'Kode OTP salah atau sudah kedaluwarsa';
      debugPrint('[EmailService] verifyOTP gagal: ${e.message}');
      return false;
    } catch (e) {
      lastError = 'Gagal memverifikasi OTP. Periksa koneksi internet Anda.';
      debugPrint('[EmailService] verifyOTP error: $e');
      return false;
    }
  }

  /// Kompatibilitas pemanggilan lama saat kembali ke halaman sebelumnya.
  void clearOtp(String email) {
    lastError = null;
  }
}
