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

/// Halaman Pilih Meja Praktikan.
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

  /// Lab tempat sesi presensi aktif berlangsung (dibuka Aslab).
  String get _lab => PresensiSyncService.instance.activeSession.labName;

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
    final liveMap = _sync.deskStatusMap(labName: _lab);
    final myBooked = _sync.bookedDeskForUser(userKey, labName: _lab);
    if (myBooked != null) {
      _s.bookedDesk = myBooked;
    }
    if (liveMap[_s.selectedDesk] != PrakDesk.available &&
        _s.selectedDesk != myBooked) {
      _s.selectedDesk = _sync.firstAvailableDesk(
        labName: _lab,
        preferred: _s.selectedDesk,
      );
    }
  }

  void _pilih(int n) {
    final liveMap = _sync.deskStatusMap(labName: _lab);
    final userKey = AuthController.instance.userIdentifier;
    final myBooked = _sync.bookedDeskForUser(userKey, labName: _lab);
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
      labName: _lab,
      deskNumber: targetDesk,
      userKey: auth.userIdentifier,
      userName: auth.userName,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.success) {
      labToast(context, result.errorMessage ?? 'Meja gagal dipilih, coba lagi');
      _syncSelectionWithLiveState();
      return;
    }

    _s.bookedDesk = targetDesk;
    widget.nav.mejaKamu(context, replace: true);
  }

  @override
  Widget build(BuildContext context) {
    final session = PresensiSyncService.instance.activeSession;
    final course = PraktikumSyncService.instance.courseById(session.courseId);
    final liveMap = _sync.deskStatusMap(labName: _lab);
    final taken = _sync.takenCount(labName: _lab);
    final sel = _s.selectedDesk;
    final pc = sel.toString().padLeft(2, '0');
    final deskRec = _sync.deskRecord(sel, labName: _lab);
    final spec = deskRec?.spec ?? 'Core i5-12400 • 16 GB • SSD 512 GB';

    return LabSubPage(
      onLogoTap: widget.nav.home,
      gap: 24,
      children: [
        LabCard(
          children: [
            const LabOverline(
              overline: 'Kom C • Sesi C1',
              title: 'Pilih Meja\nPraktikum',
            ),
            Text(
              '$_lab • ${course.name} • Pertemuan ${session.meetingNumber}',
              style: labText(12, w: kMedium, c: LabColors.textGrey),
            ),
            Row(
              children: [
                Flexible(
                  child: LabMeta(icon: 'clock', text: course.jadwalAbsensi),
                ),
                const SizedBox(width: 24),
                Flexible(
                  child: LabMeta(
                    icon: 'people_group',
                    text: '$taken / 30 terisi',
                  ),
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
          trailing: deskRec?.status == PrakDesk.broken
              ? const LabChip.danger('Rusak')
              : (deskRec?.status == PrakDesk.taken
                    ? const LabChip.warn('Terisi')
                    : const LabChip.live('Siap')),
        ),
        LabPrimaryButton(
          icon: 'check',
          label: 'Pilih Meja $sel',
          large: true,
          onTap: _booking,
        ),
      ],
    );
  }
}
