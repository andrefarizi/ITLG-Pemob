import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';

/// Figma: "Detail Pertemuan-Aslab" (node 5703:2957).
class AslabDetailPertemuanPage extends StatelessWidget {
  final AslabNav nav;
  final AslabMeeting meeting;

  const AslabDetailPertemuanPage({
    super.key,
    required this.nav,
    required this.meeting,
  });

  @override
  Widget build(BuildContext context) {
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
                  const LabIcon('calendar', size: 12, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text(
                    meeting.date,
                    style: labText(11, w: kMedium, c: const Color(0xFF6B7280)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  PrakNumberTile('${meeting.number}'),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      'Pertemuan ${meeting.number} :\n${meeting.title.replaceFirst('Pertemuan ${meeting.number} : ', '')}',
                      style: labText(16, w: kBold, c: Colors.black).copyWith(height: 1.2),
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
                      child: const LabIcon('book_open', size: 20, color: ItlgColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDEE9F4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Modul',
                              style: labText(10, w: kSemiBold, c: const Color(0xFF2369B7)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Modul ${meeting.number} : Flutter State Management',
                            style: labText(12, w: kBold, c: const Color(0xFF0A0B0C)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PDF • 3,2 MB • dilihat 21 / 24',
                            style: labText(11, w: kMedium, c: const Color(0xFF6B7280)),
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
                        onTap: () => nav.editModul(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LabPrimaryButton(
                        icon: 'view',
                        label: 'Detail Modul',
                        onTap: () => nav.detailModul(context),
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
                      child: const LabIcon('clipboard', size: 20, color: ItlgColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDDADA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Tugas',
                              style: labText(10, w: kSemiBold, c: const Color(0xFF850909)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tugas ${meeting.number} : Aplikasi Counter',
                            style: labText(12, w: kBold, c: const Color(0xFF0A0B0C)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Deadline 29 Sep, 10:30 • 20 / 24 terkumpul',
                            style: labText(11, w: kMedium, c: const Color(0xFF6B7280)),
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
                        onTap: () => nav.editTugas(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LabPrimaryButton(
                        icon: 'clipboard',
                        label: 'Evaluasi Tugas',
                        onTap: () => nav.evaluasiTugas(context),
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
                      child: const LabIcon('question', size: 20, color: ItlgColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF0F3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Kuis',
                              style: labText(10, w: kSemiBold, c: const Color(0xFF6B7280)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pre-Test Modul ${meeting.number}',
                            style: labText(12, w: kBold, c: const Color(0xFF0A0B0C)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '10 soal • 10 menit • 22 / 24 mengerjakan',
                            style: labText(11, w: kMedium, c: const Color(0xFF6B7280)),
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
                        onTap: () => nav.tambahMateri(context, kind: 2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LabPrimaryButton(
                        icon: 'view',
                        label: 'Lihat Hasil',
                        onTap: () => nav.hasilKuis(context),
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
  }
}
