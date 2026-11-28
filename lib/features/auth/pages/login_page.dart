import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/constants.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../shared/profil_data.dart';
import '../auth_controller.dart';
import '../services/auth_service.dart';
import '../widgets/auth_design.dart';
import 'forgot_password_page_1.dart';

/// Halaman login untuk seluruh peran pengguna.
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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _helpCardKey = GlobalKey();

  late UserRole _role = _auth.currentRole;
  bool _remember = false;
  bool _loading = false;
  bool _helpExpanded = false;
  int _passwordFieldResetId = 0;
  String? _identifierError;
  String? _passwordError;
  String? _authError;

  @override
  void initState() {
    super.initState();
    if (_auth.rememberMe && _auth.rememberedIdentifier != null) {
      _remember = true;
      _role = _auth.rememberedRole ?? _auth.currentRole;
      _identifier.text = _auth.rememberedIdentifier!;
    }
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _scrollController.dispose();
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
          ? 'Contoh : 241402105'
          : 'Contoh : 198501012010011001';

  bool get _hasGenericAuthError =>
      _authError == AuthService.invalidLoginMessage;

  void _selectRole(UserRole role) {
    if (role == _role) return;
    FocusScope.of(context).unfocus();
    _identifier.clear();
    _password.clear();
    setState(() {
      _role = role;
      _identifierError = null;
      _passwordError = null;
      _authError = null;
      _passwordFieldResetId++;
    });
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final id = _identifier.text.trim();
    final pass = _password.text;
    setState(() {
      _authError = null;
      _identifierError = id.isEmpty ? '$_identifierLabel wajib diisi' : null;
      _passwordError = pass.isEmpty ? 'Kata sandi wajib diisi' : null;
    });
    if (_identifierError != null || _passwordError != null) return;

    setState(() => _loading = true);
    final result = await _auth.loginWithCredentials(
      identifier: id,
      password: pass,
      role: _role,
      rememberMe: _remember,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.success) {
      final msg = result.errorMessage ?? AuthService.invalidLoginMessage;
      setState(() {
        _identifierError = null;
        _passwordError = null;
        _authError = msg;
      });
      return;
    }

    ProfilData.refresh(_auth.currentRole);

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

  void _toggleHelp() {
    FocusScope.of(context).unfocus();
    final expanding = !_helpExpanded;
    setState(() => _helpExpanded = expanding);
    if (expanding) {
      Future.delayed(const Duration(milliseconds: 260), () {
        if (!mounted || !_helpExpanded) return;
        final ctx = _helpCardKey.currentContext;
        if (ctx != null && ctx.mounted) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      });
    }
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
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildIntro(),
                const SizedBox(height: 22),
                _buildForm(),
                const SizedBox(height: 22),
                _buildHelpCard(),
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
              hasErrorBorder: _hasGenericAuthError,
              onChanged: (_) {
                if (_identifierError != null || _authError != null) {
                  setState(() {
                    _identifierError = null;
                    _authError = null;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 18),
          ItlgTextField(
            key: ValueKey('password_$_passwordFieldResetId'),
            label: 'Kata Sandi',
            hint: '************',
            icon: Icons.lock_outline_rounded,
            iconAsset: 'assets/ic_login_lock.png',
            showObscureToggle: true,
            controller: _password,
            obscure: true,
            textInputAction: TextInputAction.done,
            errorText: _passwordError,
            hasErrorBorder: _hasGenericAuthError,
            onChanged: (_) {
              if (_passwordError != null || _authError != null) {
                setState(() {
                  _passwordError = null;
                  _authError = null;
                });
              }
            },
            onSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _remember = !_remember),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Checkbox(checked: _remember),
                    const SizedBox(width: 8),
                    Text('Ingat Saya',
                        style: ItlgText.style(
                            size: 12, color: Colors.black, height: 1.2)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openForgotPassword,
                  child: Text(
                    'Lupa Kata Sandi?',
                    textAlign: TextAlign.end,
                    style: ItlgText.style(
                      weight: FontWeight.w700,
                      color: ItlgColors.primary,
                      height: 1.2,
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
            trailingAsset: 'assets/ic_login_enter.png',
            loading: _loading,
            onPressed: _login,
          ),
          if (_authError != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: ItlgColors.error,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _authError!,
                    textAlign: TextAlign.center,
                    style: ItlgText.style(
                      size: 12,
                      weight: FontWeight.w500,
                      color: ItlgColors.error,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return DecoratedBox(
      key: _helpCardKey,
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        boxShadow: ItlgShadows.outline,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _toggleHelp,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    const Icon(
                      Icons.help_outline_rounded,
                      size: 19,
                      color: ItlgColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Butuh bantuan? '),
                            TextSpan(
                              text: 'Info Sekretariat',
                              style: ItlgText.style(
                                size: 13,
                                weight: FontWeight.w700,
                                color: ItlgColors.primary,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ItlgText.style(
                          size: 13,
                          weight: FontWeight.w500,
                          color: ItlgColors.textMuted,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _helpExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 22,
                        color: ItlgColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(height: 1, thickness: 1, color: ItlgColors.border),
                    SizedBox(height: 14),
                    _HelpInfoItem(
                      icon: Icons.location_on_outlined,
                      title: 'Lokasi',
                      body:
                          'Gedung Teknologi Informasi USU (Jl. Alumni, Medan). '
                          'Lantai 3: Sekretariat ITLG.',
                    ),
                    SizedBox(height: 12),
                    Divider(height: 1, thickness: 1, color: ItlgColors.border),
                    SizedBox(height: 12),
                    _HelpInfoItem(
                      icon: Icons.schedule_rounded,
                      title: 'Jam Operasional',
                      body: 'Senin–Jumat, 08:00–16:30 WIB',
                    ),
                    SizedBox(height: 12),
                    Divider(height: 1, thickness: 1, color: ItlgColors.border),
                    SizedBox(height: 12),
                    _HelpInfoItem(
                      icon: Icons.badge_outlined,
                      title: 'Info Pendaftaran Akun',
                      body:
                          'Akun Asisten, Laboran, dan Dosen didaftarkan oleh '
                          'admin laboratorium.',
                    ),
                  ],
                ),
              ),
              crossFadeState: _helpExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
              sizeCurve: Curves.easeOutCubic,
              firstCurve: Curves.easeOut,
              secondCurve: Curves.easeOut,
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip peran.
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

class _HelpInfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _HelpInfoItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ItlgColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: ItlgColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ItlgText.style(
                  size: 12,
                  weight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: ItlgText.style(
                  size: 12.5,
                  color: ItlgColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
