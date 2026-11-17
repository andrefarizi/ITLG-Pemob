import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Detail Praktikum-Praktikan (Kuis & Rating)".
class PraktikanDetailPraktikumPage extends StatefulWidget {
  final PraktikanNav nav;
  final PrakCourse course;

  const PraktikanDetailPraktikumPage({
    super.key,
    required this.nav,
    required this.course,
  });

  @override
  State<PraktikanDetailPraktikumPage> createState() =>
      _PraktikanDetailPraktikumPageState();
}

class _PraktikanDetailPraktikumPageState
    extends State<PraktikanDetailPraktikumPage> {
  /// 0 Semua Pertemuan, 1 Materi, 2 Tugas.
  int _tab = 0;

  static const List<String> _labels = ['Semua Pertemuan', 'Materi', 'Tugas'];
  static const List<double> _widths = [144, 86, 86];

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final nav = widget.nav;
    return LabSubPage(
      onLogoTap: nav.home,
      children: [
        _header(c),
        Row(
          children: [
            for (var i = 0; i < _labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              _FixedTab(
                label: _labels[i],
                width: _widths[i],
                selected: i == _tab,
                onTap: () => setState(() => _tab = i),
              ),
            ],
          ],
        ),
        LabColumn(
          gap: 16,
          children: [
            _MeetingCard(
              course: c,
              tab: _tab,
              postTest: false,
              onMateri: () => nav.detailMateri(context),
              onTugas: () => nav.editTugas(context),
              onKuis: () => nav.kuis(context),
            ),
            _MeetingCard(
              course: c,
              tab: _tab,
              postTest: true,
              onMateri: () => nav.detailMateri(context),
              onTugas: () => nav.editTugas(context),
              onKuis: () => nav.hasilKuis(context),
            ),
          ],
        ),
        LabCard(
          children: [
            const PrakSpaceRow(
              left: LabSectionTitle(icon: 'star', text: 'Rating Asisten'),
              right: LabTag.grey('4 / 12 pertemuan'),
            ),
            Text(
              'Penilaian asisten dibuka setelah seluruh pertemuan praktikum '
              'selesai.',
              style: labText(12, c: ItlgColors.textMuted),
            ),
            LabOutlineButton(
              icon: 'star',
              label: 'Beri Rating Asisten',
              large: true,
              onTap: () => nav.penilaianAsisten(context, c),
            ),
          ],
        ),
      ],
    );
  }

  // Kartu judul (370 x 268).
  Widget _header(PrakCourse c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 23, 13, 28),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ItlgShadows.outline,
      ),
      child: LabColumn(
        gap: 16,
        children: [
          LabColumn(
            gap: 6,
            children: [
              Text(c.kelas,
                  style: labText(16, w: kBold, c: ItlgColors.primaryDark)),
              Text('Praktikum \n${c.name}',
                  style: labText(22, w: kBold, c: Colors.black)),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  icon: 'm_person_small',
                  iconSize: 9.3,
                  iconColor: PrakColors.mutedRed,
                  label: 'Koordinator',
                  value: c.asisten,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: _InfoBox(
                  icon: 'm_clock',
                  iconSize: 11.7,
                  iconColor: ItlgColors.secondary,
                  label: 'Waktu',
                  value: c.jadwalDetail,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: LabColumn(
              gap: 4,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Pertemuan',
                          style: labText(16,
                              w: kBold, c: ItlgColors.textSubtle)),
                    ),
                    Text('4 / 12',
                        style: labText(16, w: kBold, c: PrakColors.ink)),
                  ],
                ),
                const PrakTrack(
                    fraction: 227.1 / 341, color: ItlgColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kotak cekung 64 px: label kecil + nilai Bold 14.
class _InfoBox extends StatelessWidget {
  final String icon;
  final double iconSize;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoBox({
    required this.icon,
    required this.iconSize,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return InnerShadowBox(
      radius: 12,
      height: 64,
      color: ItlgColors.surfaceDark,
      padding: const EdgeInsets.fromLTRB(15, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LabIcon(icon, size: iconSize, color: iconColor),
              const SizedBox(width: 6),
              Text(label,
                  style: labText(12, w: kMedium, c: PrakColors.ink2)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labText(14, w: kBold)),
        ],
      ),
    );
  }
}

/// Tab lebar tetap (144 / 86 / 86) seperti di Figma.
class _FixedTab extends StatelessWidget {
  final String label;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  const _FixedTab({
    required this.label,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: width,
        height: 39,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? ItlgColors.primary : LabColors.chipIdle,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? ItlgShadows.primary : ItlgShadows.outline,
        ),
        child: Text(
          label,
          maxLines: 1,
          style: labText(12,
              w: kBold,
              c: selected ? ItlgColors.surfaceWhite : ItlgColors.text),
        ),
      ),
    );
  }
}

/// Kartu pertemuan (370 lebar): tanggal, judul modul, deskripsi, lalu kotak
/// Materi, Tugas, dan Kuis. Isi kotak mengikuti tab yang dipilih.
class _MeetingCard extends StatelessWidget {
  final PrakCourse course;
  final int tab;

  /// Kartu kedua di Figma: tugas dengan deadline & post-test yang sudah
  /// dikerjakan.
  final bool postTest;
  final VoidCallback onMateri;
  final VoidCallback onTugas;
  final VoidCallback onKuis;

  const _MeetingCard({
    required this.course,
    required this.tab,
    required this.postTest,
    required this.onMateri,
    required this.onTugas,
    required this.onKuis,
  });

  @override
  Widget build(BuildContext context) {
    final showMateri = tab == 0 || tab == 1;
    final showTugas = tab == 0 || tab == 2;
    final showKuis = tab == 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 26, 19, 21),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ItlgShadows.outline,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const LabIcon('m_clock',
                  size: 11.7, color: ItlgColors.textSubtle),
              const SizedBox(width: 6),
              Text('Sen, 29 September 2026',
                  style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              PrakBookTile(
                color: ItlgColors.primary,
                child: Text('4',
                    style: labText(16, w: kBold, c: Colors.white)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text('Modul 4 : \n${course.modulTitle}',
                    style: labText(16, w: kBold, c: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(course.modulDesc, style: labText(12, c: Colors.black)),
          if (showMateri) ...[
            const SizedBox(height: 15),
            _materiBox(),
          ],
          if (showTugas) ...[
            SizedBox(height: showMateri ? 8 : 15),
            _tugasBox(),
          ],
          if (showKuis) ...[
            const SizedBox(height: 8),
            _kuisBox(),
          ],
        ],
      ),
    );
  }

  Widget _materiBox() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onMateri,
      child: InnerShadowBox(
        radius: 12,
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 15, 13, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                const PrakFileIcon(
                  icon: 'book_open_solid',
                  color: ItlgColors.secondary,
                  iconSize: 17.9,
                  radius: 8.6,
                  shadows: PrakShadows.outlineSmall,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PrakTag17('Materi'),
                      const SizedBox(height: 6),
                      Text(course.materiTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              labText(12, w: kSemiBold, c: Colors.black)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: 116,
              height: 24,
              decoration: BoxDecoration(
                color: ItlgColors.surfaceDark,
                borderRadius: BorderRadius.circular(2),
                boxShadow: ItlgShadows.outline,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LabIcon('eye', size: 16, color: LabColors.blueDark),
                  const SizedBox(width: 7),
                  Text(
                    'Lihat Materi',
                    style: labText(12, w: kMedium, c: PrakColors.linkBlue)
                        .copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tugasBox() {
    return InnerShadowBox(
      radius: 12,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 11, 15, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PrakWarnChipWide('Belum Dikumpulkan', italic: postTest),
          const SizedBox(height: 8),
          Row(
            children: [
              const PrakFileIcon(
                color: ItlgColors.primaryDark,
                radius: 8.6,
                shadows: PrakShadows.outlineSmall,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PrakTag17('Tugas', red: true),
                    const SizedBox(height: 6),
                    Text(course.tugasTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labText(12, w: kSemiBold, c: Colors.black)),
                    if (postTest) ...[
                      const SizedBox(height: 6),
                      Text('Deadline : 10:30 WIB , 29 Sep 2026',
                          style: labText(10, c: Colors.black)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrakPlainButton('Kumpulkan Tugas', onTap: onTugas),
        ],
      ),
    );
  }

  Widget _kuisBox() {
    return InnerShadowBox(
      radius: 12,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: LabColumn(
        gap: 10,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: postTest
                ? const LabChip.live('Sudah Dikerjakan')
                : const LabChip.warn('Belum Dikerjakan'),
          ),
          Row(
            children: [
              const PrakFileIcon(icon: 'question'),
              const SizedBox(width: 8),
              Expanded(
                child: LabColumn(
                  gap: 6,
                  cross: CrossAxisAlignment.start,
                  children: [
                    const LabTag.blue('Kuis'),
                    Text(postTest ? course.postTest : course.preTest,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labText(12, w: kBold)),
                    Text(
                      postTest
                          ? '10 soal • Nilai 80 / 100'
                          : '10 soal • 10 menit • dibuat asisten',
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle),
                    ),
                  ],
                ),
              ),
            ],
          ),
          postTest
              ? LabOutlineButton(
                  icon: 'eye', label: 'Lihat Hasil Kuis', onTap: onKuis)
              : PrakTrailingButton(
                  label: 'Kerjakan Kuis', icon: 'arrow_right', onTap: onKuis),
        ],
      ),
    );
  }
}
