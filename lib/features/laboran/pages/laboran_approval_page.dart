import 'package:flutter/material.dart';

import '../../../core/services/jadwal_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../laboran_store.dart';
import '../widgets/laboran_ui.dart';

/// Figma: "Approval Ruangan-Laboran".
class LaboranApprovalPage extends StatefulWidget {
  final LaboranStore store;
  const LaboranApprovalPage({super.key, required this.store});

  @override
  State<LaboranApprovalPage> createState() => _LaboranApprovalPageState();
}

class _LaboranApprovalPageState extends State<LaboranApprovalPage> {
  final JadwalSyncService _sync = JadwalSyncService.instance;
  int _tab = 0;

  static const List<RoomStatus> _order = [
    RoomStatus.menunggu,
    RoomStatus.disetujui,
    RoomStatus.ditolak,
  ];

  @override
  void initState() {
    super.initState();
    _sync.refreshFromBackend();
  }

  Future<void> _decide(RoomBookingRecord request, RoomStatus status) async {
    await _sync.decideRoomRequest(requestId: request.id, status: status);
    if (!mounted) return;
    labToast(
      context,
      status == RoomStatus.disetujui
          ? 'Peminjaman ${request.labName} disetujui & disinkronkan ke BE'
          : 'Peminjaman ${request.labName} ditolak',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sync,
      builder: (context, _) {
        final all = _sync.roomRequests;
        final waiting =
            all.where((r) => r.status == RoomStatus.menunggu).length;
        final shown = all.where((r) => r.status == _order[_tab]).toList();
        return LabTabBody(
          children: [
            const LabTitle(
              title: 'Approval Ruangan',
              subtitle:
                  'Permintaan peminjaman ruangan untuk kelas dan praktikum '
                  'pengganti',
            ),
            LabTabs(
              labels: ['Menunggu ($waiting)', 'Disetujui', 'Ditolak'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            for (final r in shown)
              _RequestCard(
                request: r.toRoomRequest(),
                onReject: () => _decide(r, RoomStatus.ditolak),
                onApprove: () => _decide(r, RoomStatus.disetujui),
              ),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Tidak ada permintaan pada status ini.',
                  textAlign: TextAlign.center,
                  style: labText(12, c: ItlgColors.textSubtle),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RoomRequest request;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const _RequestCard({
    required this.request,
    required this.onReject,
    required this.onApprove,
  });

  Widget _chip() {
    switch (request.status) {
      case RoomStatus.menunggu:
        return const LabChip.warn('Menunggu Persetujuan');
      case RoomStatus.disetujui:
        return const LabChip.live('Disetujui');
      case RoomStatus.ditolak:
        return const LabChip.danger('Ditolak');
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = request;
    return LabCard(
      children: [
        Row(
          children: [
            _chip(),
            const Spacer(),
            LabTag.blue(r.tag),
          ],
        ),
        LabOverline(overline: r.lab, title: r.title, titleSize: 16),
        LabStatRow(
          gap: 13,
          stats: [
            LabStat(icon: 'calendar', label: 'Tanggal', value: r.date),
            LabStat(icon: 'clock', label: 'Waktu', value: r.time),
          ],
        ),
        LabPerson(initials: r.initials, name: r.name, caption: r.role),
        LabInsetBox(
          child: LabColumn(
            gap: 10,
            children: [
              Text('Alasan Peminjaman', style: labText(12, w: kBold)),
              Text(r.reason, style: labText(12, c: ItlgColors.textMuted)),
            ],
          ),
        ),
        if (r.status == RoomStatus.menunggu)
          LabButtonPair(
            left: LabOutlineButton(
                icon: 'cross', label: 'Tolak', onTap: onReject),
            right: LabPrimaryButton(
                icon: 'check', label: 'Setujui', onTap: onApprove),
          ),
      ],
    );
  }
}
