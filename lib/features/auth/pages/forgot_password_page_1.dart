import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
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
      _nimError = nim.isEmpty ? 'Nomor Induk Mahasiswa wajib diisi' : null;
      _emailError = email.isEmpty
          ? 'Email USU wajib diisi'
          : (_usuEmail.hasMatch(email)
              ? null
              : 'Gunakan email @usu.ac.id atau @students.usu.ac.id');
    });
    if (_nimError != null || _emailError != null) return;

    // Simulasi pengiriman OTP (belum ada backend)
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _loading = false);

    await showAuthResultDialog(
      context,
      icon: Icons.password_rounded,
      title: 'Kode OTP Dikirim',
      message: 'Kode OTP anda berhasil dikirim silahkan periksa email usu anda',
      buttonLabel: 'Lanjutkan',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ForgotPasswordPage2(targetIdentifier: email),
          ),
        );
      },
    );
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
                label: 'Nomor Induk Mahasiswa',
                hint: 'Contoh : 123456789',
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
