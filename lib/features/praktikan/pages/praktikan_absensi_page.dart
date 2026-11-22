import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Absensi-Praktikan".
class PraktikanAbsensiPage extends StatelessWidget {
  final PraktikanNav nav;
  const PraktikanAbsensiPage({super.key, required this.nav});

  @override
  Widget build(BuildContext context) {
    final sync = PraktikumSyncService.instance;
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final courses = sync.courses;
        return LabTabBody(
          children: [
            const LabTitle(
              title: 'Absensi',
              subtitle:
                  'Rekap kehadiran anda di setiap praktikum Semester Ganjil '
                  '2026/2027',
            ),
            LabCard(
              children: [
                const PrakSpaceRow(
                  left: LabChip.live('Presensi Berlangsung'),
                  right: LabPill(icon: 'calendar', text: 'Minggu ke-5'),
                ),
                Text('Praktikum Pemrograman Mobile',
                    style: labText(16, w: kBold, c: Colors.black)),
                const Row(
                  children: [
                    Flexible(
                      child: LabMeta(
                          icon: 'clock', text: 'Senin • 08:00–09:40 WIB'),
                    ),
                    SizedBox(width: 24),
                    Flexible(
                      child: LabMeta(icon: 'door', text: 'Lab Komputer 1'),
                    ),
                  ],
                ),
                LabPrimaryButton(
                  icon: 'circle_check',
                  label: 'Isi Presensi Sekarang',
                  large: true,
                  onTap: () => nav.presensi(context),
                ),
              ],
            ),
            LabColumn(
              gap: 12,
              children: [
                PrakSpaceRow(
                  left: const LabHeading(
                      icon: 'book_open', text: 'Absensi per Praktikum'),
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
                                ? _AttendanceCard(
                                    course: courses[row + col],
                                    onTap: () => nav.detailAbsensi(
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

/// Kartu 178 x 270 per praktikum.
class _AttendanceCard extends StatelessWidget {
  final PrakCourse course;
  final VoidCallback onTap;
  const _AttendanceCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final total = course.hadir + course.izin + course.alpa;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 270),
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
              children: [
                const LabIconTile('book_open'),
                LabTag.blue('Hadir ${course.hadir} / $total'),
              ],
            ),
            const SizedBox(height: 10),
            Text('Praktikum\n${course.name}',
                style: labText(16, w: kBold, c: Colors.black)),
            const SizedBox(height: 10),
            const PrakDivider(),
            const SizedBox(height: 10),
            LabColumn(
              gap: 6,
              children: [
                LabMeta(icon: 'person', text: course.asisten),
                LabMeta(icon: 'clock', text: course.jadwalAbsensi),
                LabMeta(icon: 'door', text: course.room),
              ],
            ),
            const SizedBox(height: 10),
            const LabProgress(
              label: 'Pertemuan',
              value: '4 / 12',
              fraction: 50 / 150,
            ),
          ],
        ),
      ),
    );
  }
}
