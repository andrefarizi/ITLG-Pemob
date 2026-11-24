import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';

/// Komponen UI halaman autentikasi dan lupa kata sandi.

/// Nama route awal alur Lupa Password (dipakai untuk kembali ke halaman Masuk).
const String kForgotPasswordRoute = '/forgot-password';

/// Kembali ke halaman login dari alur lupa kata sandi.
void popToBeforeForgotPassword(BuildContext context) {
  var startFound = false;
  Navigator.of(context).popUntil((route) {
    if (startFound || route.isFirst) return true;
    if (route.settings.name == kForgotPasswordRoute) startFound = true;
    return false;
  });
}

/// Kerangka tata letak halaman lupa kata sandi.
class AuthScaffold extends StatelessWidget {
  final List<Widget> children;
  final bool showBack;

  const AuthScaffold({super.key, required this.children, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ItlgColors.surfaceWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showBack) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: ItlgBackButton(),
                ),
                const SizedBox(height: 16),
              ],
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Kotak ikon halaman autentikasi.
class AuthIconBadge extends StatelessWidget {
  final IconData icon;
  final double size;

  const AuthIconBadge({super.key, required this.icon, this.size = 53});

  @override
  Widget build(BuildContext context) {
    final large = size >= 70;
    return Center(
      child: InnerShadowBox(
        width: size,
        height: size,
        radius: size * 0.2476,
        shadows: large ? ItlgShadows.innerLarge : ItlgShadows.inner,
        child: Center(
          child: Icon(icon, size: size * 0.64, color: ItlgColors.primary),
        ),
      ),
    );
  }
}

/// Kartu judul Lupa Password + indikator langkah (1 Akun, 2 OTP, 3 Sandi Baru).
class ResetPasswordHeader extends StatelessWidget {
  /// Langkah aktif: 1, 2, atau 3.
  final int step;

  const ResetPasswordHeader({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return ItlgCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        children: [
          const AuthIconBadge(icon: Icons.lock_reset_rounded),
          const SizedBox(height: 8),
          Text(
            'Lupa Password?',
            textAlign: TextAlign.center,
            style: ItlgText.style(size: 22, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Silahkan Masukkan NIM dan Email USU anda\nuntuk menerima kode '
            'OTP verifikasi pemulihan kata sandi',
            textAlign: TextAlign.center,
            style: ItlgText.style(color: ItlgColors.textMuted, height: 1.3),
          ),
          const SizedBox(height: 20),
          ResetStepper(step: step),
        ],
      ),
    );
  }
}

class ResetStepper extends StatelessWidget {
  final int step;
  const ResetStepper({super.key, required this.step});

  static const _labels = ['Akun', 'OTP', 'Sandi\nBaru'];

  @override
  Widget build(BuildContext context) {
    // Progres garis merah: langkah 1 = 70/265, 2 = 207/265, 3 = penuh
    const fractions = [70 / 265, 207 / 265, 1.0];
    final index = step < 1 ? 0 : (step > 3 ? 2 : step - 1);
    final progress = fractions[index];

    return SizedBox(
      height: 68,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          const dot = 31.0;
          // Pusat lingkaran: kiri, tengah, kanan (kolom label lebar 39)
          final centers = [19.5, w / 2, w - 19.5];
          final trackLeft = centers[0] + 12;
          final trackRight = centers[2] - 12;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: trackLeft,
                right: w - trackRight,
                top: 13,
                height: 6,
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: ItlgColors.track),
                ),
              ),
              Positioned(
                left: trackLeft,
                top: 13,
                height: 6,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progress),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Container(
                    width: (trackRight - trackLeft) * v,
                    decoration: BoxDecoration(
                      color: ItlgColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < 3; i++)
                Positioned(
                  left: centers[i] - 19.5,
                  top: 0,
                  width: 39,
                  child: Column(
                    children: [
                      _StepDot(number: i + 1, active: i + 1 <= step, size: dot),
                      const SizedBox(height: 8),
                      Text(
                        _labels[i],
                        textAlign: TextAlign.center,
                        style: ItlgText.style(
                          size: 12,
                          weight: FontWeight.w700,
                          color: i + 1 <= step
                              ? Colors.black
                              : ItlgColors.textMuted,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final bool active;
  final double size;
  const _StepDot({required this.number, required this.active, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size + 1,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? ItlgColors.primary : ItlgColors.field,
        borderRadius: BorderRadius.circular(24),
        boxShadow: active
            ? const [
                ...ItlgShadows.outline,
                BoxShadow(
                    offset: Offset(0, 4),
                    blurRadius: 2.6,
                    color: Color(0x40A71111)),
              ]
            : ItlgShadows.outline,
      ),
      child: Text(
        '$number',
        style: ItlgText.style(
          size: 14,
          weight: FontWeight.w700,
          color: active ? ItlgColors.surfaceWhite : ItlgColors.textMuted,
        ),
      ),
    );
  }
}

/// Info "Ketentuan Akun Resmi" dengan ikon bulat biru.
class AuthNotice extends StatelessWidget {
  final String title;
  final String message;

  const AuthNotice({
    super.key,
    this.title = 'Ketentuan Akun Resmi:',
    this.message = 'Kode OTP 6-digit hanya dikirim ke email '
        '@students.usu.ac.id',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_rounded, size: 24, color: ItlgColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: ItlgText.style(
                        size: 12, weight: FontWeight.w700, color: Colors.black)),
                const SizedBox(height: 5),
                Text(message,
                    style: ItlgText.style(
                        size: 12, color: Colors.black, height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog Berhasil Kirim OTP.
Future<void> showAuthResultDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String buttonLabel,
  IconData? buttonIcon,
  VoidCallback? onPressed,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: title,
    barrierColor: const Color(0x66000000),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, __) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, _, __) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 370),
                child: Material(
                  color: Colors.transparent,
                  child: ItlgCard(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AuthIconBadge(icon: icon, size: 80),
                        const SizedBox(height: 8),
                        Text(title,
                            textAlign: TextAlign.center,
                            style: ItlgText.style(
                                size: 22, weight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(message,
                            textAlign: TextAlign.center,
                            style: ItlgText.style(
                                color: ItlgColors.textMuted, height: 1.3)),
                        const SizedBox(height: 13),
                        ItlgPrimaryButton(
                          label: buttonLabel,
                          trailingIcon: buttonIcon,
                          onPressed: () {
                            Navigator.of(context).pop();
                            onPressed?.call();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Kartu "Pusat Bantuan Lab" di halaman Masuk.
class HelpCenterCard extends StatelessWidget {
  const HelpCenterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ItlgCard(
      padding: const EdgeInsets.fromLTRB(19, 14, 19, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ItlgColors.field,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: ItlgShadows.outline,
                ),
                child: Image.asset('assets/ic_login_ask.png',
                    width: 21, height: 21),
              ),
              const SizedBox(width: 8),
              Text('Pusat Bantuan Lab',
                  style: ItlgText.style(
                      size: 16, weight: FontWeight.w700, height: 1.2)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lokasi Pusat Bantuan jika Terjadi Kendala :',
                    style: ItlgText.style(
                        size: 12, color: Colors.black, height: 1.2)),
                const SizedBox(height: 8),
                Text(
                  'Gedung Teknologi Informasi USU (Jl. Alumni, Medan). '
                  'Lantai 3: Sekretariat ITLG.',
                  style: ItlgText.style(
                    size: 12,
                    color: ItlgColors.textMuted,
                    fontStyle: FontStyle.italic,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Image.asset('assets/ic_login_clock.png',
                        width: 15, height: 15),
                    const SizedBox(width: 10),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Senin-Jumat '),
                          TextSpan(
                            text: '08:00-16:30 WIB',
                            style: ItlgText.style(
                                size: 12,
                                weight: FontWeight.w700,
                                color: ItlgColors.textMuted,
                                height: 1.2),
                          ),
                        ],
                      ),
                      style: ItlgText.style(
                          size: 12, color: ItlgColors.textMuted, height: 1.2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
