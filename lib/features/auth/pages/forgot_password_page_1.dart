import 'package:flutter/material.dart';

import '../../../core/services/email_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../services/auth_service.dart';
import '../widgets/auth_design.dart';
import 'forgot_password_page_2.dart';

/// Lupa Password – langkah 1: Akun (Figma "Lupa Password").
class ForgotPasswordPage1 extends StatefulWidget {
  const ForgotPasswordPage1({super.key});

  @override
  State<ForgotPasswordPage1> createState() => _ForgotPasswordPage1State();
}

class _ForgotPasswordPage1State extends State<ForgotPasswordPage1> {
  final TextEditingController _nim = TextEditingController();
  final TextEditingController _email = TextEditingController();
  String? _nimError;
  String? _emailError;
  bool _loading = false;

  static final RegExp _usuEmail =
      RegExp(r'^[\w.+-]+@(students\.)?usu\.ac\.id$', caseSensitive: false);

  @override
  void dispose() {
    _nim.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    final nim = _nim.text.trim();
    final email = _email.text.trim();
    setState(() {
      _nimError = nim.isEmpty ? 'NIM / NIP wajib diisi' : null;
      _emailError = email.isEmpty
          ? 'Email USU wajib diisi'
          : (_usuEmail.hasMatch(email)
              ? null
              : 'Gunakan email @usu.ac.id atau @students.usu.ac.id');
    });
    if (_nimError != null || _emailError != null) return;

    setState(() => _loading = true);

    try {
      // 1. Cari email berdasarkan NIM/NIP di database
      final registeredEmail = await AuthService.instance.findEmailByNimOrEmail(nim);

      if (!mounted) return;

      if (registeredEmail == null) {
        setState(() {
          _loading = false;
          _nimError = 'NIM / NIP tidak ditemukan dalam sistem';
        });
        return;
      }

      // 2. Validasi email yang dimasukkan cocok dengan yang terdaftar
      if (registeredEmail.toLowerCase() != email.toLowerCase()) {
        setState(() {
          _loading = false;
          _emailError = 'Email tidak sesuai dengan NIM/NIP yang terdaftar';
        });
        return;
      }

      // 3. Kirim OTP via SMTP
      final sent = await EmailService.instance.sendOtp(registeredEmail);

      if (!mounted) return;
      setState(() => _loading = false);

      if (!sent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Gagal mengirim email. Periksa koneksi internet Anda.'),
          ),
        );
        return;
      }

      // 4. Tampilkan dialog sukses lalu lanjut ke halaman 2
      await showAuthResultDialog(
        context,
        icon: Icons.password_rounded,
        title: 'Kode OTP Dikirim',
        message: 'Kode OTP anda berhasil dikirim silahkan periksa email usu anda',
        buttonLabel: 'Lanjutkan',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ForgotPasswordPage2(
                targetIdentifier: registeredEmail,
                targetEmail: registeredEmail,
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Terjadi kesalahan: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      children: [
        const ResetPasswordHeader(step: 1),
        const SizedBox(height: 24),
        ItlgCard(
          padding: const EdgeInsets.fromLTRB(16, 27, 16, 27),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ItlgTextField(
                label: 'NIM / NIP',
                hint: 'Contoh : 241402105 atau NIP',
                icon: Icons.badge_outlined,
                controller: _nim,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                errorText: _nimError,
                onChanged: (_) {
                  if (_nimError != null) setState(() => _nimError = null);
                },
              ),
              const SizedBox(height: 18),
              ItlgTextField(
                label: 'Email USU',
                hint: 'nama@students.usu.ac.id',
                icon: Icons.alternate_email_rounded,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                errorText: _emailError,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
                onSubmitted: (_) => _sendOtp(),
              ),
              const SizedBox(height: 18),
              const AuthNotice(),
              const SizedBox(height: 18),
              ItlgPrimaryButton(
                label: 'Kirim Kode OTP',
                leadingIcon: Icons.mark_email_unread_rounded,
                loading: _loading,
                onPressed: _sendOtp,
              ),
              const SizedBox(height: 12),
              ItlgLinkRow(
                text: 'Sudah Ingat Akun?',
                link: 'Kembali ke Masuk >',
                onTap: () => popToBeforeForgotPassword(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
