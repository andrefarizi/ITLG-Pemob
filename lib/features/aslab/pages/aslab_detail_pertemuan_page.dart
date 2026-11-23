import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';

/// Figma: "Detail Pertemuan-Aslab" (node 5703:2957).
class AslabDetailPertemuanPage extends StatelessWidget {
  final AslabNav nav;
  final AslabMeeting meeting;
  final String courseId;

  const AslabDetailPertemuanPage({
    super.key,
    required this.nav,
    required this.meeting,
    this.courseId = 'pemob',
  });

  @override
  Widget build(BuildContext context) {
    final sync = PraktikumSyncService.instance;
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final course = sync.courseById(courseId);
        final live = sync.meetingFor(courseId, meeting.number);
        final mNum = meeting.number;
        final dateText = live != null ? live.date.split(' • ').first : meeting.date;
        final topic = live != null
            ? live.module.split(' • ').last
            : meeting.title.replaceFirst('Pertemuan $mNum :\n', '');
        final modulTitle = (live != null && live.materiTitle.isNotEmpty)
            ? live.materiTitle
            : (mNum == 4 ? course.materiTitle : 'Materi Pertemuan $mNum');
        final modulFile = (live != null && live.materiFile.isNotEmpty)
            ? live.materiFile
            : course.materiFile;
        final hasTugas =
            (live != null && live.tugasTitle.isNotEmpty) || mNum <= 4;
        final tugasTitle = (live != null && live.tugasTitle.isNotEmpty)
            ? live.tugasTitle
            : (mNum == 4 ? course.tugasTitle : 'Tugas $mNum');
        final tugasDeadline = (live != null && live.tugasDeadline.isNotEmpty)
            ? live.tugasDeadline
            : course.tugasDeadline;
        final subsCount =
            (20 + sync.submissionsForCourse(courseId, mNum).length).clamp(0, 24);
        final hasKuis =
            (live != null && live.kuisTitle.isNotEmpty) || mNum <= 4;
        final kuisTitle = (live != null && live.kuisTitle.isNotEmpty)
            ? live.kuisTitle
            : course.preTest;
        final qCount = sync.questionsForCourse(courseId).length;
        final attemptCount = (22 +
                sync.allQuizAttempts
                    .where((q) => q.courseId == courseId && q.meetingNumber == mNum)
                    .length)
            .clamp(0, 24);

        return LabSubPage(
          onLogoTap: nav.home,
          children: [
            // Judul Pertemuan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LabIcon('calendar',
                          size: 12, color: Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text(
                        dateText,
                        style:
                            labText(11, w: kMedium, c: const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      PrakNumberTile('$mNum'),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          'Pertemuan $mNum :\n$topic',
                          style: labText(16, w: kBold, c: Colors.black)
                              .copyWith(height: 1.2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bagian Modul
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modul',
                  style: labText(16, w: kBold, c: const Color(0xFF0A0B0C)),
                ),
                const SizedBox(height: 12),
                LabCard(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF0F3),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const LabIcon('book_open',
                              size: 20, color: ItlgColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDEE9F4),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Modul',
                                  style: labText(10,
                                      w: kSemiBold,
                                      c: const Color(0xFF2369B7)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                modulTitle,
                                style: labText(12,
                                    w: kBold, c: const Color(0xFF0A0B0C)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${modulFile.isNotEmpty ? modulFile : 'PDF • 3,2 MB'} • dilihat 21 / 24',
                                style: labText(11,
                                    w: kMedium, c: const Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: LabOutlineButton(
                            icon: 'pencil',
                            label: 'Edit Modul',
                            onTap: () => nav.editModul(context,
                                courseId: courseId, meetingNumber: mNum),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LabPrimaryButton(
                            icon: 'eye',
                            label: 'Detail Modul',
                            onTap: () => nav.detailModul(context,
                                courseId: courseId, meetingNumber: mNum),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Bagian Tugas
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tugas',
                  style: labText(16, w: kBold, c: const Color(0xFF0A0B0C)),
                ),
                const SizedBox(height: 12),
                LabCard(
                  children: !hasTugas
                      ? [
                          Text(
                            'Belum ada tugas di pertemuan ini.',
                            style: labText(12, c: ItlgColors.textMuted),
                          ),
                          LabPrimaryButton(
                            icon: 'plus',
                            label: 'Tambah Tugas Pertemuan Ini',
                            onTap: () => nav.tambahMateri(context,
                                kind: 1,
                                courseId: courseId,
                                meetingNumber: mNum),
                          ),
                        ]
                      : [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF0F3),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const LabIcon('clipboard',
                                    size: 20, color: ItlgColors.primary),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEDDADA),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Tugas',
                                        style: labText(10,
                                            w: kSemiBold,
                                            c: const Color(0xFF850909)),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tugasTitle,
                                      style: labText(12,
                                          w: kBold,
                                          c: const Color(0xFF0A0B0C)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$tugasDeadline • $subsCount / 24 terkumpul',
                                      style: labText(11,
                                          w: kMedium,
                                          c: const Color(0xFF6B7280)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: LabOutlineButton(
                                  icon: 'pencil',
                                  label: 'Edit Tugas',
                                  onTap: () => nav.editTugas(context,
                                      courseId: courseId, meetingNumber: mNum),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: LabPrimaryButton(
                                  icon: 'clipboard',
                                  label: 'Evaluasi Tugas',
                                  onTap: () => nav.evaluasiTugas(context,
                                      courseId: courseId, meetingNumber: mNum),
                                ),
                              ),
                            ],
                          ),
                        ],
                ),
              ],
            ),

            // Bagian Kuis
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kuis',
                  style: labText(16, w: kBold, c: const Color(0xFF0A0B0C)),
                ),
                const SizedBox(height: 12),
                LabCard(
                  children: !hasKuis
                      ? [
                          Text(
                            'Belum ada kuis di pertemuan ini.',
                            style: labText(12, c: ItlgColors.textMuted),
                          ),
                          LabPrimaryButton(
                            icon: 'plus',
                            label: 'Tambah Kuis Pertemuan Ini',
                            onTap: () => nav.tambahMateri(context,
                                kind: 2,
                                courseId: courseId,
                                meetingNumber: mNum),
                          ),
                        ]
                      : [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF0F3),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const LabIcon('question',
                                    size: 20, color: ItlgColors.primary),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF0F3),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Kuis',
                                        style: labText(10,
                                            w: kSemiBold,
                                            c: const Color(0xFF6B7280)),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      kuisTitle,
                                      style: labText(12,
                                          w: kBold,
                                          c: const Color(0xFF0A0B0C)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$qCount soal • 10 menit • $attemptCount / 24 mengerjakan',
                                      style: labText(11,
                                          w: kMedium,
                                          c: const Color(0xFF6B7280)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: LabOutlineButton(
                                  icon: 'pencil',
                                  label: 'Edit Kuis',
                                  onTap: () => nav.tambahMateri(context,
                                      kind: 2,
                                      courseId: courseId,
                                      meetingNumber: mNum),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: LabPrimaryButton(
                                  icon: 'eye',
                                  label: 'Lihat Hasil',
                                  onTap: () => nav.hasilKuis(context,
                                      courseId: courseId, meetingNumber: mNum),
                                ),
                              ),
                            ],
                          ),
                        ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
