import 'package:flutter/material.dart';

import '../../../core/services/jadwal_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
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

  Future<void> _decide(
    RoomBookingRecord request,
    RoomStatus status, {
    String? rejectionNote,
  }) async {
    final conflictError = await _sync.decideRoomRequest(
      requestId: request.id,
      status: status,
      rejectionNote: rejectionNote,
    );
    if (!mounted) return;
    if (conflictError != null) {
      labToast(context, conflictError);
      return;
    }
    labToast(
      context,
      status == RoomStatus.disetujui
          ? 'Peminjaman ${request.labName} disetujui & disinkronkan ke BE'
          : 'Peminjaman ${request.labName} ditolak',
    );
  }

  /// Figma: "Sheet Alasan Penolakan-Laboran" (5817:3163).
  Future<void> _openRejectSheet(RoomBookingRecord request) async {
    const reasons = [
      ('clipboard', 'Dipakai Ujian'),
      ('wrench_outline', 'Perbaikan Alat'),
      ('clock', 'Bentrok Jadwal'),
      ('info', 'Lainnya'),
    ];
    var selected = 0;
    final noteCtrl = TextEditingController(
      text:
          '${request.labName} dipakai ujian susulan pada jam yang sama. Silakan ajukan ruangan lain.',
    );

    final confirmed = await labShowCustomSheet<bool>(
      context,
      title: 'Alasan Penolakan',
      subtitle:
          'Alasan ini dikirim ke ${request.requesterName} dan tampil di kartu pengajuan ruangannya.',
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return LabColumn(
            gap: 14,
            children: [
              PrakField(
                label: 'Pilih Alasan',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < reasons.length; i++)
                      GestureDetector(
                        onTap: () => setSheetState(() {
                          selected = i;
                          if (i == 0) {
                            noteCtrl.text =
                                '${request.labName} dipakai ujian susulan pada jam yang sama. Silakan ajukan ruangan lain.';
                          } else if (i == 1) {
                            noteCtrl.text =
                                '${request.labName} sedang dalam perbaikan alat. Silakan pilih ruangan lain.';
                          } else if (i == 2) {
                            noteCtrl.text =
                                'Jadwal bentrok dengan kelas praktikum lain di ${request.labName}.';
                          } else {
                            noteCtrl.clear();
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: selected == i
                                ? ItlgColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: selected == i
                                ? ItlgShadows.primary
                                : ItlgShadows.outline,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LabIcon(
                                reasons[i].$1,
                                size: 15,
                                color: selected == i
                                    ? Colors.white
                                    : ItlgColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                reasons[i].$2,
                                style: labText(
                                  12,
                                  w: kBold,
                                  c: selected == i
                                      ? Colors.white
                                      : ItlgColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PrakField(
                label: 'Catatan untuk Asisten :',
                child: PrakTextArea(
                  controller: noteCtrl,
                  height: 92,
                  hint: 'Tulis alasan penolakan untuk asisten...',
                ),
              ),
              LabPrimaryButton(
                icon: 'cross',
                label: 'Tolak Peminjaman',
                large: true,
                onTap: () => Navigator.of(ctx).pop(true),
              ),
            ],
          );
        },
      ),
    );
    final note = noteCtrl.text.trim();
    noteCtrl.dispose();
    if (confirmed == true && mounted) {
      await _decide(
        request,
        RoomStatus.ditolak,
        rejectionNote: note.isNotEmpty ? note : reasons[selected].$2,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sync,
      builder: (context, _) {
        final all = _sync.roomRequests;
        final waiting =
            all.where((r) => r.status == RoomStatus.menunggu).length;
        final rejected =
            all.where((r) => r.status == RoomStatus.ditolak).length;
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
              labels: [
                'Menunggu ($waiting)',
                'Disetujui',
                rejected > 0 ? 'Ditolak ($rejected)' : 'Ditolak',
              ],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            for (final r in shown)
              _RequestCard(
                request: r.toRoomRequest(),
                rejectionNote: r.rejectionNote,
                onReject: () => _openRejectSheet(r),
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
  final String? rejectionNote;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const _RequestCard({
    required this.request,
    this.rejectionNote,
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
        if (r.status == RoomStatus.ditolak &&
            (rejectionNote?.isNotEmpty ?? false))
          LabInsetBox(
            child: LabColumn(
              gap: 6,
              children: [
                Text('Catatan Laboran',
                    style: labText(12, w: kBold, c: ItlgColors.primary)),
                Text(rejectionNote!,
                    style: labText(12, c: ItlgColors.textMuted)),
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
