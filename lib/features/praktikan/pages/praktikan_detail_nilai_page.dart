import 'package:flutter/material.dart';

import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../shared/profil_data.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Halaman Detail Nilai Praktikan.
class PraktikanDetailNilaiPage extends StatefulWidget {
  final PraktikanNav nav;
  final PrakCourse course;

  const PraktikanDetailNilaiPage({
    super.key,
    required this.nav,
    required this.course,
  });

  @override
  State<PraktikanDetailNilaiPage> createState() =>
      _PraktikanDetailNilaiPageState();
}

class _PraktikanDetailNilaiPageState extends State<PraktikanDetailNilaiPage> {
  /// 0 Semua, 1 Sudah Dinilai, 2 Menunggu.
  int _tab = 0;

  bool _match(PrakGrade g) {
    if (_tab == 1) return g.score != null;
    if (_tab == 2) return g.score == null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final sync = PraktikumSyncService.instance;
    final nilaiSync = NilaiSyncService.instance;
    final nim = ProfilData.praktikan.idValue;
    return ListenableBuilder(
      listenable: Listenable.merge([sync, nilaiSync]),
      builder: (context, _) {
        final c = sync.courseById(widget.course.id);
        final validated = nilaiSync.isCourseValidated(c.id);
        final allGrades = sync.effectiveGradesForCourse(c, nim);
        final graded = allGrades.where((g) => g.score != null).length;
        final items = allGrades.where(_match).toList();
        final avgLabel = sync.effectiveAverageForCourse(c, nim);
        final totalPoints = allGrades.fold<double>(
          0,
          (sum, g) =>
              sum +
              (g.score != null
                  ? (double.tryParse(g.score!.replaceAll(',', '.')) ?? 0)
                  : 0),
        );
        final akumulasiText =
            '${totalPoints % 1 == 0 ? totalPoints.toInt() : totalPoints.toStringAsFixed(1).replaceAll('.', ',')} / ${graded * 100}';
        return LabSubPage(
          onLogoTap: widget.nav.home,
          children: [
            LabCard(
              children: [
                LabColumn(
                  gap: 6,
                  children: [
                    Text(c.kelas,
                        style: labText(16, w: kBold, c: ItlgColors.primaryDark)),
                    Text('Praktikum\n${c.name}',
                        style: labText(22, w: kBold, c: Colors.black)),
                  ],
                ),
                InnerShadowBox(
                  radius: 12,
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: Column(
                    children: [
                      Text('Nilai Rata-rata',
                          style: labText(12, c: ItlgColors.textSubtle)),
                      const SizedBox(height: 4),
                      PrakBigScore(avgLabel),
                      const SizedBox(height: 4),
                      LabMeta(
                        icon: 'clipboard',
                        text: 'Dari $graded modul yang sudah dinilai',
                      ),
                    ],
                  ),
                ),
                LabStatRow(
                  gap: 13,
                  stats: [
                    LabStat(
                        icon: 'trophy',
                        label: 'Akumulasi Nilai',
                        value: graded > 0 ? akumulasiText : c.akumulasi),
                    LabStat(
                        icon: 'clipboard',
                        label: 'Modul Dinilai',
                        value: '$graded / 12'),
                  ],
                ),
              ],
            ),
            LabTabs(
              labels: const ['Semua', 'Sudah Dinilai', 'Menunggu'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            // Semua nilai di dalam satu "Kartu Daftar".
            if (items.isNotEmpty)
              LabListCard(
                children: [
                  for (final g in items)
                    Builder(
                      builder: (_) {
                        final appeal = nilaiSync.appealFor(c.id, g.modul, nim);
                        final sanggahLabel = validated
                            ? 'Nilai Tervalidasi'
                            : (appeal == null
                                ? 'Sanggah Nilai'
                                : (appeal.status == 'resolved'
                                    ? 'Sanggahan Selesai'
                                    : 'Sanggahan Diajukan'));
                        return _GradeCard(
                          grade: g,
                          asisten: c.asisten,
                          sanggahLabel: sanggahLabel,
                          onSanggah: () => widget.nav.sanggah(context, c, g),
                        );
                      },
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _GradeCard extends StatelessWidget {
  final PrakGrade grade;
  final String asisten;
  final String sanggahLabel;
  final VoidCallback onSanggah;

  const _GradeCard({
    required this.grade,
    required this.asisten,
    this.sanggahLabel = 'Sanggah Nilai',
    required this.onSanggah,
  });

  @override
  Widget build(BuildContext context) {
    final waiting = grade.score == null;
    return LabRowCard(
      gap: 16,
      children: [
        PrakSpaceRow(
          left: LabMeta(icon: 'calendar', text: grade.date),
          right: waiting
              ? const LabChip.warn('Menunggu Penilaian')
              : const LabChip.live('Sudah Dinilai'),
        ),
        Row(
          children: [
            PrakNumberTile('${grade.modul}'),
            const SizedBox(width: 13),
            Expanded(
              child: LabColumn(
                gap: 4,
                cross: CrossAxisAlignment.start,
                children: [
                  LabTag.red('Modul ${grade.modul} • Tugas ${grade.modul}'),
                  Text(grade.title,
                      style: labText(16, w: kBold, c: Colors.black)),
                ],
              ),
            ),
            const SizedBox(width: 13),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  waiting ? '–' : grade.score!,
                  style: labText(22,
                      w: kBold,
                      c: waiting ? LabColors.divider : ItlgColors.primary),
                ),
                Text('/ 100',
                    style:
                        labText(11, w: kMedium, c: ItlgColors.textSubtle)),
              ],
            ),
          ],
        ),
        if (waiting)
          LabInsetBox(
            child: Row(
              children: [
                const LabIcon('clock', size: 14, color: LabColors.warnText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nilai dan feedback akan muncul setelah asisten selesai '
                    'memeriksa.',
                    style: labText(12, c: ItlgColors.textMuted),
                  ),
                ),
              ],
            ),
          )
        else
          LabInsetBox(
            child: LabColumn(
              gap: 10,
              children: [
                Row(
                  children: [
                    const LabIcon('chat_bubble',
                        size: 14, color: ItlgColors.secondary),
                    const SizedBox(width: 6),
                    Text('Catatan Asisten', style: labText(12, w: kBold)),
                  ],
                ),
                Text(grade.note ?? '', style: labText(12, c: Colors.black)),
                PrakSpaceRow(
                  left: LabMeta(
                      icon: 'person', text: '$asisten • Asisten Lab'),
                  right: PrakSideLink(sanggahLabel, onTap: onSanggah),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
