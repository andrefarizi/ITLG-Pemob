import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Nilai-Praktikan".
class PraktikanNilaiPage extends StatelessWidget {
  final PraktikanNav nav;
  const PraktikanNilaiPage({super.key, required this.nav});

  @override
  Widget build(BuildContext context) {
    final store = nav.store;
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
              const PrakBigScore('86,4'),
              const SizedBox(height: 13),
              const LabStatRow(
                stats: [
                  LabStat(icon: 'book_open', label: 'Praktikum', value: '2'),
                  LabStat(icon: 'clipboard', label: 'Dinilai', value: '6'),
                  LabStat(icon: 'clock', label: 'Menunggu', value: '2'),
                ],
              ),
            ],
          ),
        ),
        LabColumn(
          gap: 12,
          children: [
            const PrakSpaceRow(
              left: LabHeading(icon: 'book_open', text: 'Nilai per Praktikum'),
              right: PrakSideLink('2 Praktikum'),
            ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _GradeCard(
                      course: store.mobile,
                      onTap: () => nav.detailNilai(context, store.mobile),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _GradeCard(
                      course: store.desain,
                      onTap: () => nav.detailNilai(context, store.desain),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Kartu 178 x 218 per praktikum.
class _GradeCard extends StatelessWidget {
  final PrakCourse course;
  final VoidCallback onTap;
  const _GradeCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                    Text(course.nilaiRata,
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
            const LabProgress(
              label: 'Dinilai',
              value: '3 / 4',
              fraction: 113 / 150,
              color: ItlgColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
