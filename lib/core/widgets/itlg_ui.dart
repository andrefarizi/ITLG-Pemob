import 'package:flutter/material.dart';

/// Komponen UI bersama untuk autentikasi dan notifikasi.

// Token

class ItlgColors {
  ItlgColors._();

  static const Color primary = Color(0xFF850909); // Primary/Normal
  static const Color primaryDark = Color(0xFF640707);
  static const Color secondary = Color(0xFF2369B7); // Secondary/Normal
  static const Color secondaryDarker = Color(0xFF0C2540);
  static const Color surfaceWhite = Color(0xFFFDFEFE);
  static const Color surfaceDark = Color(0xFFF5F5F5);
  static const Color field = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF0A0B0C);
  static const Color textMuted = Color(0xFF5B636B);
  static const Color textSubtle = Color(0xFF6B7280);
  static const Color border = Color(0xFFE3E6EA);
  static const Color track = Color(0xFFD9D9D9);
  static const Color error = Color(0xFFC62828);
}

class ItlgText {
  ItlgText._();

  static const String font = 'Montserrat';

  static TextStyle style({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = ItlgColors.text,
    double height = 1.25,
    FontStyle fontStyle = FontStyle.normal,
  }) =>
      TextStyle(
        fontFamily: font,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        fontStyle: fontStyle,
      );
}

class ItlgShadows {
  ItlgShadows._();

  /// Efek bayangan luar kartu dan tombol.
  static const List<BoxShadow> outline = [
    BoxShadow(offset: Offset(1, 1), blurRadius: 1.7, color: Color(0x0F000000)),
    BoxShadow(offset: Offset(4, 5), blurRadius: 4.3, color: Color(0x0D000000)),
    BoxShadow(offset: Offset(8, 12), blurRadius: 6.1, color: Color(0x08000000)),
    BoxShadow(offset: Offset(14, 21), blurRadius: 7.8, color: Color(0x03000000)),
  ];

  /// Efek bayangan tombol utama berwarna merah.
  static const List<BoxShadow> primary = [
    ...outline,
    BoxShadow(offset: Offset(0, 4), blurRadius: 2.6, color: Color(0x40850909)),
  ];

  /// Efek bayangan dalam untuk kolom input.
  static const List<BoxShadow> inner = [
    BoxShadow(offset: Offset(4, 4), blurRadius: 2.6, color: Color(0x1F000000)),
    BoxShadow(offset: Offset(0, -2), blurRadius: 2.6, color: Color(0x0D000000)),
  ];

  /// Efek bayangan dalam ukuran besar untuk kotak ikon.
  static const List<BoxShadow> innerLarge = [
    BoxShadow(offset: Offset(6, 6), blurRadius: 4.3, color: Color(0x1F000000)),
    BoxShadow(offset: Offset(0, -3), blurRadius: 4.3, color: Color(0x0D000000)),
  ];
}

// Widget pembungkus efek bayangan dalam

class InnerShadowBox extends StatelessWidget {
  final double radius;
  final Color color;
  final List<BoxShadow> shadows;
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const InnerShadowBox({
    super.key,
    required this.radius,
    this.color = ItlgColors.field,
    this.shadows = ItlgShadows.inner,
    this.child,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        foregroundPainter: _InnerShadowPainter(radius: radius, shadows: shadows),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: padding == null ? child : Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}

class _InnerShadowPainter extends CustomPainter {
  final double radius;
  final List<BoxShadow> shadows;
  const _InnerShadowPainter({required this.radius, required this.shadows});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(rrect);
    for (final s in shadows) {
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect((Offset.zero & size).inflate(s.blurRadius * 3 + 20))
        ..addRRect(rrect);
      canvas.drawPath(
        path.shift(s.offset),
        Paint()
          ..color = s.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.blurSigma),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InnerShadowPainter old) =>
      old.radius != radius || old.shadows != shadows;
}

// Kartu, tombol, input

/// Widget kartu kontainer utama.
class ItlgCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;

  const ItlgCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.color = ItlgColors.surfaceDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: ItlgShadows.outline,
      ),
      child: child,
    );
  }
}

/// Tombol navigasi kembali.
class ItlgBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const ItlgBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: ItlgShadows.outline,
      ),
      child: Material(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap ?? () => Navigator.of(context).maybePop(),
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded,
                      size: 24, color: ItlgColors.primary),
                  const SizedBox(width: 7),
                  Text(
                    'Kembali',
                    style: ItlgText.style(
                      size: 16,
                      weight: FontWeight.w700,
                      color: ItlgColors.primary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol aksi utama.
class ItlgPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  /// Path aset ikon di sebelah kanan label.
  final String? trailingAsset;
  final VoidCallback? onPressed;
  final bool loading;

  const ItlgPrimaryButton({
    super.key,
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    this.trailingAsset,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: onPressed == null ? 0.6 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: ItlgShadows.primary,
        ),
        child: Material(
          color: ItlgColors.primary,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: ItlgColors.surfaceWhite,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (leadingIcon != null) ...[
                            Icon(leadingIcon,
                                size: 22, color: ItlgColors.surfaceWhite),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            label,
                            style: ItlgText.style(
                              size: 16,
                              weight: FontWeight.w700,
                              color: ItlgColors.surfaceWhite,
                              height: 1.2,
                            ),
                          ),
                          if (trailingAsset != null) ...[
                            const SizedBox(width: 8),
                            Image.asset(trailingAsset!, width: 22, height: 22),
                          ] else if (trailingIcon != null) ...[
                            const SizedBox(width: 8),
                            Icon(trailingIcon,
                                size: 22, color: ItlgColors.surfaceWhite),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget kolom input teks beserta label.
class ItlgTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;

  /// Path aset ikon kustom pada kolom input.
  final String? iconAsset;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool obscure;

  /// Opsi tampilkan tombol visibilitas kata sandi.
  final bool showObscureToggle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const ItlgTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.iconAsset,
    this.controller,
    this.focusNode,
    this.obscure = false,
    this.showObscureToggle = true,
    this.keyboardType,
    this.textInputAction,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<ItlgTextField> createState() => _ItlgTextFieldState();
}

class _ItlgTextFieldState extends State<ItlgTextField> {
  late bool _hidden = widget.obscure;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(ItlgTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final activeBorderColor = hasError
        ? ItlgColors.error
        : (_isFocused ? ItlgColors.primary : const Color(0xFFE2E8F0));
    final activeBorderWidth = (hasError || _isFocused) ? 1.5 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: ItlgText.style(
            size: 13,
            weight: FontWeight.w600,
            color: ItlgColors.text,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white : ItlgColors.field,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: activeBorderColor,
              width: activeBorderWidth,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: (hasError ? ItlgColors.error : ItlgColors.primary)
                          .withValues(alpha: 0.15),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : (hasError
                    ? [
                        BoxShadow(
                          color: ItlgColors.error.withValues(alpha: 0.12),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: InnerShadowBox(
              radius: 11,
              color: _isFocused ? Colors.white : ItlgColors.field,
              shadows: _isFocused ? const [] : ItlgShadows.inner,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    if (widget.iconAsset != null)
                      Image.asset(widget.iconAsset!, width: 20, height: 20)
                    else
                      Icon(
                        widget.icon,
                        size: 20,
                        color: _isFocused
                            ? ItlgColors.primary
                            : ItlgColors.textMuted,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        obscureText: _hidden,
                        keyboardType: widget.keyboardType,
                        textInputAction: widget.textInputAction,
                        onChanged: widget.onChanged,
                        onSubmitted: widget.onSubmitted,
                        cursorColor: ItlgColors.primary,
                        cursorWidth: 2.0,
                        cursorRadius: const Radius.circular(2),
                        style: ItlgText.style(
                          size: 14,
                          weight: FontWeight.w500,
                          color: ItlgColors.text,
                          height: 1.3,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          hintText: widget.hint,
                          hintStyle: ItlgText.style(
                            size: 14,
                            weight: FontWeight.w400,
                            color: ItlgColors.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                    if (widget.obscure && widget.showObscureToggle)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _hidden = !_hidden),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          child: Icon(
                            _hidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: _isFocused
                                ? ItlgColors.primary
                                : ItlgColors.textMuted,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: ItlgText.style(size: 12, color: ItlgColors.error),
          ),
        ],
      ],
    );
  }
}

/// Baris teks dengan tautan aksi di sisi kanan.
class ItlgLinkRow extends StatelessWidget {
  final String text;
  final String link;
  final VoidCallback? onTap;

  const ItlgLinkRow({
    super.key,
    required this.text,
    required this.link,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(text,
              style: ItlgText.style(size: 12, color: Colors.black)),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              link,
              style: ItlgText.style(
                size: 14,
                weight: FontWeight.w700,
                color: onTap == null
                    ? ItlgColors.textMuted
                    : ItlgColors.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Komponen gambar vektor logo ITLG

/// Widget ikon logo ITLG.
class ItlgLogoMark extends StatelessWidget {
  final double size;
  final Color lightColor;
  final Color darkColor;

  const ItlgLogoMark({
    super.key,
    this.size = 29,
    this.lightColor = ItlgColors.secondary,
    this.darkColor = ItlgColors.secondaryDarker,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 58 / 64,
      child: CustomPaint(
        painter: _ItlgLogoPainter(light: lightColor, dark: darkColor),
      ),
    );
  }
}

/// Widget logo lengkap dengan nama institusi.
class ItlgWordmark extends StatelessWidget {
  final double height;
  const ItlgWordmark({super.key, this.height = 53});

  @override
  Widget build(BuildContext context) {
    final s = height / 53;
    return SizedBox(
      height: height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ITLG',
                style: ItlgText.style(
                  size: 30 * s,
                  weight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: ItlgColors.secondaryDarker,
                  height: 1.0,
                ),
              ),
              SizedBox(height: 3 * s),
              Text(
                'Information Technology\nLaboratory Group',
                style: ItlgText.style(
                  size: 5.6 * s,
                  fontStyle: FontStyle.italic,
                  color: ItlgColors.secondaryDarker,
                  height: 1.15,
                ),
              ),
            ],
          ),
          SizedBox(width: 6 * s),
          ItlgLogoMark(size: 44 * s),
        ],
      ),
    );
  }
}

class _ItlgLogoPainter extends CustomPainter {
  final Color light;
  final Color dark;
  _ItlgLogoPainter({required this.light, required this.dark});

  static final Path _light = (Path()
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
        ..close())
    ..fillType = PathFillType.evenOdd;

  static final Path _dark = (Path()
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
        ..close())
    ..fillType = PathFillType.evenOdd;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 58);
    canvas.drawPath(_light, Paint()..color = light);
    canvas.drawPath(_dark, Paint()..color = dark);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ItlgLogoPainter old) =>
      old.light != light || old.dark != dark;
}
