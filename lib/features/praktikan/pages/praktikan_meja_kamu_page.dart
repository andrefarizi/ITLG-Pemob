import 'package:flutter/material.dart';

import '../../../core/services/lab_desk_sync_service.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../widgets/desk_map.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Meja Kamu-Praktikan".
///
/// Muncul setelah praktikan membooking meja. Dari sini praktikan bisa
/// kembali ke Beranda atau melaporkan kendala alat/software di meja yang
/// sudah dibooking (halaman Laporkan Kerusakan Meja).
class PraktikanMejaKamuPage extends StatelessWidget {
  final PraktikanNav nav;
  const PraktikanMejaKamuPage({super.key, required this.nav});

  @override
  Widget build(BuildContext context) {
    final sync = LabDeskSyncService.instance;
    final s = nav.store;

    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final userKey = AuthController.instance.userIdentifier;
        final n = sync.bookedDeskForUser(userKey) ??
            s.bookedDesk ??
            s.selectedDesk;
        final pc = n.toString().padLeft(2, '0');
        final liveMap = sync.deskStatusMap();
        final taken = sync.takenCount();
        final spec = sync.deskRecord(n)?.spec ??
            'Core i5-12400 • 16 GB • SSD 512 GB';

        return LabSubPage(
          onLogoTap: nav.home,
          onBack: nav.home,
          gap: 24,
          children: [
            LabCard(
              children: [
                const LabOverline(
                    overline: 'Lab Komputer 1', title: 'Meja Kamu'),
                Row(
                  children: [
                    const Flexible(
                      child: LabMeta(
                          icon: 'clock', text: 'Senin • 08:00–09:40 WIB'),
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
              trailing: const LabChip.live('Terbooking'),
            ),
            Text(
              'Meja $n sudah dibooking atas namamu untuk sesi ini. Kalau ada '
              'kendala alat atau software di meja ini, laporkan lewat tombol di '
              'bawah.',
              style: labText(13, c: LabColors.textGrey).copyWith(height: 1.4),
            ),
            LabColumn(
              gap: 12,
              children: [
                LabPrimaryButton(
                  icon: 'check',
                  label: 'Selesai, ke Beranda',
                  large: true,
                  onTap: nav.home,
                ),
                LabOutlineButton(
                  icon: 'triangle_alert',
                  label: 'Laporkan Kendala Meja $n',
                  large: true,
                  onTap: () => nav.laporkanKerusakan(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
