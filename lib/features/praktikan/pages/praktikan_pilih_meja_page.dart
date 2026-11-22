import 'package:flutter/material.dart';

import '../../../core/services/lab_desk_sync_service.dart';
import '../../auth/auth_controller.dart';
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
  final LabDeskSyncService _sync = LabDeskSyncService.instance;
  bool _submitting = false;

  PraktikanStore get _s => widget.nav.store;

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onSyncChanged);
    _syncSelectionWithLiveState();
    _sync.refreshFromBackend();
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncChanged);
    super.dispose();
  }

  void _onSyncChanged() {
    if (!mounted) return;
    _syncSelectionWithLiveState();
    setState(() {});
  }

  void _syncSelectionWithLiveState() {
    final userKey = AuthController.instance.userIdentifier;
    final liveMap = _sync.deskStatusMap();
    final myBooked = _sync.bookedDeskForUser(userKey);
    if (myBooked != null) {
      _s.bookedDesk = myBooked;
    }
    if (liveMap[_s.selectedDesk] != PrakDesk.available &&
        _s.selectedDesk != myBooked) {
      _s.selectedDesk = _sync.firstAvailableDesk(preferred: _s.selectedDesk);
    }
  }

  void _pilih(int n) {
    final liveMap = _sync.deskStatusMap();
    final userKey = AuthController.instance.userIdentifier;
    final myBooked = _sync.bookedDeskForUser(userKey);
    final status = liveMap[n];
    if (status == PrakDesk.available || n == myBooked) {
      setState(() => _s.selectedDesk = n);
    } else if (status == PrakDesk.broken) {
      labToast(context, 'Meja ${n.toString().padLeft(2, '0')} sedang rusak');
    } else {
      labToast(context, 'Meja ${n.toString().padLeft(2, '0')} sudah terisi');
    }
  }

  Future<void> _booking() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final auth = AuthController.instance;
    final targetDesk = _s.selectedDesk;
    final result = await _sync.bookDesk(
      deskNumber: targetDesk,
      userKey: auth.userIdentifier,
      userName: auth.userName,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.success) {
      labToast(context, result.errorMessage ?? 'Gagal membooking meja');
      _syncSelectionWithLiveState();
      return;
    }

    _s.bookedDesk = targetDesk;
    widget.nav.mejaKamu(context, replace: true);
  }

  @override
  Widget build(BuildContext context) {
    final liveMap = _sync.deskStatusMap();
    final taken = _sync.takenCount();
    final sel = _s.selectedDesk;
    final pc = sel.toString().padLeft(2, '0');
    final deskRec = _sync.deskRecord(sel);
    final spec = deskRec?.spec ?? 'Core i5-12400 • 16 GB • SSD 512 GB';

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
                      icon: 'people_group', text: '$taken / 30 terisi'),
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
            PrakDeskMap(desks: liveMap, selected: sel, onTap: _pilih),
            const PrakDeskLegend(),
          ],
        ),
        LabListItem(
          leading: const LabIconTile('desktop_device'),
          title: 'Meja $sel • PC-$pc',
          subtitle: spec,
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
