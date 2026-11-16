import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/constants.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../auth_controller.dart';
import '../widgets/auth_design.dart';
import 'forgot_password_page_1.dart';

/// Halaman Masuk untuk semua peran (Figma: "05 Umum — Login & Notifikasi" >
/// "Masuk-Semua Peran"). UI saja: belum terhubung ke backend.
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
  bool _remember = true;
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

  String get _identifierHint {
    switch (_role) {
      case UserRole.praktikan:
        return 'Contoh : 241402105';
      case UserRole.aslab:
        return 'Contoh : 221402004';
      case UserRole.laboran:
        return 'Contoh : 199001012019031001';
      case UserRole.dosen:
        return 'Contoh : 198501012010011001';
    }
  }

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
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);

    _auth.login(identifier: id, role: _role);
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
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
          child: const Center(child: ItlgWordmark(height: 50)),
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
          Text('Masuk Sebagai', style: ItlgText.style()),
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
            duration: const Duration(milliseconds: 200),
            child: ItlgTextField(
              key: ValueKey(_identifierLabel),
              label: _identifierLabel,
              hint: _identifierHint,
              icon: Icons.badge_outlined,
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
            hint: '••••••••••••',
            icon: Icons.lock_outline_rounded,
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
                        style: ItlgText.style(size: 12, color: Colors.black)),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openForgotPassword,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Lupa Password?',
                    style: ItlgText.style(
                      weight: FontWeight.w700,
                      color: ItlgColors.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ItlgPrimaryButton(
            label: 'Masuk',
            trailingIcon: Icons.login_rounded,
            loading: _loading,
            onPressed: _login,
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _role == UserRole.praktikan
                ? ItlgLinkRow(
                    key: const ValueKey('daftar'),
                    text: 'Belum Punya Akun?',
                    link: 'Daftar',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('Halaman daftar akun belum tersedia.'),
                        ),
                      );
                    },
                  )
                : Text(
                    'Akun Asisten, Laboran, dan Dosen didaftarkan oleh admin '
                    'laboratorium.',
                    key: const ValueKey('catatan'),
                    textAlign: TextAlign.center,
                    style: ItlgText.style(
                      size: 12,
                      color: ItlgColors.textMuted,
                      height: 1.2,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: 39,
      decoration: BoxDecoration(
        color: selected ? ItlgColors.primary : const Color(0xFFFEFEFE),
        borderRadius: BorderRadius.circular(12),
        boxShadow: selected ? ItlgShadows.primary : ItlgShadows.outline,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: ItlgText.style(
                  size: 12,
                  weight: FontWeight.w700,
                  color: selected ? ItlgColors.surfaceWhite : ItlgColors.text,
                ),
              ),
            ),
          ),
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
