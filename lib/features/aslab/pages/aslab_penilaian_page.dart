import 'package:flutter/material.dart';

import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';

/// Figma: "Penilaian-Aslab".
class AslabPenilaianPage extends StatefulWidget {
  final AslabNav nav;
  const AslabPenilaianPage({super.key, required this.nav});

  @override
  State<AslabPenilaianPage> createState() => _AslabPenilaianPageState();
}

class _AslabPenilaianPageState extends State<AslabPenilaianPage> {
  /// 0 Perlu Dinilai, 1 Selesai.
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final nav = widget.nav;
    final sync = PraktikumSyncService.instance;
    final nilaiSync = NilaiSyncService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([sync, nilaiSync]),
      builder: (context, _) {
        final courses = sync.courses;
        final totalPending = courses.fold<int>(0, (sum, c) {
          final subs = sync.submissionsForCourse(c.id, 4);
          final pendingExtra = subs.where((s) => s.status != 'graded').length;
          final appeals = nilaiSync.pendingAppealsForCourse(c.id).length;
          return sum + 6 + pendingExtra + appeals;
        });
        final totalGraded = courses.fold<int>(0, (sum, c) {
          final subs = sync.submissionsForCourse(c.id, 4);
          final gradedExtra = subs.where((s) => s.status == 'graded').length;
          return sum + 14 + gradedExtra;
        });

        return LabTabBody(
          children: [
            const LabTitle(
              title: 'Penilaian',
              subtitle: 'Tugas praktikan yang perlu anda evaluasi',
            ),
            LabStatRow(
              stats: [
                LabStat(
                  icon: 'clipboard',
                  label: 'Tugas Aktif',
                  value: '${courses.length}',
                ),
                LabStat(
                  icon: 'clock',
                  label: 'Menunggu',
                  value: '$totalPending',
                ),
                LabStat(
                  icon: 'circle_check',
                  label: 'Dinilai',
                  value: '$totalGraded',
                ),
              ],
            ),
            LabTabs(
              labels: ['Perlu Dinilai (${courses.length})', 'Selesai'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            if (_tab == 0) ...[
              for (final c in courses)
                Builder(
                  builder: (_) {
                    final subs = sync.submissionsForCourse(c.id, 4);
                    final gradedExtra =
                        subs.where((s) => s.status == 'graded').length;
                    final totalSubs = (20 + subs.length).clamp(1, 24);
                    final gradedCount = (14 + gradedExtra).clamp(0, totalSubs);
                    return _TaskCard(
                      tag: 'Tugas 4',
                      title: c.tugasTitle.replaceFirst('Tugas 4 : ', ''),
                      course: 'Praktikum ${c.name} • Kom C (C1 & C2)',
                      deadline: c.tugasDeadline,
                      done: '$gradedCount / $totalSubs',
                      fraction: (gradedCount / totalSubs).clamp(0.0, 1.0),
                      onTap: () => nav.evaluasiTugas(context, courseId: c.id),
                    );
                  },
                ),
            ] else
              for (final c in courses.take(2))
                _TaskCard(
                  tag: 'Tugas 3',
                  title: c.grades.length > 1 ? c.grades[1].title : c.modulTitle,
                  course: 'Praktikum ${c.name} • Kom C (C1 & C2)',
                  done: '24 / 24',
                  fraction: 1,
                  finished: true,
                  onTap: () => nav.evaluasiTugas(context, courseId: c.id),
                ),
          ],
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String tag;
  final String title;
  final String course;
  final String deadline;
  final String done;
  final double fraction;
  final bool finished;
  final VoidCallback onTap;

  const _TaskCard({
    required this.tag,
    required this.title,
    required this.course,
    this.deadline = 'Deadline 29 Sep, 10:30',
    required this.done,
    required this.fraction,
    required this.onTap,
    this.finished = false,
  });

  @override
  Widget build(BuildContext context) {
    return LabCard(
      children: [
        PrakSpaceRow(
          left: Align(
            alignment: Alignment.centerLeft,
            child: LabTag.red(tag),
          ),
          right: finished
              ? const LabChip.live('Selesai Dinilai')
              : LabMeta(icon: 'clock', text: deadline),
        ),
        Text(title, style: labText(16, w: kBold, c: Colors.black)),
        LabMeta(icon: 'book_open', text: course),
        LabProgress(
          label: 'Sudah dinilai',
          value: done,
          fraction: fraction,
          color: finished ? LabColors.green : ItlgColors.primary,
        ),
        finished
            ? LabOutlineButton(
                icon: 'clipboard', label: 'Lihat Evaluasi', onTap: onTap)
            : LabPrimaryButton(
                icon: 'clipboard', label: 'Evaluasi Tugas', onTap: onTap),
      ],
    );
  }
}
