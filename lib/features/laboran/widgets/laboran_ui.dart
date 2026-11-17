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
  static const Color tile = Color(0xFFEEF0F3);
  static const Color blueDark = Color(0xFF1A4F89);
  static const Color avatarBg = Color(0xFFE9F0F8);
  static const Color tagBlueBg = Color(0xFFDEE9F4);
  static const Color tagRedBg = Color(0xFFEDDADA);
  static const Color warnBg = Color(0xFFE6EDB7);
  static const Color warnText = Color(0xFF9B712E);
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

void labToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ItlgColors.primary,
        duration: const Duration(seconds: 2),
        content: Text(message,
            style: labText(12, w: kBold, c: ItlgColors.surfaceWhite)),
      ),
    );
}

// =============================================================================
// Header atas (Frame 41 + Frame 45) dan tombol Kembali (Frame 29)
// =============================================================================

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
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: ItlgShadows.outline,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/gyro/gyro_avatar.png',
                      width: 38, height: 38, fit: BoxFit.contain),
                  const SizedBox(width: 3.5),
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
        width: 116,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ItlgColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ItlgShadows.outline,
        ),
        child: Row(
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

  const LabSubPage({super.key, required this.children, this.onLogoTap});

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
                child: LabColumn(gap: 24, children: children),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LabTopBar(onLogoTap: onLogoTap),
            ),
            Positioned(left: 16, top: bar + 7, child: const LabBackButton()),
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
      child: LabColumn(gap: 24, children: children),
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
            item.icon,
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

/// Kotak ikon 36 px (#EEF0F3, radius 9, bayangan timbul).
class LabIconTile extends StatelessWidget {
  final String icon;
  const LabIconTile(this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: LabColors.tile,
        borderRadius: BorderRadius.circular(9),
        boxShadow: LabShadows.neu,
      ),
      child: LabIcon(icon, size: 20, color: ItlgColors.primary),
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
            boxShadow: ItlgShadows.outline,
          ),
          child: LabIcon(icon, size: 15, color: Colors.white),
        ),
        const SizedBox(width: 9),
        Text(text, style: labText(14, w: kSemiBold, c: Colors.black)),
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
        Text(text, style: labText(16, w: kBold, c: Colors.black)),
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

/// Chip status 22 px (radius 24, padding 4/10).
class LabChip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final FontWeight weight;
  final bool shadow;
  final bool dot;

  const LabChip(
    this.text, {
    super.key,
    required this.bg,
    required this.fg,
    this.weight = kSemiBold,
    this.shadow = false,
    this.dot = false,
  });

  /// Chip putih hijau dengan ikon radio (Live, Digunakan, Siap, jam hadir).
  const LabChip.live(this.text, {super.key})
      : bg = Colors.white,
        fg = LabColors.green,
        weight = kBold,
        shadow = true,
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
        boxShadow: shadow ? ItlgShadows.outline : const [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            LabIcon('radio_btn_active', size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(text, style: labText(12, w: weight, c: fg)),
        ],
      ),
    );
  }
}

/// Pill abu-abu timbul dengan ikon 12 px (jam, Real-time, bulan).
class LabPill extends StatelessWidget {
  final String icon;
  final String text;
  const LabPill({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(11),
        boxShadow: LabShadows.neu,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LabIcon(icon, size: 12, color: ItlgColors.textSubtle),
          const SizedBox(width: 4),
          Text(text, style: labText(12, c: ItlgColors.textSubtle)),
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
