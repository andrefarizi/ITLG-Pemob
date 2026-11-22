import 'package:flutter/material.dart';

import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../widgets/aslab_ui.dart';

/// Figma: "Persetujuan Izin-Aslab".
class AslabPersetujuanIzinPage extends StatefulWidget {
  final AslabNav nav;
  const AslabPersetujuanIzinPage({super.key, required this.nav});

  @override
  State<AslabPersetujuanIzinPage> createState() =>
      _AslabPersetujuanIzinPageState();
}

class _AslabPersetujuanIzinPageState extends State<AslabPersetujuanIzinPage> {
  final PresensiSyncService _sync = PresensiSyncService.instance;

  /// 0 Menunggu, 1 Disetujui, 2 Ditolak.
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onSyncChanged);
    _sync.refreshFromBackend();
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncChanged);
    super.dispose();
  }

  void _onSyncChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _decide(LeaveRequestRecord l, bool approve) async {
    await _sync.decideLeaveRequest(
      leave: l,
      approve: approve,
      decidedBy: AuthController.instance.userName,
    );
    if (!mounted) return;
    labToast(
      context,
      approve
          ? 'Pengajuan ${l.userName} disetujui'
          : 'Pengajuan ${l.userName} ditolak',
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaves = _sync.leaves;
    final items = leaves.where((l) => l.status == _tab).toList();
    final pending = leaves.where((l) => l.status == 0).length;
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        const LabTitle(
          title: 'Persetujuan Izin',
          subtitle: 'Pengajuan izin dan presensi susulan dari praktikan',
        ),
        LabTabs(
          labels: ['Menunggu ($pending)', 'Disetujui', 'Ditolak'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        for (final l in items)
          _LeaveCard(
            leave: l,
            onReject: () => _decide(l, false),
            onApprove: () => _decide(l, true),
          ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('Tidak ada pengajuan.',
                textAlign: TextAlign.center,
                style: labText(12, c: ItlgColors.textSubtle)),
          ),
      ],
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveRequestRecord leave;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const _LeaveCard({
    required this.leave,
    required this.onReject,
    required this.onApprove,
  });

  Widget _chip() {
    switch (leave.status) {
      case 1:
        return const LabChip.live('Disetujui');
      case 2:
        return const LabChip.danger('Ditolak');
      default:
        return const LabChip.warn('Menunggu');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LabCard(
      children: [
        PrakSpaceRow(left: _chip(), right: LabTag.blue(leave.leaveType)),
        LabPerson(
          initials: leave.initials,
          name: leave.userName,
          caption: '${leave.userIdentifier} • TIF 3001 - Kelas C',
        ),
        LabStatRow(
          gap: 13,
          stats: [
            LabStat(
                icon: 'calendar',
                label: 'Pertemuan',
                value: leave.pertemuanLabel),
            LabStat(
                icon: 'clock',
                label: 'Diajukan',
                value: leave.submittedLabel),
          ],
        ),
        LabInsetBox(
          child: LabColumn(
            gap: 10,
            cross: CrossAxisAlignment.start,
            children: [
              Text('Keterangan', style: labText(12, w: kBold)),
              Text(leave.note, style: labText(12, c: ItlgColors.textMuted)),
              if (leave.fileName != null && leave.fileName!.isNotEmpty)
                AslabFilePill(
                  icon: 'attach',
                  text: leave.fileName!,
                  background: ItlgColors.surfaceDark,
                ),
            ],
          ),
        ),
        if (leave.status == 0)
          LabButtonPair(
            left: LabOutlineButton(
                icon: 'cross', label: 'Tolak', onTap: onReject),
            right: LabPrimaryButton(
                icon: 'check', label: leave.approveLabel, onTap: onApprove),
          ),
      ],
    );
  }
}
