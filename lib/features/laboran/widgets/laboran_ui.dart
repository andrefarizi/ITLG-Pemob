import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../gyro/gyro_page.dart';

/// Komponen halaman peran Laboran (Figma: section "03 Laboran").
///
/// Semua ukuran, warna, radius, dan bayangan diambil dari Figma dengan kanvas
/// 402 px. Lebar konten = lebar layar - 32, jadi di 402 px hasilnya sama
/// persis dan di layar lain menyesuaikan.

// =============================================================================
// Token
// =============================================================================

class LabColors {
  LabColors._();

  static const Color green = Color(0xFF2E9B5B);

  /// Latar chip status hijau (Hadir, Digunakan, Siap, dst).
  static const Color greenBg = Color(0xFFE8F5EE);
  static const Color tile = Color(0xFFEEF0F3);
  static const Color blueDark = Color(0xFF1A4F89);
  static const Color avatarBg = Color(0xFFE9F0F8);
  static const Color tagBlueBg = Color(0xFFDEE9F4);
  static const Color tagRedBg = Color(0xFFEDDADA);
  static const Color warnBg = Color(0xFFE6EDB7);
  static const Color warnText = Color(0xFF9B712E);
  static const Color warnSoftBg = Color(0xFFFBF1DC);
  static const Color line = Color(0xFFEEF0F2);
  static const Color textGrey = Color(0xFF5B636B);
  static const Color bar = Color(0xFFFBFCFC);
  static const Color chipIdle = Color(0xFFFEFEFE);
  static const Color divider = Color(0xFFB5B9BC);
  static const Color gyroText = Color(0xFF2F0303);
  static const Color filterIcon = Color(0xFF202124);
  static const Color toggleOff = Color(0xFFC9CDD2);
}

class LabShadows {
  LabShadows._();

  /// Bayangan timbul pada ikon kotak, pill, dan tombol filter.
  static const List<BoxShadow> neu = [
    BoxShadow(offset: Offset(6, 6), blurRadius: 14, color: Color(0x73A3B1C6)),
    BoxShadow(offset: Offset(-6, -6), blurRadius: 11, color: Color(0xE6FFFFFF)),
  ];

  /// Inner shadow jalur progress dan titik langkah yang belum aktif.
  static const List<BoxShadow> track = [
    BoxShadow(offset: Offset(-1, -1), blurRadius: 3, color: Color(0xE6FFFFFF)),
    BoxShadow(offset: Offset(1, 1), blurRadius: 3, color: Color(0x80A3B1C6)),
  ];

  /// Inner shadow kolom pencarian.
  static const List<BoxShadow> search = [
    BoxShadow(offset: Offset(-3, -3), blurRadius: 6, color: Color(0xE6FFFFFF)),
    BoxShadow(offset: Offset(3, 3), blurRadius: 6, color: Color(0x80A3B1C6)),
  ];

  /// Bayangan ke atas pada navbar.
  static const List<BoxShadow> navbar = [
    BoxShadow(offset: Offset(0, -4), blurRadius: 12, color: Color(0x40A3B1C6)),
  ];
}

const FontWeight kMedium = FontWeight.w500;
const FontWeight kSemiBold = FontWeight.w600;
const FontWeight kBold = FontWeight.w700;

/// Gaya teks Montserrat dengan line-height 120% seperti di Figma.
TextStyle labText(
  double size, {
  FontWeight w = FontWeight.w400,
  Color c = ItlgColors.text,
}) =>
    ItlgText.style(size: size, weight: w, color: c, height: 1.2);

// =============================================================================
// Ikon (PNG hasil ekspor Figma, diwarnai lewat [color])
// =============================================================================

class LabIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color color;

  const LabIcon(this.name, {super.key, this.size = 20, required this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/ic_$name.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      filterQuality: FilterQuality.medium,
    );
  }
}

// =============================================================================
// Navigasi (durasi & arah mengikuti prototipe Figma)
// =============================================================================

/// Halaman detail: masuk dari kanan, 300 ms ease-out.
Future<T?> labPush<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
    ),
  );
}

/// Tanya Gyro: naik dari bawah, 350 ms ease-out.
Future<void> labOpenGyro(BuildContext context) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const GyroPage(),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
    ),
  );
}

/// Toast global ITLG (Figma: "Toast Semua Notifikasi Dibaca" 5828:3303):
/// batang #202124 radius 14, ikon centang hijau 20px, teks SemiBold 13px putih.
void labToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF202124),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const LabIcon('circle_check', size: 20, color: LabColors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: labText(13, w: kSemiBold, c: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Pop-up hasil (Figma: "Pop up Berkas Diunduh", "Pop up Izin Disetujui",
/// dst): kartu 370 px, ikon 44 px di kotak cekung 80 px, judul Bold 22,
/// pesan Regular 14, tombol merah 50 px. Muncul dengan fade 250 ms di atas
/// latar gelap #0A0B0C 40%.
Future<void> labShowResult(
  BuildContext context, {
  required String icon,
  required String title,
  required String message,
  String button = 'Selesai',
  VoidCallback? onPressed,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: title,
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
                padding: const EdgeInsets.fromLTRB(16, 22, 17, 22),
                decoration: BoxDecoration(
                  color: ItlgColors.surfaceDark,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: ItlgShadows.outline,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: InnerShadowBox(
                        width: 80,
                        height: 80,
                        radius: 19.875,
                        shadows: ItlgShadows.innerLarge,
                        child: Center(
                          child: LabIcon(icon,
                              size: 44, color: ItlgColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(title,
                        textAlign: TextAlign.center,
                        style: labText(22, w: kBold)),
                    const SizedBox(height: 8),
                    Text(message,
                        textAlign: TextAlign.center,
                        style: labText(14, c: ItlgColors.textMuted)),
                    const SizedBox(height: 13),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        onPressed?.call();
                      },
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ItlgColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: ItlgShadows.primary,
                        ),
                        child: Text(button,
                            style: labText(16,
                                w: kBold, c: ItlgColors.surfaceWhite)),
                      ),
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

// =============================================================================
// Header atas (Frame 41 + Frame 45) dan tombol Kembali (Frame 29)
// =============================================================================

/// Jarak antar-bagian di halaman (Figma: auto layout "Content" gap 28).
const double kLabSectionGap = 28;

/// Tinggi header di bawah status bar (112 - 60 di Figma).
const double kLabTopBarBody = 52;

double labTopBarHeight(BuildContext context) =>
    MediaQuery.of(context).padding.top + kLabTopBarBody;

class LabTopBar extends StatelessWidget {
  /// Ketuk logo ITLG (kembali ke Beranda).
  final VoidCallback? onLogoTap;

  const LabTopBar({super.key, this.onLogoTap});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      height: top + kLabTopBarBody,
      padding: EdgeInsets.fromLTRB(19, top, 18, 14),
      decoration: const BoxDecoration(
        color: LabColors.bar,
        boxShadow: ItlgShadows.outline,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onLogoTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ItlgLogoMark(size: 28.6),
                const SizedBox(width: 6.5),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ITLG',
                      style: ItlgText.style(
                        size: 14.82,
                        weight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        height: 1.2,
                      ),
                    ),
                    Text('Mobile', style: labText(11.12)),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => labOpenGyro(context),
            child: Container(
              width: 146,
              height: 38.12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: ItlgShadows.outline,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/gyro/gyro_avatar.png',
                    width: 38.12,
                    height: 38.12,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
                  const SizedBox(width: 3.55),
                  Text('Tanya Gyro',
                      style: labText(14.18, w: kBold, c: LabColors.gyroText)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LabBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const LabBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      child: Container(
        // Lebar Figma 116 px; boleh melebar sedikit bila font perangkat
        // lebih lebar supaya teks "Kembali" tidak terpotong (overflow).
        constraints: const BoxConstraints(minWidth: 116),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ItlgColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ItlgShadows.outline,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LabIcon('arrow_back', size: 24, color: ItlgColors.primary),
            const SizedBox(width: 7),
            Text('Kembali',
                style: labText(16, w: kBold, c: ItlgColors.primary)),
          ],
        ),
      ),
    );
  }
}

/// Kerangka halaman detail (tanpa navbar): header + tombol Kembali tetap di
/// atas, konten mulai 57 px di bawah header dan bisa di-scroll.
class LabSubPage extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback? onLogoTap;

  /// Jarak antar-bagian (Figma: gap auto layout "Content").
  final double gap;

  /// Aksi tombol Kembali (default: tutup halaman ini).
  final VoidCallback? onBack;

  const LabSubPage({
    super.key,
    required this.children,
    this.onLogoTap,
    this.gap = kLabSectionGap,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bar = labTopBarHeight(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: ItlgColors.surfaceWhite,
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  bar + 57,
                  16,
                  56 + MediaQuery.of(context).padding.bottom,
                ),
                child: LabColumn(gap: gap, children: children),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LabTopBar(onLogoTap: onLogoTap),
            ),
            Positioned(
              left: 16,
              top: bar + 7,
              child: LabBackButton(onTap: onBack),
            ),
          ],
        ),
      ),
    );
  }
}

/// Isi halaman tab (di dalam LaboranShell): konten mulai 20 px di bawah header
/// dan berakhir 40 px di atas navbar.
class LabTabBody extends StatelessWidget {
  final List<Widget> children;
  const LabTabBody({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding:
          EdgeInsets.fromLTRB(16, labTopBarHeight(context) + 20, 16, 40),
      child: LabColumn(gap: kLabSectionGap, children: children),
    );
  }
}

// =============================================================================
// Navbar bawah
// =============================================================================

class LabNavItem {
  final String label;
  final String icon;
  const LabNavItem(this.label, this.icon);
}

class LabNavBar extends StatelessWidget {
  final List<LabNavItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  const LabNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, inset > 22 ? inset : 22),
      decoration: const BoxDecoration(
        color: LabColors.bar,
        boxShadow: LabShadows.navbar,
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: _NavTab(item: items[i], active: i == index),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final LabNavItem item;
  final bool active;
  const _NavTab({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 52,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? ItlgColors.primary : const Color(0x00850909),
            borderRadius: BorderRadius.circular(16),
            boxShadow: active ? ItlgShadows.primary : const [],
          ),
          child: LabIcon(
            // Ikon navbar sengaja memakai aset tersendiri (ic_nav_*) supaya
            // tidak ikut berubah ketika ikon konten diganti.
            'nav_${item.icon}',
            size: 20,
            color: active ? Colors.white : ItlgColors.textSubtle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.clip,
          softWrap: false,
          style: labText(
            11,
            w: active ? kBold : kMedium,
            c: active ? ItlgColors.primary : ItlgColors.textSubtle,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Susunan
// =============================================================================

/// Column dengan jarak antar-anak tetap (auto layout vertikal di Figma).
class LabColumn extends StatelessWidget {
  final double gap;
  final List<Widget> children;
  final CrossAxisAlignment cross;

  const LabColumn({
    super.key,
    required this.gap,
    required this.children,
    this.cross = CrossAxisAlignment.stretch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: cross,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          children[i],
        ],
      ],
    );
  }
}

/// Kartu abu-abu #F5F5F5, radius 24, padding 16, jarak isi 16.
class LabCard extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  final VoidCallback? onTap;

  const LabCard({super.key, required this.children, this.gap = 16, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ItlgShadows.outline,
      ),
      child: LabColumn(gap: gap, children: children),
    );
    if (onTap == null) return card;
    return GestureDetector(
        behavior: HitTestBehavior.opaque, onTap: onTap, child: card);
  }
}

/// Judul halaman: Bold 22 + keterangan Regular 14.
class LabTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const LabTitle({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return LabColumn(
      gap: 6,
      children: [
        Text(title, style: labText(22, w: kBold, c: Colors.black)),
        Text(subtitle, style: labText(14, c: Colors.black)),
      ],
    );
  }
}

/// Keterangan kecil di atas judul kartu (Regular 14 merah tua) + judul.
class LabOverline extends StatelessWidget {
  final String overline;
  final String title;
  final double titleSize;

  const LabOverline({
    super.key,
    required this.overline,
    required this.title,
    this.titleSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return LabColumn(
      gap: 6,
      children: [
        Text(overline, style: labText(14, c: ItlgColors.primaryDark)),
        Text(title, style: labText(titleSize, w: kBold, c: Colors.black)),
      ],
    );
  }
}

// =============================================================================
// Elemen kecil
// =============================================================================

/// Kotak ikon 36 px (#EEF0F3, radius 9). Datar, tanpa bayangan.
class LabIconTile extends StatelessWidget {
  final String icon;
  final Color color;
  final Color bg;
  final double size;
  final double iconSize;
  const LabIconTile(
    this.icon, {
    super.key,
    this.color = ItlgColors.primary,
    this.bg = LabColors.tile,
    this.size = 36,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: LabIcon(icon, size: iconSize, color: color),
    );
  }
}

/// Judul bagian di dalam kartu: kotak merah 28 px + teks SemiBold 14.
class LabSectionTitle extends StatelessWidget {
  final String icon;
  final String text;
  const LabSectionTitle({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ItlgColors.primary,
            borderRadius: BorderRadius.circular(7),
          ),
          child: LabIcon(icon, size: 15, color: Colors.white),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labText(14, w: kSemiBold, c: Colors.black)),
        ),
      ],
    );
  }
}

/// Judul bagian di luar kartu: ikon biru 20 px + teks Bold 16.
class LabHeading extends StatelessWidget {
  final String icon;
  final String text;
  const LabHeading({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LabIcon(icon, size: 20, color: LabColors.blueDark),
        const SizedBox(width: 8),
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labText(16, w: kBold, c: Colors.black)),
        ),
      ],
    );
  }
}

/// Avatar inisial 36 px.
class LabAvatar extends StatelessWidget {
  final String initials;
  const LabAvatar(this.initials, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: LabColors.avatarBg,
        shape: BoxShape.circle,
      ),
      child: Text(initials, style: labText(12, w: kBold, c: LabColors.blueDark)),
    );
  }
}

/// Avatar + nama Bold 14 + keterangan Medium 11.
class LabPerson extends StatelessWidget {
  final String initials;
  final String name;
  final String caption;

  const LabPerson({
    super.key,
    required this.initials,
    required this.name,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LabAvatar(initials),
        const SizedBox(width: 10),
        Expanded(
          child: LabColumn(
            gap: 2,
            children: [
              Text(name, style: labText(14, w: kBold)),
              Text(caption,
                  style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Titik status bercincin 10 px (Figma: radio-dot kecil, garis 0,9 px).
class LabRingDot extends StatelessWidget {
  final Color color;
  final double size;
  const LabRingDot({super.key, required this.color, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RingDotPainter(color)),
    );
  }
}

class _RingDotPainter extends CustomPainter {
  final Color color;
  const _RingDotPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final s = size.shortestSide / 10;
    canvas.drawCircle(
      c,
      3.75 * s,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9 * s
        ..color = color,
    );
    canvas.drawCircle(c, 1.9 * s, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RingDotPainter old) => old.color != color;
}

/// Chip status 22 px (radius 24, padding 4/10). Datar, tanpa bayangan.
class LabChip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final FontWeight weight;
  final bool dot;

  /// Tidak dipakai lagi (status tidak memakai bayangan); tetap ada supaya
  /// pemanggil lama tidak perlu diubah.
  final bool shadow;

  const LabChip(
    this.text, {
    super.key,
    required this.bg,
    required this.fg,
    this.weight = kSemiBold,
    this.shadow = false,
    this.dot = false,
  });

  /// Hijau muda dengan titik bercincin (Live, Digunakan, Siap, jam hadir).
  const LabChip.live(this.text, {super.key})
      : bg = LabColors.greenBg,
        fg = LabColors.green,
        weight = kBold,
        shadow = false,
        dot = true;

  /// Merah muda (Reported, Rusak).
  const LabChip.danger(this.text, {super.key})
      : bg = LabColors.tagRedBg,
        fg = ItlgColors.primary,
        weight = kSemiBold,
        shadow = false,
        dot = false;

  /// Kuning (In Progress, Menunggu Persetujuan, Terlambat).
  const LabChip.warn(this.text, {super.key})
      : bg = LabColors.warnBg,
        fg = LabColors.warnText,
        weight = kSemiBold,
        shadow = false,
        dot = false;

  /// Abu-abu (Kosong, Belum).
  const LabChip.idle(this.text, {super.key})
      : bg = LabColors.tile,
        fg = ItlgColors.textSubtle,
        weight = kSemiBold,
        shadow = false,
        dot = false;

  /// Biru muda (peran di Profil).
  const LabChip.info(this.text, {super.key})
      : bg = LabColors.tagBlueBg,
        fg = ItlgColors.secondary,
        weight = kSemiBold,
        shadow = false,
        dot = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            LabRingDot(color: fg),
            const SizedBox(width: 6),
          ],
          // Flexible: teks panjang terpotong rapi, tidak overflow.
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: labText(12, w: weight, c: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill abu-abu datar dengan ikon 12 px (jam, Real-time, minggu ke-n).
class LabPill extends StatelessWidget {
  final String icon;
  final String text;
  final Color color;
  const LabPill({
    super.key,
    required this.icon,
    required this.text,
    this.color = ItlgColors.textSubtle,
  });

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
          LabIcon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: labText(12, c: color)),
          ),
        ],
      ),
    );
  }
}

/// Tag kecil 16 px (radius 6, SemiBold 10).
class LabTag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const LabTag(this.text, {super.key, required this.bg, required this.fg});

  const LabTag.blue(this.text, {super.key})
      : bg = LabColors.tagBlueBg,
        fg = ItlgColors.secondary;

  const LabTag.red(this.text, {super.key})
      : bg = LabColors.tagRedBg,
        fg = ItlgColors.primary;

  const LabTag.grey(this.text, {super.key})
      : bg = LabColors.tile,
        fg = ItlgColors.textSubtle;

  @override
  Widget build(BuildContext context) {
    // Center(widthFactor: 1) supaya tag selebar teksnya, juga di dalam Column.
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(text, style: labText(10, w: kSemiBold, c: fg)),
      ),
    );
  }
}

/// Ikon 12 px + teks Medium 11.
class LabMeta extends StatelessWidget {
  final String icon;
  final String text;
  final Color color;

  const LabMeta({
    super.key,
    required this.icon,
    required this.text,
    this.color = ItlgColors.textSubtle,
  });

  @override
  Widget build(BuildContext context) {
    // Text.rich supaya aman dipakai di dalam Row maupun Column (tidak butuh
    // Flexible) dan tetap terpotong rapi bila ruangnya sempit.
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: LabIcon(icon, size: 12, color: color),
            ),
          ),
          TextSpan(text: text),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: labText(11, w: kMedium, c: color),
    );
  }
}

/// Kotak statistik 60 px (inner shadow): label kecil + nilai Bold 14.
class LabStat extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const LabStat({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return InnerShadowBox(
      radius: 12,
      height: 60,
      color: ItlgColors.surfaceDark,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabMeta(icon: icon, text: label, color: ItlgColors.textMuted),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labText(14, w: kBold),
          ),
        ],
      ),
    );
  }
}

/// Deret kotak statistik selebar kartu.
class LabStatRow extends StatelessWidget {
  final List<LabStat> stats;
  final double gap;
  const LabStatRow({super.key, required this.stats, this.gap = 10});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: stats[i]),
        ],
      ],
    );
  }
}

/// Label + nilai + batang progress 6 px.
class LabProgress extends StatelessWidget {
  final String label;
  final String value;

  /// 0..1 (di Figma: lebar isi / 338).
  final double fraction;
  final Color color;

  const LabProgress({
    super.key,
    required this.label,
    required this.value,
    required this.fraction,
    this.color = LabColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return LabColumn(
      gap: 4,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: labText(12, c: ItlgColors.textSubtle)),
            ),
            Text(value, style: labText(12, w: kBold)),
          ],
        ),
        InnerShadowBox(
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
        ),
      ],
    );
  }
}

/// Kotak putih dengan inner shadow (radius 12).
class LabInsetBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const LabInsetBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return InnerShadowBox(
      radius: 12,
      color: Colors.white,
      padding: padding,
      child: child,
    );
  }
}

/// Baris daftar putih (radius 12, padding 11/14, Outline Shadow).
class LabListItem extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final double titleSize;
  final VoidCallback? onTap;

  const LabListItem({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.titleSize = 14,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ItlgShadows.outline,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: LabColumn(
                gap: 2,
                children: [
                  Text(title, style: labText(titleSize, w: kBold)),
                  Text(subtitle,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Kartu abu-abu pembungkus daftar (Figma "Kartu Daftar": padding 12,
/// jarak 10, radius 24, Outline Shadow). Isinya [LabRowCard].
class LabListCard extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  final EdgeInsetsGeometry padding;
  const LabListCard({
    super.key,
    required this.children,
    this.gap = 10,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ItlgShadows.outline,
      ),
      child: LabColumn(gap: gap, children: children),
    );
  }
}

/// Baris putih timbul di dalam [LabListCard] (radius 16, padding 14).
class LabRowCard extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  const LabRowCard({
    super.key,
    required this.children,
    this.gap = 12,
    this.padding = const EdgeInsets.all(14),
    this.radius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: ItlgShadows.outline,
      ),
      child: LabColumn(gap: gap, children: children),
    );
    if (onTap == null) return card;
    return GestureDetector(
        behavior: HitTestBehavior.opaque, onTap: onTap, child: card);
  }
}

// =============================================================================
// Tab pilihan & tombol
// =============================================================================

/// Deret tab/opsi 39 px. Yang aktif merah dengan cahaya, lainnya putih.
class LabTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  /// Tab halaman: gap 12 & padding 14. Opsi di kartu: gap 10 & padding 12.
  final double gap;
  final double hPadding;

  const LabTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.gap = 12,
    this.hPadding = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            _TabChip(
              label: labels[i],
              selected: i == index,
              hPadding: hPadding,
              onTap: () => onChanged(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final double hPadding;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.hPadding,
    required this.onTap,
  });

  static const Duration _d = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: _d,
        curve: Curves.easeOut,
        height: 39,
        padding: EdgeInsets.symmetric(horizontal: hPadding),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? ItlgColors.primary : LabColors.chipIdle,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? ItlgShadows.primary : ItlgShadows.outline,
        ),
        child: AnimatedDefaultTextStyle(
          duration: _d,
          curve: Curves.easeOut,
          style: labText(
            12,
            w: kBold,
            c: selected ? ItlgColors.surfaceWhite : ItlgColors.text,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// Tombol merah. Kecil: 41 px (Bold 12, ikon 16). Besar: 50 px (Bold 16,
/// ikon 22).
class LabPrimaryButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool large;
  final VoidCallback? onTap;

  const LabPrimaryButton({
    super.key,
    required this.icon,
    required this.label,
    this.large = false,
    this.onTap,
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
            LabIcon(icon,
                size: large ? 22 : 16, color: ItlgColors.surfaceWhite),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labText(large ? 16 : 12,
                    w: kBold, c: ItlgColors.surfaceWhite),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol putih (#FBFCFC, garis dalam putih 4 px) dengan teks merah.
class LabOutlineButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool large;
  final VoidCallback? onTap;

  const LabOutlineButton({
    super.key,
    required this.icon,
    required this.label,
    this.large = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: large ? 50 : 41,
        decoration: BoxDecoration(
          color: LabColors.bar,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: ItlgShadows.outline,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LabIcon(icon, size: large ? 22 : 16, color: ItlgColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    labText(large ? 16 : 12, w: kBold, c: ItlgColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dua tombol sejajar dengan perbandingan lebar Figma (167 : 159, jarak 12).
class LabButtonPair extends StatelessWidget {
  final Widget left;
  final Widget right;
  const LabButtonPair({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 167, child: left),
        const SizedBox(width: 12),
        Expanded(flex: 159, child: right),
      ],
    );
  }
}

/// Lingkaran status 26/28 px berisi ikon putih.
class LabStatusDot extends StatelessWidget {
  final double size;
  final Color color;
  final String icon;

  const LabStatusDot({
    super.key,
    required this.size,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: LabIcon(icon, size: 14, color: Colors.white),
    );
  }
}

// =============================================================================
// Komponen UX Baru (Figma: Avatar Inisial, Badge Lonceng, Pop up Konfirmasi,
// Pop up Hasil, Sheet Scrollable, & Date-Time Picker)
// =============================================================================

/// Avatar inisial bulat bergaya Figma (`#F3E6E6`, border `#D9B8B8`, teks `#850909`).
/// Jika [photoSource] berisi URL Supabase atau path file lokal yang valid,
/// menampilkan foto profil nyata secara bulat dengan fallback otomatis ke inisial.
class LabInitialAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final double? fontSize;
  final bool hasPhotoBadge;
  final String? photoSource;

  const LabInitialAvatar({
    super.key,
    required this.initials,
    this.size = 64,
    this.fontSize,
    this.hasPhotoBadge = false,
    this.photoSource,
  });

  Widget _initialsWidget(double fs) {
    return Text(
      initials,
      style: labText(
        fs,
        w: kBold,
        c: hasPhotoBadge ? ItlgColors.secondary : ItlgColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fs = fontSize ?? (size * 0.34);
    final src = photoSource?.trim();
    Widget content = _initialsWidget(fs);

    if (src != null && src.isNotEmpty) {
      if (src.startsWith('http://') || src.startsWith('https://')) {
        content = ClipOval(
          child: Image.network(
            src,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(child: _initialsWidget(fs)),
          ),
        );
      } else if (!kIsWeb && File(src).existsSync()) {
        content = ClipOval(
          child: Image.file(
            File(src),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(child: _initialsWidget(fs)),
          ),
        );
      }
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasPhotoBadge ? const Color(0xFFEAF2FB) : const Color(0xFFF3E6E6),
        shape: BoxShape.circle,
        border: Border.all(
          color: hasPhotoBadge
              ? const Color(0xFFB6D2F2)
              : const Color(0xFFD9B8B8),
          width: 1.2,
        ),
      ),
      child: content,
    );
  }
}

/// Tombol lonceng notifikasi bulat merah 40x40 (Figma 5813:3004 / 5497:1559 /
/// 5479:186 / 5479:1160) dengan badge bulat putih berbingkai merah di kanan atas.
class LabBellButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const LabBellButton({
    super.key,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ItlgColors.primary,
                shape: BoxShape.circle,
                boxShadow: ItlgShadows.primary,
              ),
              child: const LabIcon('bell_filled', size: 19, color: Colors.white),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ItlgColors.primary, width: 1.6),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: labText(10, w: kBold, c: ItlgColors.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tombol merah lembut bergaya Figma ("Akhiri Pemakaian Meja" 5712:2948 &
/// "Batalkan Permintaan Tukar Jadwal" 5814:3113): latar #FCEAEA, teks #850909 Bold.
class LabSoftDangerButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const LabSoftDangerButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEAEA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LabIcon(icon, size: 18, color: ItlgColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labText(14, w: kBold, c: ItlgColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma: "Sheet Filter & Urutkan" (5828:3158).
Future<({int sortIndex, int statusIndex})?> labShowFilterSortSheet(
  BuildContext context, {
  int initialSort = 0,
  int initialStatus = 0,
  List<String> sortOptions = const ['Terbaru', 'Terlama', 'Nama A–Z'],
  List<String> statusOptions = const ['Semua', 'Perlu Tindakan', 'Selesai'],
}) {
  var sortIdx = initialSort;
  var statusIdx = initialStatus;
  return labShowCustomSheet<({int sortIndex, int statusIndex})>(
    context,
    title: 'Filter & Urutkan',
    child: StatefulBuilder(
      builder: (ctx, setSheetState) {
        Widget chipRow(
            List<String> labels, int active, ValueChanged<int> onPick) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < labels.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onPick(i),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == active ? ItlgColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: i == active
                          ? ItlgShadows.primary
                          : ItlgShadows.outline,
                    ),
                    child: Text(
                      labels[i],
                      style: labText(
                        12,
                        w: kBold,
                        c: i == active ? Colors.white : ItlgColors.text,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }

        return LabColumn(
          gap: 14,
          children: [
            LabColumn(
              gap: 8,
              children: [
                Text('Urutkan', style: labText(13, c: ItlgColors.textMuted)),
                chipRow(sortOptions, sortIdx,
                    (i) => setSheetState(() => sortIdx = i)),
              ],
            ),
            LabColumn(
              gap: 8,
              children: [
                Text('Status', style: labText(13, c: ItlgColors.textMuted)),
                chipRow(statusOptions, statusIdx,
                    (i) => setSheetState(() => statusIdx = i)),
              ],
            ),
            const SizedBox(height: 2),
            LabButtonPair(
              left: LabOutlineButton(
                icon: 'arrow_cycle',
                label: 'Reset',
                onTap: () => Navigator.of(ctx)
                    .pop((sortIndex: 0, statusIndex: 0)),
              ),
              right: LabPrimaryButton(
                icon: 'check',
                label: 'Terapkan',
                onTap: () => Navigator.of(ctx)
                    .pop((sortIndex: sortIdx, statusIndex: statusIdx)),
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// Pop-up konfirmasi dua tombol bergaya Figma ("Keluar Akun", "Akhiri Meja",
/// "Selesai Kuis", "Batalkan Pengumpulan"). Mengembalikan true jika dikonfirmasi.
Future<bool> labShowConfirmDialog(
  BuildContext context, {
  required String icon,
  required String title,
  required String message,
  String cancelLabel = 'Batal',
  required String confirmLabel,
}) async {
  final res = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: const Color(0x660A0B0C),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (dialogCtx, anim, _, __) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 370),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
                decoration: BoxDecoration(
                  color: ItlgColors.surfaceDark,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: ItlgShadows.outline,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: InnerShadowBox(
                        width: 79.5,
                        height: 79.5,
                        radius: 20,
                        color: ItlgColors.field,
                        shadows: ItlgShadows.innerLarge,
                        child: Center(
                          child: LabIcon(icon,
                              size: 40, color: ItlgColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: labText(20, w: kBold, c: ItlgColors.text),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: labText(14, c: ItlgColors.textMuted),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(dialogCtx).pop(false),
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: LabColors.bar,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: ItlgShadows.outline,
                              ),
                              child: Text(
                                cancelLabel,
                                textAlign: TextAlign.center,
                                style: labText(14,
                                    w: kBold, c: ItlgColors.primary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(dialogCtx).pop(true),
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: ItlgColors.primary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: ItlgShadows.primary,
                              ),
                              child: Text(
                                confirmLabel,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: labText(14,
                                    w: kBold, c: ItlgColors.surfaceWhite),
                              ),
                            ),
                          ),
                        ),
                      ],
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
  return res ?? false;
}

/// Pop-up hasil 1 tombol bergaya Figma ("Kata Sandi Diperbarui",
/// "Check-In Berhasil", "Sanggahan Disetujui", "Nilai Diperbarui").
Future<void> labShowResultDialog(
  BuildContext context, {
  required String icon,
  required String title,
  required String message,
  String button = 'Selesai',
  VoidCallback? onPressed,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: title,
    barrierColor: const Color(0x660A0B0C),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (dialogCtx, anim, _, __) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 370),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
                decoration: BoxDecoration(
                  color: ItlgColors.surfaceDark,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: ItlgShadows.outline,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: InnerShadowBox(
                        width: 79.5,
                        height: 79.5,
                        radius: 20,
                        color: ItlgColors.field,
                        shadows: ItlgShadows.innerLarge,
                        child: Center(
                          child: LabIcon(icon,
                              size: 40, color: ItlgColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: labText(20, w: kBold, c: ItlgColors.text),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: labText(14, c: ItlgColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.of(dialogCtx).pop();
                        onPressed?.call();
                      },
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ItlgColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: ItlgShadows.primary,
                        ),
                        child: Text(
                          button,
                          style: labText(16,
                              w: kBold, c: ItlgColors.surfaceWhite),
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
    ),
  );
}

/// Bottom sheet umum ITLG dengan handle bar 40x4 dan scroll otomatis.
Future<T?> labShowCustomSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x660A0B0C),
    builder: (sheetCtx) {
      final bottomInset = MediaQuery.of(sheetCtx).viewInsets.bottom +
          MediaQuery.of(sheetCtx).padding.bottom;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: ItlgColors.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
          child: SingleChildScrollView(
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
                const SizedBox(height: 14),
                Text(title, style: labText(16, w: kBold, c: Colors.black)),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: labText(12, c: ItlgColors.textSubtle)),
                ],
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Figma: "Sheet Pilih Tanggal & Jam" (5816:3260).
Future<DateTime?> labShowDateTimePicker(
  BuildContext context, {
  DateTime? initial,
  String title = 'Pilih Tanggal & Jam',
}) async {
  DateTime selectedDate = initial ?? DateTime(2026, 10, 5, 23, 59);
  int selectedHour = selectedDate.hour;
  int selectedMinute = selectedDate.minute;

  const monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x660A0B0C),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final firstOfMonth =
              DateTime(selectedDate.year, selectedDate.month, 1);
          final daysInMonth =
              DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
          final leadingEmpty = firstOfMonth.weekday - 1;
          final totalCells = leadingEmpty + daysInMonth;

          return Container(
            decoration: const BoxDecoration(
              color: ItlgColors.surfaceWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              24 + MediaQuery.of(ctx).padding.bottom,
            ),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 14),
                  Text(title, style: labText(16, w: kBold, c: Colors.black)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setSheetState(() {
                          selectedDate = DateTime(
                              selectedDate.year, selectedDate.month - 1, 1);
                        }),
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: ItlgShadows.outline,
                          ),
                          child: const LabIcon('arrow_left',
                              size: 16, color: ItlgColors.primary),
                        ),
                      ),
                      Text(
                        '${monthNames[selectedDate.month - 1]} ${selectedDate.year}',
                        style: labText(14, w: kBold),
                      ),
                      GestureDetector(
                        onTap: () => setSheetState(() {
                          selectedDate = DateTime(
                              selectedDate.year, selectedDate.month + 1, 1);
                        }),
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: ItlgShadows.outline,
                          ),
                          child: const LabIcon('arrow_right',
                              size: 16, color: ItlgColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final d in dayNames)
                        Expanded(
                          child: Center(
                            child: Text(d,
                                style: labText(11,
                                    w: kSemiBold, c: ItlgColors.textSubtle)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: totalCells,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemBuilder: (_, idx) {
                      if (idx < leadingEmpty) return const SizedBox.shrink();
                      final day = idx - leadingEmpty + 1;
                      final active = day == selectedDate.day;
                      return GestureDetector(
                        onTap: () => setSheetState(() {
                          selectedDate = DateTime(
                              selectedDate.year, selectedDate.month, day);
                        }),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? ItlgColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: active
                                ? ItlgShadows.primary
                                : ItlgShadows.outline,
                          ),
                          child: Text(
                            '$day',
                            style: labText(12,
                                w: active ? kBold : kMedium,
                                c: active ? Colors.white : ItlgColors.text),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Jam (WIB)',
                                style: labText(12,
                                    w: kSemiBold, c: ItlgColors.textSubtle)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final slot in const [
                                  (8, 0, '08:00'),
                                  (10, 0, '10:00'),
                                  (13, 0, '13:00'),
                                  (15, 0, '15:00'),
                                  (17, 0, '17:00'),
                                  (23, 59, '23:59'),
                                ])
                                  GestureDetector(
                                    onTap: () => setSheetState(() {
                                      selectedHour = slot.$1;
                                      selectedMinute = slot.$2;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: (selectedHour == slot.$1 &&
                                                selectedMinute == slot.$2)
                                            ? ItlgColors.primary
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: ItlgShadows.outline,
                                      ),
                                      child: Text(
                                        slot.$3,
                                        style: labText(
                                          11,
                                          w: kBold,
                                          c: (selectedHour == slot.$1 &&
                                                  selectedMinute == slot.$2)
                                              ? Colors.white
                                              : ItlgColors.text,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LabPrimaryButton(
                    icon: 'check',
                    label: 'Terapkan Tanggal & Jam',
                    large: true,
                    onTap: () => Navigator.of(ctx).pop(DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedHour,
                      selectedMinute,
                    )),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
