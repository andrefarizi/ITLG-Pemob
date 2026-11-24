import 'package:flutter/material.dart';

import '../../core/widgets/itlg_ui.dart';
import '../auth/auth_controller.dart';
import '../auth/pages/forgot_password_page_1.dart';
import '../auth/widgets/auth_design.dart';
import '../laboran/widgets/laboran_ui.dart';

/// Halaman Ubah Kata Sandi.
class UbahKataSandiPage extends StatefulWidget {
  final VoidCallback? onLogoTap;
  const UbahKataSandiPage({super.key, this.onLogoTap});

  @override
  State<UbahKataSandiPage> createState() => _UbahKataSandiPageState();
}

class _UbahKataSandiPageState extends State<UbahKataSandiPage> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _next = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNext = true;
  bool _hideConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: kForgotPasswordRoute),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const ForgotPasswordPage1(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final cur = _current.text.trim();
    final nxt = _next.text.trim();
    final cnf = _confirm.text.trim();

    if (cur.isEmpty) {
      labToast(context, 'Masukkan kata sandi saat ini terlebih dahulu');
      return;
    }
    if (nxt.length < 8) {
      labToast(context, 'Kata sandi baru minimal 8 karakter');
      return;
    }
    if (nxt != cnf) {
      labToast(context, 'Konfirmasi kata sandi baru tidak cocok');
      return;
    }
    if (cur == nxt) {
      labToast(context, 'Kata sandi baru harus berbeda dari kata sandi saat ini');
      return;
    }

    setState(() => _submitting = true);
    final res = await AuthController.instance.changePassword(
      currentPassword: cur,
      newPassword: nxt,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!res.success) {
      labToast(
        context,
        res.errorMessage ?? 'Kata sandi saat ini salah. Silakan coba lagi.',
      );
      return;
    }

    await labShowResultDialog(
      context,
      icon: 'key',
      title: 'Kata Sandi Diperbarui',
      message:
          'Gunakan kata sandi baru saat masuk berikutnya. Kamu tetap masuk di perangkat ini.',
      button: 'Kembali ke Profil',
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return LabColumn(
      gap: 8,
      children: [
        Text(label, style: labText(14, c: ItlgColors.text)),
        InnerShadowBox(
          radius: 12,
          height: 48,
          color: ItlgColors.field,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const LabIcon('lock_on', size: 20, color: ItlgColors.textSubtle),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  cursorColor: ItlgColors.primary,
                  style: labText(12, w: kSemiBold),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: hint,
                    hintStyle:
                        labText(12, w: kSemiBold, c: ItlgColors.textMuted),
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: ItlgColors.textSubtle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      gap: 24,
      children: [
        LabCard(
          gap: 10,
          children: [
            Center(
              child: InnerShadowBox(
                width: 56,
                height: 56,
                radius: 14,
                color: ItlgColors.field,
                shadows: ItlgShadows.innerLarge,
                child: const Center(
                  child: Icon(
                    Icons.lock_reset_rounded,
                    size: 35,
                    color: ItlgColors.primary,
                  ),
                ),
              ),
            ),
            Text(
              'Ubah Kata Sandi',
              textAlign: TextAlign.center,
              style: labText(22, w: kBold),
            ),
            Text(
              'Masukkan kata sandi saat ini, lalu buat kata sandi baru. Tidak perlu kode OTP karena kamu sudah masuk.',
              textAlign: TextAlign.center,
              style: labText(14, c: ItlgColors.textMuted),
            ),
          ],
        ),
        LabCard(
          gap: 16,
          children: [
            _passwordField(
              label: 'Kata Sandi Saat Ini',
              controller: _current,
              hint: 'Minimal 8 Karakter Kombinasi',
              obscure: _hideCurrent,
              onToggle: () => setState(() => _hideCurrent = !_hideCurrent),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openForgotPassword,
                child: Text(
                  'Lupa kata sandi saat ini?',
                  style: labText(14, w: kBold, c: ItlgColors.secondary),
                ),
              ),
            ),
            _passwordField(
              label: 'Kata Sandi Baru',
              controller: _next,
              hint: 'Minimal 8 Karakter Kombinasi',
              obscure: _hideNext,
              onToggle: () => setState(() => _hideNext = !_hideNext),
            ),
            _passwordField(
              label: 'Ulangi Kata Sandi Baru',
              controller: _confirm,
              hint: '************',
              obscure: _hideConfirm,
              onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _submit,
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: ItlgColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: ItlgShadows.primary,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _submitting
                          ? 'Memverifikasi...'
                          : 'Simpan Kata Sandi Baru',
                      style: labText(16, w: kBold, c: ItlgColors.surfaceWhite),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.login_rounded,
                      size: 21,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Batal mengubah?', style: labText(12, w: kSemiBold)),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Text(
                    'Kembali ke Profil >',
                    style: labText(12, w: kBold, c: ItlgColors.secondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
