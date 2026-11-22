import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Pilih Metode Presensi-Praktikan".
class PraktikanPilihMetodePage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanPilihMetodePage({super.key, required this.nav});

  @override
  State<PraktikanPilihMetodePage> createState() =>
      _PraktikanPilihMetodePageState();
}

class _PraktikanPilihMetodePageState extends State<PraktikanPilihMetodePage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    PresensiSyncService.instance.refreshFromBackend();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _remainingSeconds(AttendanceSessionRecord session) {
    if (!session.isActive) return 0;
    final totalSec = session.durationMinutes * 60;
    final elapsed = DateTime.now().difference(session.startedAt).inSeconds;
    final rem = totalSec - elapsed;
    return rem > 0 ? rem : 0;
  }

  @override
  Widget build(BuildContext context) {
    final nav = widget.nav;
    final presensiSync = PresensiSyncService.instance;
    final praktikumSync = PraktikumSyncService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([presensiSync, praktikumSync]),
      builder: (context, _) {
        final session = presensiSync.activeSession;
        final course = praktikumSync.courseById(session.courseId);
        final userId = AuthController.instance.userIdentifier;
        final myRec = presensiSync.recordFor(
            session.courseId, session.meetingNumber, userId);
        final alreadyPresent =
            myRec != null && myRec.status == PrakAttend.hadir;
        final remSec = _remainingSeconds(session);

        return LabSubPage(
          onLogoTap: nav.home,
          children: [
            const PrakStepper(step: 0),
            LabCard(
              children: [
                PrakSpaceRow(
                  left: alreadyPresent
                      ? const LabChip.live('Sudah Presensi')
                      : (session.isActive
                          ? const LabChip.live('Presensi Berlangsung')
                          : const LabChip.idle('Sesi Ditutup')),
                  right: LabPill(
                    icon: 'clock',
                    text: session.isActive
                        ? 'Sisa ${prakClock(remSec)}'
                        : 'Sesi Ditutup',
                  ),
                ),
                LabOverline(
                  overline: 'Pertemuan ${session.meetingNumber} • ${course.kelas}',
                  title: 'Praktikum\n${course.name}',
                ),
                const PrakSessionMeta(),
              ],
            ),
            LabColumn(
              gap: 12,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: LabHeading(
                      icon: 'shield_check_outline',
                      text: 'Pilih Cara Verifikasi'),
                ),
                _MethodCard(
                  icon: 'qrcode',
                  title: 'Pindai QR Code',
                  description: 'Arahkan kamera ke QR dinamis yang ditampilkan '
                      'asisten di layar lab.',
                  metaIcon: 'camera',
                  meta: 'Butuh kamera',
                  duration: '± 5 detik',
                  onTap: () {
                    if (!session.isActive) {
                      labToast(
                          context, 'Sesi presensi sudah ditutup oleh asisten');
                      return;
                    }
                    if (!session.allowQr) {
                      labToast(context,
                          'Metode QR tidak diaktifkan pada sesi ini');
                      return;
                    }
                    nav.scanQr(context);
                  },
                ),
                _MethodCard(
                  icon: 'gesture_tap_button',
                  title: 'Tombol Hadir',
                  description:
                      'Tanpa kamera. Tekan tombol hadir, lokasi anda '
                      'dicek berada di area lab.',
                  metaIcon: 'location',
                  meta: 'Butuh lokasi (GPS)',
                  duration: '± 10 detik',
                  onTap: () {
                    if (!session.isActive) {
                      labToast(
                          context, 'Sesi presensi sudah ditutup oleh asisten');
                      return;
                    }
                    if (!session.allowButton) {
                      labToast(context,
                          'Metode Tombol Hadir tidak diaktifkan pada sesi ini');
                      return;
                    }
                    nav.tombolHadir(context);
                  },
                ),
              ],
            ),
            const PrakNotice.info(
              icon: 'signature_freehand',
              text:
                  'Setelah verifikasi berhasil, anda diminta tanda tangan lalu '
                  'presensi dikirim.',
            ),
          ],
        );
      },
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final String metaIcon;
  final String meta;
  final String duration;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.metaIcon,
    required this.meta,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LabCard(
      gap: 12,
      onTap: onTap,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ItlgColors.primary,
                borderRadius: BorderRadius.circular(9),
                boxShadow: LabShadows.neu,
              ),
              child: LabIcon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LabColumn(
                gap: 4,
                children: [
                  Text(title, style: labText(16, w: kBold, c: Colors.black)),
                  Text(description,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const LabIcon('chevron_right', size: 18, color: ItlgColors.primary),
          ],
        ),
        const PrakDivider(),
        Row(
          children: [
            LabMeta(icon: metaIcon, text: meta),
            const SizedBox(width: 16),
            LabMeta(icon: 'clock', text: duration),
          ],
        ),
      ],
    );
  }
}
