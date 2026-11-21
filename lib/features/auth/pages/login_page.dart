import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/constants.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../auth_controller.dart';
import '../widgets/auth_design.dart';
import 'forgot_password_page_1.dart';

/// Halaman Masuk untuk semua peran. UI saja: belum terhubung ke backend.
///
/// Mengikuti empat status peran di Figma:
/// - "06 Prototype — Status Peran Login" > Masuk-Mahasiswa, Masuk-Asisten,
///   Masuk-Laboran
/// - "05 Umum — Login & Notifikasi" > Masuk-Semua Peran (Dosen)
///
/// Yang berubah antar status hanya chip peran yang aktif serta label dan contoh
/// nomor induk (NIM untuk Mahasiswa/Asisten, NIP untuk Laboran/Dosen).
class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController _auth = AuthController.instance;
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _password = TextEditingController();

  late UserRole _role = _auth.currentRole;
  bool _remember = false;
  bool _loading = false;
  String? _identifierError;
  String? _passwordError;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.praktikan:
        return 'Mahasiswa';
      case UserRole.aslab:
        return 'Asisten';
      case UserRole.laboran:
        return 'Laboran';
      case UserRole.dosen:
        return 'Dosen';
    }
  }

  String get _identifierLabel => _role == UserRole.praktikan ||
          _role == UserRole.aslab
      ? 'Nomor Induk Mahasiswa (NIM)'
      : 'Nomor Induk Pegawai (NIP)';

  String get _identifierHint =>
      _role == UserRole.praktikan || _role == UserRole.aslab
          ? 'Contoh : 231402033'
          : 'Contoh : 198501012010011001';

  void _selectRole(UserRole role) {
    if (role == _role) return;
    setState(() {
      _role = role;
      _identifierError = null;
    });
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final id = _identifier.text.trim();
    final pass = _password.text;
    setState(() {
      _identifierError = id.isEmpty ? '$_identifierLabel wajib diisi' : null;
      _passwordError = pass.isEmpty ? 'Kata sandi wajib diisi' : null;
    });
    if (_identifierError != null || _passwordError != null) return;

    setState(() => _loading = true);
    final result = await _auth.loginWithCredentials(
      identifier: id,
      password: pass,
      role: _role,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.success) {
      final msg =
          result.errorMessage ?? 'Gagal masuk. Periksa kembali data Anda.';
      setState(() {
        if (msg.contains('Nomor Induk') || msg.contains('tidak terdaftar')) {
          _identifierError = msg;
        } else {
          _passwordError = msg;
        }
      });
      return;
    }

    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: kForgotPasswordRoute),
        builder: (_) => const ForgotPasswordPage1(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: ItlgColors.surfaceWhite,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildIntro(),
                const SizedBox(height: 24),
                _buildForm(),
                const SizedBox(height: 24),
                const HelpCenterCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      children: [
        Container(
          width: 154,
          height: 73,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ItlgColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            boxShadow: ItlgShadows.outline,
          ),
          child: Image.asset(
            'assets/login_logo.png',
            width: 134,
            height: 53,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Selamat Datang\nKembali',
          textAlign: TextAlign.center,
          style: ItlgText.style(
            size: 27,
            weight: FontWeight.w700,
            color: Colors.black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'Pilih peran, lalu masukkan nomor induk dan kata sandi anda',
            textAlign: TextAlign.center,
            style: ItlgText.style(height: 1.2),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return ItlgCard(
      padding: const EdgeInsets.fromLTRB(16, 21, 16, 21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Masuk Sebagai', style: ItlgText.style(height: 1.2)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final role in UserRole.values) ...[
                  _RoleChip(
                    label: _roleLabel(role),
                    selected: role == _role,
                    onTap: () => _selectRole(role),
                  ),
                  if (role != UserRole.values.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeOut,
            child: ItlgTextField(
              key: ValueKey(_identifierLabel),
              label: _identifierLabel,
              hint: _identifierHint,
              icon: Icons.badge_outlined,
              iconAsset: 'assets/ic_login_id_card.png',
              controller: _identifier,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              errorText: _identifierError,
              onChanged: (_) {
                if (_identifierError != null) {
                  setState(() => _identifierError = null);
                }
              },
            ),
          ),
          const SizedBox(height: 18),
          ItlgTextField(
            label: 'Kata Sandi',
            hint: '************',
            icon: Icons.lock_outline_rounded,
            iconAsset: 'assets/ic_login_lock.png',
            showObscureToggle: true,
            controller: _password,
            obscure: true,
            textInputAction: TextInputAction.done,
            errorText: _passwordError,
            onChanged: (_) {
              if (_passwordError != null) setState(() => _passwordError = null);
            },
            onSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _remember = !_remember),
                child: Row(
                  children: [
                    _Checkbox(checked: _remember),
                    const SizedBox(width: 8),
                    Text('Ingat Saya',
                        style: ItlgText.style(
                            size: 12, color: Colors.black, height: 1.2)),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openForgotPassword,
                child: Text(
                  'Lupa Password?',
                  style: ItlgText.style(
                    weight: FontWeight.w700,
                    color: ItlgColors.secondary,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ItlgPrimaryButton(
            label: 'Masuk',
            trailingIcon: Icons.login_rounded,
            trailingAsset: 'assets/ic_login_enter.png',
            loading: _loading,
            onPressed: _login,
          ),
          const SizedBox(height: 18),
          Text(
            'Akun Asisten, Laboran, dan Dosen didaftarkan oleh admin '
            'laboratorium.',
            textAlign: TextAlign.center,
            style: ItlgText.style(
              size: 12,
              color: ItlgColors.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip peran (Figma "Option": tinggi 39, padding 9, radius 12, Bold 12).
/// Perpindahan status memakai 300 ms ease-out seperti Smart Animate di Figma.
class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Duration _duration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: _duration,
        curve: Curves.easeOut,
        height: 39,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? ItlgColors.primary : const Color(0xFFFEFEFE),
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? ItlgShadows.primary : ItlgShadows.outline,
        ),
        child: AnimatedDefaultTextStyle(
          duration: _duration,
          curve: Curves.easeOut,
          style: ItlgText.style(
            size: 12,
            weight: FontWeight.w700,
            color: selected ? ItlgColors.surfaceWhite : ItlgColors.text,
            height: 1.2,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool checked;
  const _Checkbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const InnerShadowBox(width: 16, height: 16, radius: 4),
        AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: checked ? 1 : 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: ItlgColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
