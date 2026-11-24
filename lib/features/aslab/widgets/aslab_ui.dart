import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';

/// Komponen khusus halaman Asisten Lab.

// Pemilih hari (Shift Jaga)

/// Widget pemilih hari pada jadwal shift.
class AslabDaySelector extends StatelessWidget {
  final List<(String, String, String)> days;
  final int index;
  final ValueChanged<int> onChanged;

  const AslabDaySelector({
    super.key,
    required this.days,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = ((box.maxWidth - 5 * 6) / days.length)
              .clamp(40.0, 52.0)
              .toDouble();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < days.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    width: w,
                    height: 64,
                    decoration: BoxDecoration(
                      color: i == index ? ItlgColors.primary : LabColors.tile,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow:
                          i == index ? ItlgShadows.primary : LabShadows.neu,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(days[i].$1,
                            style: labText(12,
                                w: i == index ? kSemiBold : kMedium,
                                c: i == index
                                    ? Colors.white
                                    : ItlgColors.textSubtle)),
                        Text(days[i].$2,
                            style: labText(18,
                                w: kBold,
                                c: i == index
                                    ? Colors.white
                                    : LabColors.filterIcon)),
                        Text(days[i].$3,
                            style: labText(11,
                                w: kMedium,
                                c: i == index
                                    ? Colors.white
                                    : ItlgColors.textSubtle)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// Elemen kecil

/// Dua avatar bertumpuk (jarak -8).
class AslabAvatarPair extends StatelessWidget {
  final String a;
  final String b;
  const AslabAvatarPair(this.a, this.b, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 36,
      child: Stack(
        children: [
          Positioned(left: 0, child: LabAvatar(a)),
          Positioned(left: 28, child: LabAvatar(b)),
        ],
      ),
    );
  }
}

/// "Shift A → Shift B" (dua kolom dengan ikon tukar di tengah).
class AslabSwapRow extends StatelessWidget {
  final (String, String) left;
  final (String, String) right;
  const AslabSwapRow({super.key, required this.left, required this.right});

  Widget _side((String, String) s) => LabColumn(
        gap: 2,
        children: [
          Text(s.$1,
              style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
          Text(s.$2, style: labText(12, w: kBold)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _side(left)),
        const SizedBox(width: 8),
        const LabIcon('arrow_right_left', size: 16, color: ItlgColors.primary),
        const SizedBox(width: 8),
        Expanded(child: _side(right)),
      ],
    );
  }
}

/// Widget lencana nama berkas.
class AslabFilePill extends StatelessWidget {
  final String icon;
  final String text;
  final bool raised;
  final Color background;

  const AslabFilePill({
    super.key,
    required this.icon,
    required this.text,
    this.raised = false,
    this.background = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LabIcon(icon, size: raised ? 12 : 14, color: ItlgColors.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labText(11, w: kMedium)),
        ),
      ],
    );
    if (raised) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ItlgShadows.outline,
        ),
        child: row,
      );
    }
    return InnerShadowBox(
      radius: 12,
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: row,
    );
  }
}

/// Rekap Hadir / Izin / Alpa.
class AslabRekap extends StatelessWidget {
  final int hadir;
  final int izin;
  final int alpa;

  const AslabRekap({
    super.key,
    required this.hadir,
    required this.izin,
    required this.alpa,
  });

  Widget _box(String label, int value, Color color) => Expanded(
        child: InnerShadowBox(
          radius: 12,
          height: 33,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
              Text('$value', style: labText(14, w: kBold, c: color)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _box('Hadir', hadir, LabColors.green),
        const SizedBox(width: 8),
        _box('Izin', izin, ItlgColors.secondary),
        const SizedBox(width: 8),
        _box('Alpa', alpa, ItlgColors.primary),
      ],
    );
  }
}

/// Pilihan status Hadir / Izin / Alpa.
class AslabStatusPicker extends StatelessWidget {
  /// 0 hadir, 1 izin, 2 alpa.
  final int value;
  final ValueChanged<int> onChanged;

  const AslabStatusPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Hadir', 'Izin', 'Alpa'];
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: _StatusBox(label: labels[i], selected: value == i),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusBox extends StatelessWidget {
  final String label;
  final bool selected;
  const _StatusBox({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        selected
            ? Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ItlgColors.primary,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const LabIcon('check', size: 12, color: Colors.white),
              )
            : const InnerShadowBox(
                width: 18,
                height: 18,
                radius: 5,
                color: LabColors.tile,
                shadows: LabShadows.track,
              ),
        const SizedBox(width: 6),
        Text(label,
            style: labText(12,
                w: kBold,
                c: selected ? ItlgColors.primary : ItlgColors.text)),
      ],
    );
    if (selected) {
      return Container(
        height: 34,
        decoration: BoxDecoration(
          color: LabColors.tagRedBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: content,
      );
    }
    return InnerShadowBox(radius: 10, height: 34, child: content);
  }
}

/// Toggle dengan knop putih.
class AslabToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const AslabToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 40,
        height: 22,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? ItlgColors.primary : LabColors.toggleOff,
          borderRadius: BorderRadius.circular(11),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: ItlgShadows.outline,
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu menu di Beranda.
class AslabMenuCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final int badge;
  final VoidCallback onTap;

  const AslabMenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 140),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ItlgColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: ItlgShadows.outline,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LabIconTile(icon),
                if (badge > 0) LabTag.red('$badge'),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: labText(16, w: kBold, c: Colors.black)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
          ],
        ),
      ),
    );
  }
}

/// Kolom nilai rubrik (angka merah yang bisa diubah + "/ maks").
class AslabScoreInput extends StatelessWidget {
  final TextEditingController controller;
  final int max;
  final ValueChanged<String> onChanged;

  const AslabScoreInput({
    super.key,
    required this.controller,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InnerShadowBox(
      radius: 12,
      width: 84,
      height: 33,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              cursorColor: ItlgColors.primary,
              style: labText(14, w: kBold, c: ItlgColors.primary),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: '',
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text('/ $max',
                maxLines: 1,
                softWrap: false,
                style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
          ),
        ],
      ),
    );
  }
}

/// Pill timer sesi berjalan (jam:menit:detik sejak [start]).
class AslabElapsedPill extends StatefulWidget {
  final DateTime start;
  const AslabElapsedPill({super.key, required this.start});

  @override
  State<AslabElapsedPill> createState() => _AslabElapsedPillState();
}

class _AslabElapsedPillState extends State<AslabElapsedPill> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = DateTime.now().difference(widget.start);
    String two(int v) => v.toString().padLeft(2, '0');
    final text =
        '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
    return LabPill(icon: 'clock', text: text);
  }
}

/// Header informasi kode kelas dan nama mata kuliah.
class AslabClassTitle extends StatelessWidget {
  final String kelas;
  final String name;
  const AslabClassTitle({
    super.key,
    this.kelas = 'TIF 3001 - Kelas C',
    this.name = 'Pemrograman Mobile',
  });

  @override
  Widget build(BuildContext context) {
    return LabColumn(
      gap: 6,
      children: [
        Text(kelas, style: labText(16, w: kBold, c: ItlgColors.primaryDark)),
        Text('Praktikum\n$name',
            style: labText(22, w: kBold, c: Colors.black)),
      ],
    );
  }
}
