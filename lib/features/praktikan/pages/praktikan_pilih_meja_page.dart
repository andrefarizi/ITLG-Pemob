import 'package:flutter/material.dart';

import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/desk_map.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Pilih Meja-Praktikan".
///
/// Alur: Pop up Presensi Berhasil → Pilih Meja → Booking → Meja Kamu.
/// Laporan kendala alat/software hanya bisa dibuat setelah meja dibooking
/// (dari halaman Meja Kamu), supaya praktikan tidak asal melapor.
class PraktikanPilihMejaPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanPilihMejaPage({super.key, required this.nav});

  @override
  State<PraktikanPilihMejaPage> createState() => _PraktikanPilihMejaPageState();
}

class _PraktikanPilihMejaPageState extends State<PraktikanPilihMejaPage> {
  PraktikanStore get _s => widget.nav.store;

  int get _taken =>
      _s.desks.values.where((d) => d == PrakDesk.taken).length;

  void _pilih(int n) {
    final status = _s.desks[n];
    if (status == PrakDesk.available) {
      setState(() => _s.selectedDesk = n);
    } else if (status == PrakDesk.broken) {
      labToast(context, 'Meja ${n.toString().padLeft(2, '0')} sedang rusak');
    } else {
      labToast(context, 'Meja ${n.toString().padLeft(2, '0')} sudah terisi');
    }
  }

  void _booking() {
    _s.bookedDesk = _s.selectedDesk;
    widget.nav.mejaKamu(context, replace: true);
  }

  @override
  Widget build(BuildContext context) {
    final sel = _s.selectedDesk;
    final pc = sel.toString().padLeft(2, '0');
    return LabSubPage(
      onLogoTap: widget.nav.home,
      gap: 24,
      children: [
        LabCard(
          children: [
            const LabOverline(
                overline: 'Lab Komputer 1', title: 'Pilih Meja\nPraktikum'),
            Row(
              children: [
                const Flexible(
                  child:
                      LabMeta(icon: 'clock', text: 'Senin • 08:00–09:40 WIB'),
                ),
                const SizedBox(width: 24),
                Flexible(
                  child: LabMeta(
                      icon: 'people_group', text: '$_taken / 30 terisi'),
                ),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            const PrakSpaceRow(
              left: LabSectionTitle(icon: 'desktop_device', text: 'Denah Meja'),
              right: LabTag.blue('30 PC'),
            ),
            PrakDeskMap(desks: _s.desks, selected: sel, onTap: _pilih),
            const PrakDeskLegend(),
          ],
        ),
        LabListItem(
          leading: const LabIconTile('desktop_device'),
          title: 'Meja $sel • PC-$pc',
          subtitle: 'Core i5-12400 • 16 GB • SSD 512 GB',
          titleSize: 12,
          trailing: const LabChip.live('Siap'),
        ),
        LabPrimaryButton(
          icon: 'check',
          label: 'Booking Meja $sel',
          large: true,
          onTap: _booking,
        ),
      ],
    );
  }
}
