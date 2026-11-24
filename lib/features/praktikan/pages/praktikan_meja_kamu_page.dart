import 'package:flutter/material.dart';

import '../../../core/services/lab_desk_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/desk_map.dart';
import '../widgets/praktikan_ui.dart';

/// Halaman Meja Kamu Praktikan.
class PraktikanMejaKamuPage extends StatelessWidget {
  final PraktikanNav nav;
  const PraktikanMejaKamuPage({super.key, required this.nav});

  Future<void> _akhiriMeja(
    BuildContext context, {
    required String labName,
    required int deskNumber,
  }) async {
    final ok = await labShowConfirmDialog(
      context,
      icon: 'stop',
      title: 'Akhiri Pemakaian Meja?',
      message:
          'Meja $deskNumber akan dikosongkan dan bisa dipilih praktikan lain. Pastikan berkas kamu sudah tersimpan.',
      cancelLabel: 'Batal',
      confirmLabel: 'Ya, Akhiri',
    );
    if (!ok || !context.mounted) return;
    final userKey = AuthController.instance.userIdentifier;
    await LabDeskSyncService.instance.releaseDesk(
      labName: labName,
      deskNumber: deskNumber,
      userKey: userKey,
    );
    nav.store.bookedDesk = null;
    if (!context.mounted) return;
    nav.home();
    labToast(context, 'Pemakaian Meja $deskNumber diakhiri dan dikosongkan');
  }

  @override
  Widget build(BuildContext context) {
    final sync = LabDeskSyncService.instance;
    final presensi = PresensiSyncService.instance;
    final praktikum = PraktikumSyncService.instance;
    final s = nav.store;

    return ListenableBuilder(
      listenable: Listenable.merge([sync, presensi, praktikum]),
      builder: (context, _) {
        final session = presensi.activeSession;
        final course = praktikum.courseById(session.courseId);
        final labName = session.labName;
        final userKey = AuthController.instance.userIdentifier;
        final n = sync.bookedDeskForUser(userKey, labName: labName) ??
            s.bookedDesk ??
            s.selectedDesk;
        final pc = n.toString().padLeft(2, '0');
        final liveMap = sync.deskStatusMap(labName: labName);
        final taken = sync.takenCount(labName: labName);
        final deskRec = sync.deskRecord(n, labName: labName);
        final spec = deskRec?.spec ?? 'Core i5-12400 • 16 GB • SSD 512 GB';
        final hasActiveTicket =
            sync.activeTicketForDesk(n, labName: labName) != null;

        return LabSubPage(
          onLogoTap: nav.home,
          onBack: nav.home,
          gap: 24,
          children: [
            LabCard(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: LabTag.blue('Kom C • Sesi C1'),
                ),
                LabOverline(
                  overline: '$labName • ${course.name}',
                  title: 'Meja Kamu',
                ),
                Row(
                  children: [
                    Flexible(
                      child: LabMeta(
                          icon: 'clock', text: course.jadwalAbsensi),
                    ),
                    const SizedBox(width: 24),
                    Flexible(
                      child: LabMeta(
                          icon: 'people_group', text: '$taken / 30 terisi'),
                    ),
                  ],
                ),
              ],
            ),
            LabCard(
              children: [
                const PrakSpaceRow(
                  left: LabSectionTitle(
                      icon: 'desktop_device', text: 'Denah Meja'),
                  right: LabTag.blue('30 PC'),
                ),
                PrakDeskMap(desks: liveMap, selected: n),
                const PrakDeskLegend(selectedLabel: 'Meja Kamu'),
              ],
            ),
            LabListItem(
              leading: const LabIconTile('desktop_device'),
              title: 'Meja $n • PC-$pc',
              subtitle: spec,
              titleSize: 12,
              trailing: (deskRec?.status == PrakDesk.broken || hasActiveTicket)
                  ? const LabChip.danger('Dilaporkan Rusak')
                  : const LabChip.live('Sedang Dipakai'),
            ),
            Text(
              'Meja $n tercatat atas namamu sampai sesi berakhir pukul 09:40. '
              'Kalau PC bermasalah, pindah ke meja lain atau laporkan kendalanya. '
              'Akhiri pemakaian saat praktikum selesai.',
              style: labText(13, c: LabColors.textGrey).copyWith(height: 1.4),
            ),
            LabColumn(
              gap: 12,
              children: [
                LabPrimaryButton(
                  icon: 'home',
                  label: 'Kembali ke Beranda',
                  large: true,
                  onTap: nav.home,
                ),
                LabButtonPair(
                  left: LabOutlineButton(
                    icon: 'arrow_right_left',
                    label: 'Pindah Meja',
                    onTap: () => nav.pilihMejaFromPresensi(),
                  ),
                  right: LabOutlineButton(
                    icon: 'triangle_alert',
                    label: 'Lapor Kendala',
                    onTap: () => nav.laporkanKerusakan(context),
                  ),
                ),
                LabSoftDangerButton(
                  icon: 'stop',
                  label: 'Akhiri Pemakaian Meja',
                  onTap: () => _akhiriMeja(
                    context,
                    labName: labName,
                    deskNumber: n,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
