import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';

/// Komponen khusus halaman Praktikan (Figma: section "01 Praktikan").
/// Komponen umum (kartu, chip, tombol, navbar) ada di
/// lib/features/laboran/widgets/laboran_ui.dart.

// =============================================================================
// Token
// =============================================================================

class PrakColors {
  PrakColors._();

  static const Color ink = Color(0xFF202124);
  static const Color ink2 = Color(0xFF17191B);
  static const Color faded = Color(0xFFA6ABAF);
  static const Color linkBlue = Color(0xFF1C5492);
  static const Color mutedRed = Color(0xFF2F0303);
  static const Color camera = Color(0xFF202325);
  static const Color line = Color(0xFFE3E6EA);
}

class PrakShadows {
  PrakShadows._();

  /// "Neu" yang lebih kecil (tombol hari, pill minggu, tombol filter).
  static const List<BoxShadow> neu5 = [
    BoxShadow(offset: Offset(5, 5), blurRadius: 12, color: Color(0x73A3B1C6)),
    BoxShadow(offset: Offset(-5, -5), blurRadius: 10, color: Color(0xE6FFFFFF)),
  ];

  /// Kotak ikon 36 px di kartu jadwal & Detail Praktikum.
  static const List<BoxShadow> tile = [
    BoxShadow(
        offset: Offset(5.7, 5.7), blurRadius: 13.7, color: Color(0x73A3B1C6)),
    BoxShadow(
        offset: Offset(-5.7, -5.7), blurRadius: 11.4, color: Color(0xE6FFFFFF)),
  ];

  /// Outline Shadow yang diperkecil (kotak ikon 34 px di Detail Praktikum).
  static const List<BoxShadow> outlineSmall = [
    BoxShadow(
        offset: Offset(1.3, 1.3), blurRadius: 3.9, color: Color(0x0F000000)),
    BoxShadow(
        offset: Offset(5.2, 6.5), blurRadius: 7.8, color: Color(0x0D000000)),
    BoxShadow(
        offset: Offset(10.5, 15.7), blurRadius: 10.5, color: Color(0x08000000)),
    BoxShadow(
        offset: Offset(18.3, 27.5), blurRadius: 13.1, color: Color(0x03000000)),
  ];

  /// Tombol hari terpilih: 0,4 blur 10, merah 30%.
  static const List<BoxShadow> daySelected = [
    BoxShadow(offset: Offset(0, 4), blurRadius: 10, color: Color(0x4D850909)),
  ];
}

// =============================================================================
// Kerangka
// =============================================================================

/// Isi halaman tab Praktikan: konten mulai 20 px di bawah header.
class PrakTabBody extends StatelessWidget {
  final List<Widget> children;
  final double left;
  final double top;
  final double gap;

  const PrakTabBody({
    super.key,
    required this.children,
    this.left = 16,
    this.top = 20,
    this.gap = kLabSectionGap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding:
          EdgeInsets.fromLTRB(left, labTopBarHeight(context) + top, 16, 40),
      child: LabColumn(gap: gap, children: children),
    );
  }
}

/// Teks tautan merah di tengah (Bold 12).
class PrakLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const PrakLink(this.text, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(text,
          textAlign: TextAlign.center,
          style: labText(12, w: kBold, c: ItlgColors.primary)),
    );
  }
}

/// "Lihat Semua", "2 Praktikum", dll. (Regular 12 merah).
class PrakSideLink extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const PrakSideLink(this.text, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Text(text, style: labText(12, c: ItlgColors.primary));
    if (onTap == null) return t;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: t),
    );
  }
}

/// Baris dua ujung (judul kiri, tautan/tag kanan).
class PrakSpaceRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  const PrakSpaceRow({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: left),
        const SizedBox(width: 8),
        right,
      ],
    );
  }
}

/// Garis pemisah 1 px (#B5B9BC, 40%).
class PrakDivider extends StatelessWidget {
  const PrakDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: const Color(0x66B5B9BC));
  }
}

// =============================================================================
// Elemen kecil
// =============================================================================

/// Kotak angka merah 36 px (nomor pertemuan / soal).
class PrakNumberTile extends StatelessWidget {
  final String number;
  const PrakNumberTile(this.number, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ItlgColors.primary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(number, style: labText(16, w: kBold, c: Colors.white)),
    );
  }
}

/// Kotak buku 36 px (#EEF0F3) dengan ikon basil:book-solid merah tua.
class PrakBookTile extends StatelessWidget {
  final Color color;
  final Widget? child;
  const PrakBookTile({super.key, this.color = LabColors.tile, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36.5,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9.1),
      ),
      child: child ??
          const LabIcon('book_solid', size: 27.4, color: ItlgColors.primaryDark),
    );
  }
}

/// Kotak ikon 34 px (#F5F5F5, datar) untuk berkas & kuis.
class PrakFileIcon extends StatelessWidget {
  final String icon;
  final Color color;
  final double iconSize;
  final double radius;
  final List<BoxShadow> shadows;

  const PrakFileIcon({
    super.key,
    this.icon = 'outline_assignment',
    this.color = ItlgColors.primary,
    this.iconSize = 18,
    this.radius = 9,
    this.shadows = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows,
      ),
      child: LabIcon(icon, size: iconSize, color: color),
    );
  }
}

/// Tag 17 px (padding 2/8) yang dipakai di Detail Praktikum & Daftar.
class PrakTag17 extends StatelessWidget {
  final String text;
  final bool red;
  const PrakTag17(this.text, {super.key, this.red = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 17,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: red ? LabColors.tagRedBg : LabColors.tagBlueBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(text,
            style: labText(10,
                w: kSemiBold,
                c: red ? ItlgColors.primary : ItlgColors.secondary)),
      ),
    );
  }
}

/// Chip hijau 24 px "Presensi Berlangsung" di Beranda (padding 10, jarak 10).
class PrakLiveChip24 extends StatelessWidget {
  final String text;
  const PrakLiveChip24(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: LabColors.greenBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LabRingDot(color: LabColors.green),
          const SizedBox(width: 10),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labText(12, w: kBold, c: LabColors.green)),
          ),
        ],
      ),
    );
  }
}

/// Chip kecil 19 px (padding 3/10, SemiBold 11): kuning lembut untuk yang
/// belum selesai, hijau muda untuk yang sudah selesai.
class PrakSoftChip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const PrakSoftChip(this.text,
      {super.key, required this.bg, required this.fg});

  const PrakSoftChip.warn(this.text, {super.key})
      : bg = LabColors.warnSoftBg,
        fg = LabColors.warnText;

  const PrakSoftChip.done(this.text, {super.key})
      : bg = LabColors.greenBg,
        fg = LabColors.green;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 19,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(text,
            maxLines: 1,
            softWrap: false,
            style: labText(11, w: kSemiBold, c: fg)),
      ),
    );
  }
}

/// Chip kuning lebar tetap 172 px ("Belum Dikumpulkan").
class PrakWarnChipWide extends StatelessWidget {
  final String text;
  final bool italic;
  const PrakWarnChipWide(this.text, {super.key, this.italic = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 172,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: LabColors.warnBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        style: labText(12, w: kSemiBold, c: LabColors.warnText).copyWith(
            fontStyle: italic ? FontStyle.italic : FontStyle.normal),
      ),
    );
  }
}

/// Pill abu-abu datar untuk timer kuis (ikon & teks merah).
class PrakTimerPill extends StatelessWidget {
  final String text;
  const PrakTimerPill(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LabIcon('clock', size: 12, color: ItlgColors.primary),
          const SizedBox(width: 4),
          Text(text, style: labText(12, w: kBold, c: ItlgColors.primary)),
        ],
      ),
    );
  }
}

/// Ikon kecil + teks Regular 12 abu-abu (meta di Beranda, tinggi 18).
class PrakMetaR12 extends StatelessWidget {
  final String icon;
  final double iconWidth;
  final double iconHeight;
  final String text;

  /// Nama tebal setelah [text] ("Asisten: " + "Andi Pratama").
  final String? bold;

  const PrakMetaR12({
    super.key,
    required this.icon,
    required this.text,
    this.iconWidth = 13.3,
    this.iconHeight = 13.3,
    this.bold,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: iconWidth,
            height: iconHeight,
            child: LabIcon(icon,
                size: iconWidth > iconHeight ? iconWidth : iconHeight,
                color: ItlgColors.textSubtle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: text),
                  if (bold != null)
                    TextSpan(
                      text: bold,
                      style: labText(12, w: kBold, c: PrakColors.ink),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labText(12, c: ItlgColors.textSubtle)
                  .copyWith(height: bold == null ? 1.5 : 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Jadwal, ruangan, dan asisten (Beranda: jarak antar-baris 8, antar-item 34).
class PrakScheduleMeta extends StatelessWidget {
  final String jadwal;
  final String room;
  final String asisten;
  const PrakScheduleMeta({
    super.key,
    required this.jadwal,
    required this.room,
    required this.asisten,
  });

  @override
  Widget build(BuildContext context) {
    return LabColumn(
      gap: 8,
      cross: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: PrakMetaR12(icon: 'm_clock13', text: jadwal),
            ),
            const SizedBox(width: 34),
            Flexible(
              child: PrakMetaR12(
                icon: 'm_location',
                iconWidth: 10.7,
                iconHeight: 13.3,
                text: room,
              ),
            ),
          ],
        ),
        PrakMetaR12(icon: 'm_badge', text: 'Asisten: ', bold: asisten),
      ],
    );
  }
}

/// Jadwal, ruangan, dan asisten sesi presensi (Medium 11).
class PrakSessionMeta extends StatelessWidget {
  const PrakSessionMeta({super.key});

  @override
  Widget build(BuildContext context) {
    return const LabColumn(
      gap: 8,
      cross: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: LabMeta(icon: 'clock', text: 'Senin • 08:00–09:40 WIB'),
            ),
            SizedBox(width: 24),
            Flexible(
              child: LabMeta(icon: 'location', text: 'Lab Komputer 1'),
            ),
          ],
        ),
        LabMeta(icon: 'person', text: 'Asisten: Andi Pratama'),
      ],
    );
  }
}

/// Batang progress 6 px tanpa label.
class PrakTrack extends StatelessWidget {
  final double fraction;
  final Color color;
  const PrakTrack({super.key, required this.fraction, required this.color});

  @override
  Widget build(BuildContext context) {
    return InnerShadowBox(
      radius: 3,
      height: 6,
      color: LabColors.tile,
      shadows: LabShadows.track,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0.0, 1.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

/// Nilai besar: angka Bold 34 merah + "/ 100" Bold 16, rata bawah.
class PrakBigScore extends StatelessWidget {
  final String score;
  const PrakBigScore(this.score, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(score, style: labText(34, w: kBold, c: ItlgColors.primary)),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('/ 100',
              style: labText(16, w: kBold, c: ItlgColors.textSubtle)),
        ),
      ],
    );
  }
}

/// Kotak ikon cekung 80 px (#F9FAFB, radius 20) dengan ikon 38 px.
class PrakIconWell extends StatelessWidget {
  final String icon;
  final Color color;
  const PrakIconWell(this.icon, {super.key, this.color = ItlgColors.primary});

  @override
  Widget build(BuildContext context) {
    return InnerShadowBox(
      width: 80,
      height: 80,
      radius: 20,
      child: Center(child: LabIcon(icon, size: 38, color: color)),
    );
  }
}

/// Kotak pemberitahuan berwarna dengan ikon 18 px.
class PrakNotice extends StatelessWidget {
  final String icon;
  final String text;
  final Color bg;
  final Color fg;
  final Color iconColor;

  const PrakNotice({
    super.key,
    required this.icon,
    required this.text,
    required this.bg,
    required this.fg,
    required this.iconColor,
  });

  /// Biru muda (informasi).
  const PrakNotice.info({super.key, required this.icon, required this.text})
      : bg = LabColors.tagBlueBg,
        fg = LabColors.blueDark,
        iconColor = ItlgColors.secondary;

  /// Kuning (peringatan ringan).
  const PrakNotice.warn({super.key, required this.icon, required this.text})
      : bg = LabColors.warnBg,
        fg = LabColors.warnText,
        iconColor = LabColors.warnText;

  /// Merah muda (di luar area).
  const PrakNotice.danger({super.key, required this.icon, required this.text})
      : bg = LabColors.tagRedBg,
        fg = ItlgColors.primary,
        iconColor = ItlgColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          LabIcon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: labText(12, c: fg))),
        ],
      ),
    );
  }
}

/// Tombol nonaktif abu-abu 50 px (#B5B9BC) dengan ikon gembok.
class PrakDisabledButton extends StatelessWidget {
  final String label;
  const PrakDisabledButton(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: LabColors.divider,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LabIcon('lock_on', size: 22, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: labText(16, w: kBold, c: Colors.white)),
        ],
      ),
    );
  }
}

/// Tombol merah dengan ikon di kanan teks ("Selanjutnya →", "Kerjakan Kuis →").
class PrakTrailingButton extends StatelessWidget {
  final String label;
  final String icon;
  final bool large;
  final VoidCallback onTap;

  const PrakTrailingButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: large ? 50 : 41,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: ItlgColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ItlgShadows.primary,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labText(large ? 16 : 12,
                    w: kBold, c: ItlgColors.surfaceWhite),
              ),
            ),
            const SizedBox(width: 8),
            LabIcon(icon,
                size: large ? 22 : 16, color: ItlgColors.surfaceWhite),
          ],
        ),
      ),
    );
  }
}

/// Tombol merah tanpa ikon dan tanpa cahaya ("Kumpulkan Tugas").
class PrakPlainButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const PrakPlainButton(this.label, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 41,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ItlgColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ItlgShadows.outline,
        ),
        child: Text(label,
            style: labText(12, w: kBold, c: ItlgColors.surfaceWhite)),
      ),
    );
  }
}

// =============================================================================
// Formulir
// =============================================================================

/// Label Regular 14 + isi, jarak 8.
class PrakField extends StatelessWidget {
  final String label;
  final Widget child;
  const PrakField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return LabColumn(
      gap: 8,
      children: [Text(label, style: labText(14)), child],
    );
  }
}

/// Kolom isian 48 px (#F9FAFB, inner shadow).
class PrakInput extends StatefulWidget {
  final TextEditingController controller;
  final String? leadingIcon;
  final Color textColor;
  final String hint;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool obscure;
  final bool showObscureToggle;

  const PrakInput({
    super.key,
    required this.controller,
    this.leadingIcon,
    this.textColor = ItlgColors.text,
    this.hint = '',
    this.focusNode,
    this.keyboardType,
    this.obscure = false,
    this.showObscureToggle = true,
  });

  @override
  State<PrakInput> createState() => _PrakInputState();
}

class _PrakInputState extends State<PrakInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  late bool _hidden = widget.obscure;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(PrakInput oldWidget) {
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 48,
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : ItlgColors.field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused ? ItlgColors.primary : const Color(0xFFE2E8F0),
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: ItlgColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
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
                if (widget.leadingIcon != null) ...[
                  LabIcon(
                    widget.leadingIcon!,
                    size: 18,
                    color: _isFocused
                        ? ItlgColors.primary
                        : ItlgColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    obscureText: _hidden,
                    keyboardType: widget.keyboardType,
                    cursorColor: ItlgColors.primary,
                    cursorWidth: 2.0,
                    cursorRadius: const Radius.circular(2),
                    style: labText(14, c: widget.textColor),
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
                      hintStyle: labText(14, c: ItlgColors.textSubtle),
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
    );
  }
}

/// Kolom pilihan 48 px dengan chevron ke bawah.
class PrakSelect extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  const PrakSelect({super.key, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: InnerShadowBox(
        radius: 12,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: Text(value, style: labText(12))),
            const SizedBox(width: 8),
            const LabIcon('chevron_down',
                size: 16, color: ItlgColors.textSubtle),
          ],
        ),
      ),
    );
  }
}

/// Area teks (#F9FAFB, inner shadow). Nonaktif = tidak bisa diketik.
class PrakTextArea extends StatefulWidget {
  final TextEditingController? controller;
  final String hint;
  final double height;
  final bool enabled;
  final FocusNode? focusNode;

  const PrakTextArea({
    super.key,
    this.controller,
    this.hint = '',
    this.height = 110,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<PrakTextArea> createState() => _PrakTextAreaState();
}

class _PrakTextAreaState extends State<PrakTextArea> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(PrakTextArea oldWidget) {
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: widget.height,
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : ItlgColors.field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused ? ItlgColors.primary : const Color(0xFFE2E8F0),
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: ItlgColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: InnerShadowBox(
          radius: 11,
          height: widget.height,
          color: _isFocused ? Colors.white : ItlgColors.field,
          shadows: _isFocused ? const [] : ItlgShadows.inner,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            cursorColor: ItlgColors.primary,
            cursorWidth: 2.0,
            cursorRadius: const Radius.circular(2),
            style: labText(14),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintText: widget.hint,
              hintStyle: labText(14, c: ItlgColors.textSubtle),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kotak unggah (putih cekung): ikon awan 36 px di kotak 60 px, atau ikon
/// kamera di kotak 36 px ([camera] = true).
class PrakUploadBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool camera;
  final VoidCallback onTap;

  const PrakUploadBox({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.camera = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: InnerShadowBox(
        radius: 12,
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (camera)
              const LabIconTile('camera')
            else
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ItlgColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: ItlgShadows.outline,
                ),
                child: const LabIcon('cloud_upload_outlined',
                    size: 36, color: ItlgColors.primary),
              ),
            const SizedBox(height: 7),
            Text(title,
                textAlign: TextAlign.center, style: labText(12, w: kBold)),
            const SizedBox(height: 7),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
          ],
        ),
      ),
    );
  }
}

/// Baris berkas putih 56 px: ikon tugas, nama Bold 12, keterangan, aksi 18 px.
class PrakFileItem extends StatelessWidget {
  final String name;
  final String meta;
  final String action;
  final VoidCallback? onAction;

  const PrakFileItem({
    super.key,
    required this.name,
    required this.meta,
    required this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ItlgShadows.outline,
      ),
      child: Row(
        children: [
          const PrakFileIcon(),
          const SizedBox(width: 10),
          Expanded(
            child: LabColumn(
              gap: 2,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labText(12, w: kBold)),
                Text(meta,
                    style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: LabIcon(action, size: 18, color: ItlgColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pilihan berikon 39 px (Jenis Pengajuan, Kategori Perangkat).
class PrakOptionChips extends StatelessWidget {
  final List<(String, String)> options;
  final int index;
  final ValueChanged<int> onChanged;

  const PrakOptionChips({
    super.key,
    required this.options,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        for (var i = 0; i < options.length; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              height: 39,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: i == index ? ItlgColors.primary : LabColors.chipIdle,
                borderRadius: BorderRadius.circular(12),
                boxShadow:
                    i == index ? ItlgShadows.primary : ItlgShadows.outline,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LabIcon(options[i].$1,
                      size: 14,
                      color: i == index ? Colors.white : ItlgColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    options[i].$2,
                    style: labText(12,
                        w: kBold,
                        c: i == index
                            ? ItlgColors.surfaceWhite
                            : ItlgColors.text),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Kotak centang 22 px (radius 6).
class PrakCheckBox extends StatelessWidget {
  final bool checked;
  const PrakCheckBox(this.checked, {super.key});

  @override
  Widget build(BuildContext context) {
    if (checked) {
      return Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ItlgColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const LabIcon('check', size: 14, color: Colors.white),
      );
    }
    return const InnerShadowBox(
      width: 22,
      height: 22,
      radius: 6,
      color: LabColors.tile,
      shadows: LabShadows.track,
    );
  }
}

/// Pilihan bercentang 53 px. Tercentang: kartu putih timbul. Tidak: cekung.
class PrakCheckOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool checked;
  final VoidCallback onTap;

  const PrakCheckOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const pad = EdgeInsets.symmetric(horizontal: 14, vertical: 12);
    final content = Row(
      children: [
        PrakCheckBox(checked),
        const SizedBox(width: 10),
        Expanded(
          child: LabColumn(
            gap: 2,
            children: [
              Text(title, style: labText(12, w: kBold)),
              Text(subtitle,
                  style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
            ],
          ),
        ),
      ],
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: checked
          ? Container(
              padding: pad,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: ItlgShadows.outline,
              ),
              child: content,
            )
          : InnerShadowBox(
              radius: 12,
              color: Colors.white,
              padding: pad,
              child: content,
            ),
    );
  }
}

/// Kolom cari 48 px + tombol filter 48 px.
///
/// [compact] = versi Daftar Praktikum (ikon vektor, bayangan filter lebih
/// kecil). Selain itu versi Pengumuman (ikon akar-icons).
class PrakSearchField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool compact;

  /// Ketuk tombol filter (kanan). Null = tombol hanya hiasan.
  final VoidCallback? onFilter;

  /// Ada filter yang sedang aktif (ikon filter berwarna merah).
  final bool filterActive;

  const PrakSearchField({
    super.key,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.compact = false,
    this.onFilter,
    this.filterActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InnerShadowBox(
            radius: 12,
            height: 48,
            color: LabColors.tile,
            shadows: LabShadows.search,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                LabIcon(compact ? 'm_search' : 'search',
                    size: 15, color: ItlgColors.textSubtle),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    cursorColor: ItlgColors.primary,
                    cursorWidth: 2.0,
                    cursorRadius: const Radius.circular(2),
                    style: labText(14),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: hint,
                      hintStyle: labText(14, c: ItlgColors.textSubtle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onFilter,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LabColors.tile,
              borderRadius: BorderRadius.circular(12),
              // Daftar Praktikum (compact): tombol filter datar sesuai Figma.
              boxShadow: compact ? const [] : LabShadows.neu,
            ),
            child: LabIcon(compact ? 'm_filter' : 'settings_horizontal',
                size: 15,
                color:
                    filterActive ? ItlgColors.primary : LabColors.filterIcon),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Bintang penilaian
// =============================================================================

/// Label Bold 12 + "n / 5", lalu 5 bintang 28 px (jarak 8).
class PrakRatingRow extends StatelessWidget {
  final String label;

  /// 0 = belum dinilai ("– / 5").
  final int value;
  final ValueChanged<int>? onChanged;

  const PrakRatingRow({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LabColumn(
      gap: 8,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: labText(12, w: kBold))),
            Text(value == 0 ? '– / 5' : '$value / 5',
                style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
          ],
        ),
        Row(
          children: [
            for (var i = 1; i <= 5; i++) ...[
              if (i > 1) const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onChanged == null ? null : () => onChanged!(i),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: LabIcon(
                    'star',
                    key: ValueKey<bool>(i <= value),
                    size: 28,
                    color:
                        i <= value ? ItlgColors.primary : LabColors.divider,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Stepper presensi (Verifikasi → Tanda Tangan → Selesai)
// =============================================================================

class PrakStepper extends StatelessWidget {
  /// 0 = Verifikasi aktif, 1 = Tanda Tangan aktif.
  final int step;
  const PrakStepper({super.key, required this.step});

  Widget _dot(int i) {
    if (i < step) {
      return Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            color: LabColors.green, shape: BoxShape.circle),
        child: const LabIcon('check', size: 12, color: Colors.white),
      );
    }
    if (i == step) {
      return Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            color: ItlgColors.primary, shape: BoxShape.circle),
        child: Text('${i + 1}',
            style: labText(11, w: kBold, c: Colors.white)),
      );
    }
    return InnerShadowBox(
      width: 24,
      height: 24,
      radius: 12,
      color: LabColors.tile,
      shadows: LabShadows.track,
      child: Center(
        child: Text('${i + 1}',
            style: labText(11, w: kBold, c: ItlgColors.textSubtle)),
      ),
    );
  }

  Widget _label(int i, String text) {
    final color = i < step
        ? LabColors.green
        : (i == step ? ItlgColors.primary : ItlgColors.textSubtle);
    return Text(text,
        maxLines: 1,
        style: labText(11, w: i == step ? kBold : kMedium, c: color));
  }

  Widget _line(bool done) => Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: done ? LabColors.green : PrakColors.line,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    const labels = ['Verifikasi', 'Tanda Tangan', 'Selesai'];
    final row = Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) _line(i <= step),
          _dot(i),
          const SizedBox(width: 6),
          _label(i, labels[i]),
        ],
      ],
    );
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ItlgShadows.outline,
      ),
      // Isi stepper butuh ~290 px; di layar yang lebih sempit diperkecil.
      child: LayoutBuilder(
        builder: (context, box) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: box.maxWidth < 300 ? 300 : box.maxWidth,
            height: 44,
            child: row,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Pop-up "Presensi Tercatat"
// =============================================================================

/// Kartu 370 px (Figma "Pop up Presensi Berhasil"), muncul dengan fade 250 ms
/// di atas latar gelap #0A0B0C 40%.
Future<void> prakShowPresensiBerhasil(
  BuildContext context, {
  required VoidCallback onPilihMeja,
  required VoidCallback onBeranda,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Presensi Tercatat',
    barrierColor: const Color(0x660A0B0C),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (dialogContext, anim, _, __) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 370),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                decoration: BoxDecoration(
                  color: ItlgColors.surfaceDark,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: ItlgShadows.outline,
                ),
                child: LabColumn(
                  gap: 13,
                  children: [
                    const Center(
                      child: PrakIconWell('circle_check',
                          color: LabColors.green),
                    ),
                    Text('Presensi Tercatat',
                        textAlign: TextAlign.center,
                        style: labText(22, w: kBold)),
                    Text(
                      'Kehadiran anda pada Praktikum Pemrograman Mobile, '
                      'Senin 05 Oktober 2026 pukul 08:03 WIB berhasil '
                      'dicatat beserta tanda tangan.',
                      textAlign: TextAlign.center,
                      style: labText(14, c: ItlgColors.textMuted),
                    ),
                    LabPrimaryButton(
                      icon: 'desktop_device',
                      label: 'Pilih Meja Praktikum',
                      large: true,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        onPilihMeja();
                      },
                    ),
                    LabOutlineButton(
                      icon: 'home',
                      label: 'Kembali ke Beranda',
                      large: true,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        onBeranda();
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
}

/// Peta 338 x 180 (gambar dasar dari Figma + pin lab + posisi anda).
/// Dipakai di Tombol Hadir (Praktikan) dan Bukti Presensi (Asisten Lab).
class PrakLocationMap extends StatelessWidget {
  final bool inside;
  const PrakLocationMap({super.key, required this.inside});

  Widget _label(String text, Color bg, Color fg, List<BoxShadow> shadow) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: shadow,
      ),
      child: Text(text, style: labText(10, w: kSemiBold, c: fg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 338 / 180,
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: 338,
          height: 180,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Image.asset('assets/praktikan_map.png',
                    fit: BoxFit.fill),
              ),
              Positioned(
                left: 158,
                top: 74,
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: ItlgColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: ItlgShadows.primary,
                  ),
                  child: const LabIcon('location',
                      size: 18, color: Colors.white),
                ),
              ),
              Positioned(
                left: 127,
                top: 114,
                width: 97,
                child: _label('Lab Komputer 1', Colors.white, ItlgColors.text,
                    ItlgShadows.outline),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                left: inside ? 204 : 296,
                top: inside ? 58 : 124,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: ItlgColors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                left: inside ? 224 : 248,
                top: inside ? 57 : 123,
                width: 44,
                child: _label(
                    'Anda', ItlgColors.secondary, Colors.white, const []),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Sheet pilihan (sama dengan sheet di peran Dosen)
// =============================================================================

/// Panel bawah #FDFEFE radius atas 24: pegangan 40x4, judul Bold 16, opsi
/// putih 48 px. Mengembalikan indeks yang dipilih (null bila ditutup).
Future<int?> prakShowPicker(
  BuildContext context, {
  required String title,
  required List<String> options,
  required int selected,
}) {
  return showGeneralDialog<int>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: const Color(0x660A0B0C),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (sheetContext, anim, _, __) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: ItlgColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 32 + MediaQuery.of(sheetContext).padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(title, style: labText(16, w: kBold, c: Colors.black)),
                const SizedBox(height: 12),
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(sheetContext).pop(i),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: ItlgShadows.outline,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              options[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: labText(12),
                            ),
                          ),
                          if (i == selected) ...[
                            const SizedBox(width: 8),
                            const LabIcon('check',
                                size: 16, color: ItlgColors.primary),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Format detik menjadi "mm:ss".
String prakClock(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final m = (s ~/ 60).toString().padLeft(2, '0');
  final r = (s % 60).toString().padLeft(2, '0');
  return '$m:$r';
}
