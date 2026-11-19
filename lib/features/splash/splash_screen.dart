import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


/// Splash Screen ITLG Mobile (UI + animasi saja, belum ada backend).
///
/// Mengikuti prototype Figma "Splash Screen" (5 frame, 402 x 874):
///   S1  latar maroon, logo kecil (13x12), opacity 0, rotasi 180°
///   S2  logo membesar ke 64x58 di tengah (ease-out 800ms, setelah 0.8s)
///   S3  logo bergeser ke kiri, teks "ITLG" muncul dari bawah (ease-out 800ms)
///   S4  latar berubah putih, logo & teks berubah biru (ease-out 800ms)
///   S5  setelah 0.5s, logo + teks mengecil naik ke atas dan konten
///       sambutan (ilustrasi, judul, subjudul, tombol Mulai) naik dari
///       bawah (ease-out 800ms)
///
/// Semua posisi memakai koordinat frame Figma (402 x 874) lalu diskalakan
/// ke layar dengan [FittedBox], jadi hasilnya sama persis dengan prototype.
class SplashScreen extends StatefulWidget {
  /// Dipanggil saat tombol "Mulai" ditekan. Peran dipilih di halaman Masuk.
  final VoidCallback? onStart;

  const SplashScreen({super.key, this.onStart});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // ---- Warna dari Design System ----
  static const Color _primary = Color(0xFF850909); // Primary/Normal
  static const Color _secondary = Color(0xFF2369B7); // Secondary/Normal
  static const Color _secondaryDarker = Color(0xFF0C2540); // Secondary/Darker
  static const Color _surfaceWhite = Color(0xFFFDFEFE);
  static const Color _textDark = Color(0xFF0A0B0C);

  static const String _font = 'Montserrat';

  // ---- Ukuran frame Figma ----
  static const double _frameW = 402;
  static const double _frameH = 874;

  // ---- Timeline (ms) ----
  // Disamakan dengan pemutaran prototype Figma:
  //   S1 maroon diam 0.8s -> logo membesar 0.8s -> logo geser + teks naik
  //   0.8s -> latar jadi putih 0.8s -> diam 0.5s -> konten sambutan naik 0.8s
  // Semua transisi Smart Animate "Ease out".
  static const int _startDelayMs = 300; // jeda setelah frame pertama tampil
  static const int _holdMs = 800; // S1 diam (After delay 0.8s)
  static const int _transitionMs = 800; // durasi tiap Smart Animate
  static const int _pauseBeforeWelcomeMs = 500; // S4 diam (After delay 0.5s)

  static const int _growStart = _holdMs;
  static const int _revealStart = _growStart + _transitionMs;
  static const int _recolorStart = _revealStart + _transitionMs;
  static const int _settleStart =
      _recolorStart + _transitionMs + _pauseBeforeWelcomeMs;
  static const int _totalMs = _settleStart + _transitionMs;

  late final AnimationController _controller;
  late final Animation<double> _grow; // S1 -> S2
  late final Animation<double> _reveal; // S2 -> S3
  late final Animation<double> _recolor; // S3 -> S4
  late final Animation<double> _settle; // S4 -> S5

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );
    _grow = _phase(_growStart, _growStart + _transitionMs);
    _reveal = _phase(_revealStart, _revealStart + _transitionMs);
    _recolor = _phase(_recolorStart, _recolorStart + _transitionMs);
    _settle = _phase(_settleStart, _totalMs);

    // Mulai animasi SETELAH frame pertama benar-benar tampil di layar,
    // supaya waktu loading Flutter tidak "memakan" bagian awal animasi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: _startDelayMs), () {
        if (mounted) _controller.forward();
      });
    });
  }

  /// Prototype memakai Smart Animate "Ease out" di setiap transisi.
  Animation<double> _phase(int startMs, int endMs) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(
        startMs / _totalMs,
        endMs / _totalMs,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() => widget.onStart?.call();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double recolor = _recolor.value;
        final Color background =
            Color.lerp(_primary, _surfaceWhite, recolor)!;
        final bool isLight = recolor > 0.5;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isLight
              ? SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent)
              : SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent),
          child: Scaffold(
            backgroundColor: background,
            body: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.contain,
                child: ClipRect(
                  child: SizedBox(
                    width: _frameW,
                    height: _frameH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildLogo(),
                        _buildWordmark(),
                        _buildWelcomeContent(),
                      ],
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

  // ---------------------------------------------------------------------------
  // Logo
  // ---------------------------------------------------------------------------

  Widget _buildLogo() {
    // Kotak logo di tiap frame (x, y, w, h) sesuai Figma
    const Rect s1 = Rect.fromLTWH(207, 443, 13, 12);
    const Rect s2 = Rect.fromLTWH(169, 408, 64, 58);
    const Rect s3 = Rect.fromLTWH(108, 412, 64, 58);
    const Rect s5 = Rect.fromLTWH(121, 97, 56, 50);

    Rect rect = Rect.lerp(s1, s2, _grow.value)!;
    rect = Rect.lerp(rect, s3, _reveal.value)!;
    rect = Rect.lerp(rect, s5, _settle.value)!;

    final double rotation = (1 - _grow.value) * 3.141592653589793; // 180° -> 0°
    // Seperti di Figma: logo memudar masuk bersamaan dengan membesar.
    final double opacity = _grow.value.clamp(0.0, 1.0);

    final Color lightColor =
        Color.lerp(Colors.white, _secondary, _recolor.value)!;
    final Color darkColor =
        Color.lerp(const Color(0xFFD3DBE2), _secondaryDarker, _recolor.value)!;

    return Positioned.fromRect(
      rect: rect,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: rotation,
          child: CustomPaint(
            painter: _ItlgLogoPainter(
              lightColor: lightColor,
              darkColor: darkColor,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Teks "ITLG / Information Technology Laboratory Group"
  // ---------------------------------------------------------------------------

  Widget _buildWordmark() {
    // Selama logo belum selesai membesar, teks sama sekali tidak digambar.
    if (_reveal.value <= 0) return const SizedBox.shrink();

    // Frame teks (clip) di S2-S4 dan S5
    const Rect frame = Rect.fromLTWH(185, 402, 108, 70);
    const Rect frameS5 = Rect.fromLTWH(188, 88, 94, 61);
    // FittedBox di bawah menskalakan isi 108x70 mengikuti ukuran rect.
    final Rect rect = Rect.lerp(frame, frameS5, _settle.value)!;

    // Teks naik dari y=61 (tersembunyi di bawah area clip) ke y=0
    // Sebelum muncul, teks diletakkan penuh di bawah area clip (70px) supaya
    // tidak ada potongan huruf yang mengintip di bawah logo.
    final double textOffset = 72 * (1 - _reveal.value);

    final Color titleColor =
        Color.lerp(Colors.white, _secondaryDarker, _recolor.value)!;
    final Color subtitleColor =
        Color.lerp(const Color(0xFFFBFBFB), _secondary, _recolor.value)!;

    return Positioned.fromRect(
      rect: rect,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.fill,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: frame.width,
            height: frame.height,
            child: Transform.translate(
              offset: Offset(0, textOffset),
              child: Opacity(
                opacity: _reveal.value > 0 ? 1.0 : 0.0,
                child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Text(
                      'ITLG',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 44.597,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        height: 1.0,
                        color: titleColor,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 50,
                    child: Text(
                      'Information Technology\nLaboratory Group',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 8.362,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        height: 1.2,
                        color: subtitleColor,
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Konten sambutan (S5)
  // ---------------------------------------------------------------------------

  Widget _buildWelcomeContent() {
    // Frame 40: dari y=874 (di luar layar) ke (15, 246), ukuran 370 x 531
    final double left = 16 + (15 - 16) * _settle.value;
    final double top = 874 + (246 - 874) * _settle.value;
    final bool interactive = _controller.value >= 1.0;

    return Positioned(
      left: left,
      top: top,
      width: 370,
      height: 531,
      child: IgnorePointer(
        ignoring: !interactive,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Ilustrasi
            const Positioned(
              left: 19,
              top: 0,
              width: 333,
              height: 251,
              child: _IllustrationCard(),
            ),
            // Judul
            Positioned(
              left: 18,
              top: 306,
              width: 334,
              child: Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'Selamat Datang \ndi '),
                    TextSpan(
                      text: 'ITLG MOBILE',
                      style: TextStyle(color: _primary),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: Colors.black,
                ),
              ),
            ),
            // Subjudul
            const Positioned(
              left: 18,
              top: 386,
              width: 334,
              child: Text(
                'Mulailah Pengalaman Praktikum yang Lebih\n'
                'Mudah dan Menyenangkan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                  color: _textDark,
                ),
              ),
            ),
            // Tombol Mulai
            Positioned(
              left: 0,
              top: 475,
              width: 370,
              height: 56,
              child: _StartButton(
                label: 'Mulai',
                backgroundColor: _primary,
                textColor: _surfaceWhite,
                glowColor: _primary,
                onTap: _start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Kartu ilustrasi (Surface/Dark + inner shadow, radius 21.59)
// -----------------------------------------------------------------------------

class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard();

  static const double _radius = 21.59;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: _SplashColors.surfaceDark),
          // Ilustrasi kartu (sudah termasuk inner shadow dari Figma)
          Image.asset(
            'assets/splash_illustration.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => const Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Icon(
                    Icons.science_outlined,
                    size: 72,
                    color: Color(0xFFB8C2CC),
                  ),
                ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: _InnerShadowPainter(
                      radius: _radius,
                      shadows: [
                        BoxShadow(
                          offset: Offset(4, 4),
                          blurRadius: 4,
                          color: Color(0x1F000000), // #000 12%
                        ),
                        BoxShadow(
                          offset: Offset(0, -2),
                          blurRadius: 4,
                          color: Color(0x0D000000), // #000 5%
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashColors {
  static const Color surfaceDark = Color(0xFFF5F5F5);
}

class _InnerShadowPainter extends CustomPainter {
  final double radius;
  final List<BoxShadow> shadows;

  const _InnerShadowPainter({required this.radius, required this.shadows});

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    for (final BoxShadow shadow in shadows) {
      final Paint paint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurSigma);
      // Bingkai tebal di luar kartu yang digeser -> bayangan jatuh ke dalam
      final Path frame = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect((Offset.zero & size).inflate(shadow.blurRadius * 4 + 20))
        ..addRRect(rrect);
      canvas.drawPath(frame.shift(shadow.offset), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InnerShadowPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.shadows != shadows;
}

// -----------------------------------------------------------------------------
// Tombol Mulai (370 x 56, radius 12, bayangan dari Design System)
// -----------------------------------------------------------------------------

class _StartButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color glowColor;
  final VoidCallback onTap;

  const _StartButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(12);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          const BoxShadow(
              offset: Offset(1, 1), blurRadius: 3, color: Color(0x0F000000)),
          const BoxShadow(
              offset: Offset(4, 5), blurRadius: 6, color: Color(0x0D000000)),
          const BoxShadow(
              offset: Offset(8, 12), blurRadius: 8, color: Color(0x08000000)),
          const BoxShadow(
              offset: Offset(14, 21), blurRadius: 10, color: Color(0x03000000)),
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 4,
            color: glowColor.withValues(alpha: 0.25),
          ),
        ],
      ),
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Logo ITLG (digambar ulang dari vektor Figma, viewBox 64 x 58)
// -----------------------------------------------------------------------------

class _ItlgLogoPainter extends CustomPainter {
  final Color lightColor;
  final Color darkColor;

  _ItlgLogoPainter({required this.lightColor, required this.darkColor});

  static final Path _light = _lightPath();
  static final Path _dark = _darkPath();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 58);
    canvas.drawPath(_light, Paint()..color = lightColor);
    canvas.drawPath(_dark, Paint()..color = darkColor);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ItlgLogoPainter oldDelegate) =>
      oldDelegate.lightColor != lightColor ||
      oldDelegate.darkColor != darkColor;

  static Path _lightPath() {
    final p = Path()
      ..moveTo(43.2288, 0.279)
      ..lineTo(40.4639, 0.3616)
      ..lineTo(36.8235, 7.8285)
      ..cubicTo(34.3087, 12.9871, 33.183, 15.5525, 33.183, 16.1264)
      ..cubicTo(33.183, 16.926, 38.0411, 27.9814, 38.6526, 28.5736)
      ..cubicTo(38.8341, 28.7492, 42.8264, 28.7876, 51.3356, 28.6957)
      ..cubicTo(62.0927, 28.5795, 63.7854, 28.5118, 63.9882, 28.1896)
      ..cubicTo(64.1641, 27.9098, 62.4048, 24.4003, 56.8847, 14.0203)
      ..lineTo(49.5475, 0.2231)
      ..lineTo(47.7706, 0.2096)
      ..cubicTo(46.7933, 0.2023, 44.7495, 0.2333, 43.2288, 0.279)
      ..close()
      ..moveTo(6.8907, 30.5768)
      ..cubicTo(1.6205, 30.6296, -0.002, 30.7168, 0, 30.9474)
      ..cubicTo(0.002, 31.1834, 7.6535, 43.7425, 15.4763, 56.3505)
      ..lineTo(16.3479, 57.7552)
      ..lineTo(18.7514, 57.7552)
      ..cubicTo(20.0732, 57.7552, 21.8101, 57.6866, 22.6109, 57.6028)
      ..lineTo(24.0672, 57.4504)
      ..lineTo(30.7759, 43.4103)
      ..lineTo(27.6586, 37.1624)
      ..cubicTo(25.38, 32.5962, 24.3874, 30.8446, 23.9703, 30.6543)
      ..cubicTo(23.6133, 30.4913, 21.5993, 30.4154, 18.5918, 30.451)
      ..cubicTo(15.9474, 30.4823, 10.6819, 30.539, 6.8907, 30.5768)
      ..close();
    p.fillType = PathFillType.evenOdd;
    return p;
  }

  static Path _darkPath() {
    final p = Path()
      ..moveTo(15.6793, 0.3054)
      ..cubicTo(15.0917, 1.0485, 0, 27.624, 0, 27.9155)
      ..cubicTo(0, 28.8023, 0.3367, 28.8272, 12.1884, 28.8218)
      ..cubicTo(22.9931, 28.8169, 23.8603, 28.7849, 24.7956, 28.3598)
      ..cubicTo(25.348, 28.1087, 26.0715, 27.5339, 26.4036, 27.0826)
      ..cubicTo(26.7355, 26.6312, 29.4504, 20.5134, 32.4364, 13.4877)
      ..cubicTo(36.8501, 3.1021, 37.81, 0.6464, 37.5697, 0.3567)
      ..cubicTo(37.3188, 0.054, 35.659, 0, 26.5974, 0)
      ..cubicTo(18.3473, 0, 15.8657, 0.0694, 15.6793, 0.3054)
      ..close()
      ..moveTo(40.8253, 30.5397)
      ..cubicTo(40.5312, 30.6582, 40.1284, 31.0085, 39.9302, 31.318)
      ..cubicTo(39.7318, 31.6276, 36.914, 37.5943, 33.6679, 44.5773)
      ..cubicTo(29.2652, 54.0487, 27.8257, 57.3687, 28.0014, 57.6472)
      ..cubicTo(28.2069, 57.9733, 29.6405, 58.0207, 39.3126, 58.0207)
      ..lineTo(50.3886, 58.0207)
      ..lineTo(57.3027, 44.512)
      ..cubicTo(62.9396, 33.4984, 64.1622, 30.9379, 63.922, 30.6482)
      ..cubicTo(63.6719, 30.3465, 61.9507, 30.2954, 52.494, 30.3084)
      ..cubicTo(46.3702, 30.3169, 41.1196, 30.421, 40.8253, 30.5397)
      ..close();
    p.fillType = PathFillType.evenOdd;
    return p;
  }
}
