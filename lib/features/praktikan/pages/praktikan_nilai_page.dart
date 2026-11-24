import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../shared/profil_data.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Halaman Nilai Praktikan.
class PraktikanNilaiPage extends StatelessWidget {
  final PraktikanNav nav;
  const PraktikanNilaiPage({super.key, required this.nav});

  @override
  Widget build(BuildContext context) {
    final sync = PraktikumSyncService.instance;
    final nim = ProfilData.praktikan.idValue;
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final courses = sync.courses;
        final graded = courses.fold<int>(
          0,
          (s, c) =>
              s +
              sync
                  .effectiveGradesForCourse(c, nim)
                  .where((g) => g.score != null)
                  .length,
        );
        final pending = courses.fold<int>(
          0,
          (s, c) =>
              s +
              sync
                  .effectiveGradesForCourse(c, nim)
                  .where((g) => g.score == null)
                  .length,
        );
        final avgSum = courses.fold<double>(
          0,
          (s, c) =>
              s +
              (double.tryParse(sync
                      .effectiveAverageForCourse(c, nim)
                      .replaceAll(',', '.')) ??
                  0),
        );
        final avgText = courses.isEmpty
            ? '0,0'
            : (avgSum / courses.length).toStringAsFixed(1).replaceAll('.', ',');

        return LabTabBody(
          children: [
            const LabTitle(
              title: 'Nilai',
              subtitle: 'Ringkasan nilai praktikum Semester Ganjil 2026/2027',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              decoration: BoxDecoration(
                color: ItlgColors.surfaceDark,
                borderRadius: BorderRadius.circular(24),
                boxShadow: ItlgShadows.outline,
              ),
              child: Column(
                children: [
                  const PrakIconWell('trophy'),
                  const SizedBox(height: 13),
                  Text('Nilai Rata-rata Anda',
                      style: labText(14, c: ItlgColors.textMuted)),
                  const SizedBox(height: 2),
                  PrakBigScore(avgText),
                  const SizedBox(height: 13),
                  LabStatRow(
                    stats: [
                      LabStat(
                          icon: 'book_open',
                          label: 'Praktikum',
                          value: '${courses.length}'),
                      LabStat(
                          icon: 'clipboard',
                          label: 'Dinilai',
                          value: '$graded'),
                      LabStat(
                          icon: 'clock', label: 'Menunggu', value: '$pending'),
                    ],
                  ),
                ],
              ),
            ),
            LabColumn(
              gap: 12,
              children: [
                PrakSpaceRow(
                  left: const LabHeading(
                      icon: 'book_open', text: 'Nilai per Praktikum'),
                  right: PrakSideLink('${courses.length} Praktikum'),
                ),
                for (var row = 0; row < courses.length; row += 2) ...[
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var col = 0; col < 2; col++) ...[
                          if (col > 0) const SizedBox(width: 14),
                          Expanded(
                            child: (row + col) < courses.length
                                ? _GradeCard(
                                    course: courses[row + col],
                                    onTap: () => nav.detailNilai(
                                        context, courses[row + col]),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Kartu per praktikum.
class _GradeCard extends StatelessWidget {
  final PrakCourse course;
  final VoidCallback onTap;
  const _GradeCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sync = PraktikumSyncService.instance;
    final nim = ProfilData.praktikan.idValue;
    final grades = sync.effectiveGradesForCourse(course, nim);
    final gradedCount = grades.where((g) => g.score != null).length;
    final totalCount = grades.isEmpty ? 4 : grades.length;
    final avgLabel = sync.effectiveAverageForCourse(course, nim);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 218),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const LabIconTile('book_open'),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(avgLabel,
                        style: labText(22, w: kBold, c: ItlgColors.primary)),
                    Text('rata-rata',
                        style: labText(11,
                            w: kMedium, c: ItlgColors.textSubtle)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Praktikum\n${course.name}',
                style: labText(16, w: kBold, c: Colors.black)),
            const SizedBox(height: 10),
            const PrakDivider(),
            const SizedBox(height: 10),
            LabMeta(icon: 'person', text: course.asisten),
            const SizedBox(height: 10),
            LabProgress(
              label: 'Dinilai',
              value: '$gradedCount / $totalCount',
              fraction: (gradedCount / totalCount).clamp(0.0, 1.0),
              color: ItlgColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
