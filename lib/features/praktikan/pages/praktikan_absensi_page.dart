import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
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
    final presensiSync = PresensiSyncService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([sync, presensiSync]),
      builder: (context, _) {
        final courses = sync.courses;
        final session = presensiSync.activeSession;
        final activeCourse = sync.courseById(session.courseId);
        final userId = AuthController.instance.userIdentifier;
        final myRec = presensiSync.recordFor(
            session.courseId, session.meetingNumber, userId);
        final alreadyPresent =
            myRec != null && myRec.status == PrakAttend.hadir;
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
                PrakSpaceRow(
                  left: alreadyPresent
                      ? const LabChip.live('Sudah Presensi')
                      : (session.isActive
                          ? const LabChip.live('Presensi Berlangsung')
                          : const LabChip.idle('Sesi Ditutup')),
                  right: LabPill(
                      icon: 'calendar',
                      text: 'Minggu ke-${session.meetingNumber}'),
                ),
                Text('Praktikum ${activeCourse.name}',
                    style: labText(16, w: kBold, c: Colors.black)),
                Row(
                  children: [
                    Flexible(
                      child: LabMeta(
                          icon: 'clock', text: activeCourse.jadwalAbsensi),
                    ),
                    const SizedBox(width: 24),
                    Flexible(
                      child: LabMeta(icon: 'door', text: session.labName),
                    ),
                  ],
                ),
                LabPrimaryButton(
                  icon: 'circle_check',
                  label: alreadyPresent
                      ? 'Lihat / Pilih Meja'
                      : (session.isActive
                          ? 'Isi Presensi Sekarang'
                          : 'Sesi Ditutup'),
                  large: true,
                  onTap: () {
                    if (alreadyPresent) {
                      nav.pilihMejaFromPresensi();
                    } else if (!session.isActive) {
                      labToast(
                          context, 'Sesi presensi sedang ditutup oleh asisten');
                    } else {
                      nav.presensi(context);
                    }
                  },
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
                                    summary: presensiSync.summaryForCourse(
                                        courses[row + col], userId),
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
  final ({int hadir, int izin, int alpa, int doneMeetings}) summary;
  final VoidCallback onTap;
  const _AttendanceCard({
    required this.course,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = summary.hadir + summary.izin + summary.alpa;
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
                LabTag.blue('Hadir ${summary.hadir} / $total'),
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
            LabProgress(
              label: 'Pertemuan',
              value: '${summary.doneMeetings} / 12',
              fraction: (summary.doneMeetings / 12).clamp(0.0, 1.0),
            ),
          ],
        ),
      ),
    );
  }
}
