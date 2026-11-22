import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/praktikan_store.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../widgets/aslab_ui.dart';
import 'aslab_praktikum_saya_page.dart';

/// Figma: "Absensi-Aslab".
class AslabAbsensiPage extends StatelessWidget {
  final AslabNav nav;
  const AslabAbsensiPage({super.key, required this.nav});

  @override
  Widget build(BuildContext context) {
    final praktikumSync = PraktikumSyncService.instance;
    final presensiSync = PresensiSyncService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([praktikumSync, presensiSync]),
      builder: (context, _) {
        final session = presensiSync.activeSession;
        final activeCourse = praktikumSync.courseById(session.courseId);
        final records = presensiSync.recordsForMeeting(
            session.courseId, session.meetingNumber);
        final extraHadir =
            records.where((r) => r.status == PrakAttend.hadir).length;
        final totalHadir = (15 + extraHadir).clamp(0, 24);
        final courses = praktikumSync.aslabCourses;

        return LabTabBody(
          children: [
            const LabTitle(
              title: 'Absensi',
              subtitle: 'Presensi praktikan di setiap praktikum yang anda ampu',
            ),
            LabCard(
              children: [
                PrakSpaceRow(
                  left: session.isActive
                      ? const LabChip.live('Sesi Berlangsung')
                      : const LabChip.idle('Sesi Ditutup'),
                  right: AslabElapsedPill(start: session.startedAt),
                ),
                Text(
                  'Praktikum ${activeCourse.name} • Pertemuan ${session.meetingNumber}',
                  style: labText(16, w: kBold, c: Colors.black),
                ),
                LabProgress(
                  label: 'Kehadiran sementara',
                  value: '$totalHadir / 24',
                  fraction: (totalHadir / 24).clamp(0.0, 1.0),
                ),
                LabPrimaryButton(
                  icon: 'qrcode',
                  label: 'Lihat Sesi & QR Presensi',
                  large: true,
                  onTap: () => nav.sesiAktif(context),
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
                AslabCourseGrid(
                  courses: courses,
                  thirdMeta: (c) =>
                      ('statistic_up', 'Rata-rata hadir ${c.rataHadir}'),
                  onTap: (c) => nav.detailAbsensi(context, c),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
