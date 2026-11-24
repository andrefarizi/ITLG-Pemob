import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Halaman Absensi Praktikan.
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
        // Jadwal ringkas: "Sen, C1 08:00–09:40 | C2 …" → "Sen 08:00".
        String shortSchedule(String jadwal) {
          final m = RegExp(r'^(\w+).*?(\d{2}:\d{2})').firstMatch(jadwal);
          return m == null ? jadwal : '${m.group(1)} ${m.group(2)}';
        }

        return LabTabBody(
          children: [
            const LabTitle(
              title: 'Absensi',
              subtitle: 'Rekap kehadiran per praktikum',
            ),
            // Sesi presensi aktif: satu kartu ringkas.
            LabCard(
              gap: 12,
              children: [
                PrakSpaceRow(
                  left: !session.isActive
                      ? const LabChip.idle('Sesi Ditutup')
                      : (alreadyPresent
                          ? const LabChip.live('Sudah Presensi')
                          : const LabChip.live('Presensi Berlangsung')),
                  right: LabPill(
                      icon: 'calendar',
                      text: 'Pertemuan ${session.meetingNumber}'),
                ),
                Text(activeCourse.name,
                    style: labText(16, w: kBold, c: Colors.black)),
                LabMeta(
                  icon: 'door',
                  text:
                      '${session.labName} • ${shortSchedule(activeCourse.jadwalAbsensi)}',
                ),
                LabPrimaryButton(
                  icon: 'circle_check',
                  label: !session.isActive
                      ? 'Sesi Ditutup'
                      : (alreadyPresent ? 'Pilih Meja' : 'Isi Presensi'),
                  large: true,
                  onTap: () {
                    if (!session.isActive) {
                      labToast(context, 'Sesi presensi sudah ditutup',
                          error: true);
                    } else if (alreadyPresent) {
                      nav.pilihMejaFromPresensi();
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
                const LabHeading(icon: 'book_open', text: 'Per Praktikum'),
                // Daftar kartu ringkas: nama + rekap singkat + persentase.
                for (final course in courses)
                  _AttendanceRow(
                    course: course,
                    summary: presensiSync.summaryForCourse(course, userId),
                    onTap: () => nav.detailAbsensi(context, course),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Kartu ringkas per praktikum (satu baris).
class _AttendanceRow extends StatelessWidget {
  final PrakCourse course;
  final ({int hadir, int izin, int alpa, int doneMeetings}) summary;
  final VoidCallback onTap;
  const _AttendanceRow({
    required this.course,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = summary.hadir + summary.izin + summary.alpa;
    final pct = total == 0 ? null : (summary.hadir * 100 / total).round();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: ItlgColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: ItlgShadows.outline,
        ),
        child: Row(
          children: [
            const LabIconTile('book_open'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labText(14, w: kBold, c: Colors.black)),
                  const SizedBox(height: 4),
                  Text(
                    'Hadir ${summary.hadir} • Izin ${summary.izin} • Alpa ${summary.alpa}',
                    style: labText(12, c: ItlgColors.textSubtle),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            pct == null
                ? LabTag.blue('-')
                : (pct >= 75 ? LabTag.blue('$pct%') : LabTag.red('$pct%')),
            const SizedBox(width: 6),
            const LabIcon('chevron_right',
                size: 16, color: ItlgColors.primary),
          ],
        ),
      ),
    );
  }
}
