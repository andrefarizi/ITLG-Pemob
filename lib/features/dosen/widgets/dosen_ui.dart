import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../dosen_store.dart';

/// Komponen khusus halaman Dosen Pengampu (Figma: section "04 Dosen
/// Pengampu"). Komponen umum (kartu, chip, tombol, navbar) ada di
/// lib/features/laboran/widgets/laboran_ui.dart.

/// Latar gelap di belakang pop-up dan sheet (#0A0B0C, 40%).
const Color kDosenScrim = Color(0x660A0B0C);

/// Fade 250 ms ease-out, sama dengan transisi overlay di prototipe Figma.
Widget _fade(Animation<double> anim, Widget child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: child,
    );

// =============================================================================
// Pop-up hasil (Figma: "Pop up Nilai Tervalidasi", "Pop up Revisi Terkirim",
// "Pop up Pesan Terkirim", "Pop up Laporan Diunduh")
// =============================================================================

/// Kartu 370 px: ikon 44 px di kotak cekung 80 px, judul Bold 22, pesan
/// Regular 14, tombol merah 50 px. Tidak tertutup saat area gelap diketuk.
Future<void> dosenShowResult(
  BuildContext context, {
  required String icon,
  required String title,
  required String message,
  required String button,
  VoidCallback? onPressed,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: title,
    barrierColor: kDosenScrim,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (dialogContext, anim, _, __) => _fade(
      anim,
      Center(
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
                    InnerShadowBox(
                      width: 80,
                      height: 80,
                      radius: 19.875,
                      shadows: ItlgShadows.innerLarge,
                      child: Center(
                        child: LabIcon(icon,
                            size: 44, color: ItlgColors.primary),
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
                          boxShadow: ItlgShadows.outline,
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
// Sheet pilihan (Figma: "Sheet Pilih Praktikum", "Sheet Pilih Periode")
// =============================================================================

/// Panel bawah #FDFEFE radius atas 24: pegangan 40x4, judul Bold 16, opsi
/// putih 48 px. Mengembalikan indeks yang dipilih (null bila ditutup).
Future<int?> dosenShowPicker(
  BuildContext context, {
  required String title,
  required List<String> options,
  required int selected,
}) {
  return showGeneralDialog<int>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: kDosenScrim,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (sheetContext, anim, _, __) => _fade(
      anim,
      Align(
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

// =============================================================================
// Elemen formulir
// =============================================================================

/// "TIF 3001 - Kelas C" (Bold 16 merah tua) + judul praktikum Bold 22.
class DosenClassTitle extends StatelessWidget {
  final String kelas;
  final String? code;
  final String courseName;
  const DosenClassTitle({
    super.key,
    this.kelas = 'Kom C (C1 & C2)',
    this.code,
    this.courseName = 'Pemrograman Mobile',
  });

  @override
  Widget build(BuildContext context) {
    return LabColumn(
      gap: 6,
      children: [
        Text(code ?? 'TIF 3001 - $kelas',
            style: labText(16, w: kBold, c: ItlgColors.primaryDark)),
        Text('Praktikum\n$courseName',
            style: labText(22, w: kBold, c: Colors.black)),
      ],
    );
  }
}

/// Label Regular 14 + kolom teks 110 px (#F9FAFB, inner shadow).
class DosenTextArea extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;

  const DosenTextArea({
    super.key,
    required this.label,
    required this.controller,
    this.hint = '',
    this.focusNode,
  });

  @override
  State<DosenTextArea> createState() => _DosenTextAreaState();
}

class _DosenTextAreaState extends State<DosenTextArea> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(DosenTextArea oldWidget) {
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
    return LabColumn(
      gap: 8,
      children: [
        Text(
          widget.label,
          style: labText(14, w: FontWeight.w600, c: ItlgColors.text),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 110,
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
              height: 110,
              color: _isFocused ? Colors.white : ItlgColors.field,
              shadows: _isFocused ? const [] : ItlgShadows.inner,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
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
        ),
      ],
    );
  }
}

/// Pilihan bercentang 53 px. Tercentang: kartu putih timbul + kotak merah.
/// Tidak: kartu putih cekung + kotak abu-abu.
class DosenCheckOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool checked;
  final VoidCallback onTap;

  const DosenCheckOption({
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
        checked
            ? Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ItlgColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const LabIcon('check', size: 14, color: Colors.white),
              )
            : const InnerShadowBox(
                width: 22,
                height: 22,
                radius: 6,
                color: LabColors.tile,
                shadows: LabShadows.track,
              ),
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

/// Kolom cari 48 px (cekung) + tombol filter 48 px (timbul).
class DosenSearchField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  /// Ketuk tombol filter (kanan). Null = tombol hanya hiasan.
  final VoidCallback? onFilter;

  /// Ada filter yang sedang aktif (ikon filter berwarna merah).
  final bool filterActive;

  const DosenSearchField({
    super.key,
    required this.hint,
    required this.controller,
    required this.onChanged,
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
                const LabIcon('search', size: 15, color: ItlgColors.textSubtle),
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
              boxShadow: LabShadows.neu,
            ),
            child: LabIcon('settings_horizontal',
                size: 15,
                color:
                    filterActive ? ItlgColors.primary : LabColors.filterIcon),
          ),
        ),
      ],
    );
  }
}

/// Kotak info biru muda (#DEE9F4) dengan ikon 18 px.
class DosenInfoBox extends StatelessWidget {
  final String icon;
  final String text;
  const DosenInfoBox({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LabColors.tagBlueBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          LabIcon(icon, size: 18, color: ItlgColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: labText(12, c: LabColors.blueDark)),
          ),
        ],
      ),
    );
  }
}

/// Tombol nonaktif abu-abu 50 px (#B5B9BC).
class DosenDisabledButton extends StatelessWidget {
  final String icon;
  final String label;
  const DosenDisabledButton(
      {super.key, required this.icon, required this.label});

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
          LabIcon(icon, size: 22, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: labText(16, w: kBold, c: Colors.white)),
        ],
      ),
    );
  }
}

/// Tabel rekap nilai: kolom 130 / 44 / 52 / 60 dengan jarak 8 (lebar 310).
/// Huruf mutu "D" (tidak lulus) memakai tag merah.
class DosenGradeTable extends StatelessWidget {
  final List<DosenGrade> grades;
  final ValueChanged<DosenGrade>? onTapGrade;
  const DosenGradeTable({super.key, required this.grades, this.onTapGrade});

  Widget _row(List<Widget> cells, {VoidCallback? onTap}) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 130, child: cells[0]),
          const SizedBox(width: 8),
          Expanded(flex: 44, child: cells[1]),
          const SizedBox(width: 8),
          Expanded(flex: 52, child: cells[2]),
          const SizedBox(width: 8),
          Expanded(flex: 60, child: cells[3]),
        ],
      ),
    );
    if (onTap == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: row,
    );
  }

  @override
  Widget build(BuildContext context) {
    final head = labText(11, w: kMedium, c: ItlgColors.textSubtle);
    final cell = labText(12, w: kMedium);
    return LabInsetBox(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          _row([
            Text('Praktikan', style: head),
            Text('Tugas', textAlign: TextAlign.center, style: head),
            Text('Presensi', textAlign: TextAlign.center, style: head),
            Text('Akhir', textAlign: TextAlign.right, style: head),
          ]),
          for (final g in grades)
            _row(
              [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labText(12, w: kBold)),
                    const SizedBox(height: 2),
                    Text(g.nim,
                        style: labText(11,
                            w: kMedium, c: ItlgColors.textSubtle)),
                  ],
                ),
                Text(g.tugas, textAlign: TextAlign.center, style: cell),
                Text(g.presensi, textAlign: TextAlign.center, style: cell),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(g.akhir,
                        style: labText(14, w: kBold, c: ItlgColors.primary)),
                    const SizedBox(width: 4),
                    g.lulus ? LabTag.blue(g.huruf) : LabTag.red(g.huruf),
                  ],
                ),
              ],
              onTap: onTapGrade != null ? () => onTapGrade!(g) : null,
            ),
        ],
      ),
    );
  }
}

/// Kembali ke halaman utama Dosen (menutup semua halaman detail).
void dosenPopToShell(BuildContext context) =>
    Navigator.of(context).popUntil((route) => route.isFirst);
