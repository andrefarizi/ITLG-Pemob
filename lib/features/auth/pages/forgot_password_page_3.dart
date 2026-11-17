import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../widgets/auth_design.dart';

/// Lupa Password – langkah 3: Sandi Baru (Figma "Lupa Password 3"),
/// diakhiri popup "Kata Sandi Diubah".
class ForgotPasswordPage3 extends StatefulWidget {
  const ForgotPasswordPage3({super.key});

  @override
  State<ForgotPasswordPage3> createState() => _ForgotPasswordPage3State();
}

class _ForgotPasswordPage3State extends State<ForgotPasswordPage3> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  String? _passwordError;
  String? _confirmError;
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Kata sandi baru wajib diisi';
    if (value.length < 8) return 'Minimal 8 karakter';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasDigit = RegExp(r'\d').hasMatch(value);
    if (!hasLetter || !hasDigit) return 'Gunakan kombinasi huruf dan angka';
    return null;
  }

  void _backToLogin() => popToBeforeForgotPassword(context);

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _passwordError = _validatePassword(_password.text);
      _confirmError = _confirm.text.isEmpty
          ? 'Konfirmasi kata sandi wajib diisi'
          : (_confirm.text != _password.text
              ? 'Konfirmasi kata sandi tidak sama'
              : null);
    });
    if (_passwordError != null || _confirmError != null) return;

    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _loading = false);

    await showAuthResultDialog(
      context,
      icon: Icons.key_rounded,
      title: 'Kata Sandi Diubah',
      message:
          'Kata sandi anda berhasil diubah silahkan kembali ke halaman masuk',
      buttonLabel: 'Halaman Masuk',
      buttonIcon: Icons.login_rounded,
      onPressed: _backToLogin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      children: [
        const ResetPasswordHeader(step: 3),
        const SizedBox(height: 24),
        ItlgCard(
          padding: const EdgeInsets.fromLTRB(16, 38, 16, 38),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ItlgTextField(
                label: 'Kata Sandi Baru',
                hint: 'Minimal 8 Karakter Kombinasi',
                icon: Icons.lock_rounded,
                controller: _password,
                obscure: true,
                textInputAction: TextInputAction.next,
                errorText: _passwordError,
                onChanged: (_) {
                  if (_passwordError != null) {
                    setState(() => _passwordError = null);
                  }
                },
              ),
              const SizedBox(height: 18),
              ItlgTextField(
                label: 'Konfirmasi Kata Sandi Baru',
                hint: '••••••••••••',
                icon: Icons.lock_rounded,
                controller: _confirm,
                obscure: true,
                textInputAction: TextInputAction.done,
                errorText: _confirmError,
                onChanged: (_) {
                  if (_confirmError != null) {
                    setState(() => _confirmError = null);
                  }
                },
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 18),
              ItlgPrimaryButton(
                label: 'Konfirmasi',
                trailingIcon: Icons.login_rounded,
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              ItlgLinkRow(
                text: 'Sudah Ingat Akun?',
                link: 'Kembali ke Masuk >',
                onTap: _backToLogin,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
