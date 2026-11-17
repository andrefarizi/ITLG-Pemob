import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';
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
  /// 0 Menunggu, 1 Disetujui, 2 Ditolak.
  int _tab = 0;

  void _decide(AslabLeave l, bool approve) {
    setState(() => l.status = approve ? 1 : 2);
    labToast(
      context,
      approve
          ? 'Pengajuan ${l.student.name} disetujui'
          : 'Pengajuan ${l.student.name} ditolak',
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaves = widget.nav.store.leaves;
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
  final AslabLeave leave;
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
    final s = leave.student;
    return LabCard(
      children: [
        PrakSpaceRow(left: _chip(), right: LabTag.blue(leave.type)),
        LabPerson(
          initials: s.initials,
          name: s.name,
          caption: '${s.nim} • TIF 3001 - Kelas C',
        ),
        LabStatRow(
          gap: 13,
          stats: [
            LabStat(
                icon: 'calendar', label: 'Pertemuan', value: leave.pertemuan),
            LabStat(icon: 'clock', label: 'Diajukan', value: leave.diajukan),
          ],
        ),
        LabInsetBox(
          child: LabColumn(
            gap: 10,
            cross: CrossAxisAlignment.start,
            children: [
              Text('Keterangan', style: labText(12, w: kBold)),
              Text(leave.note, style: labText(12, c: ItlgColors.textMuted)),
              if (leave.file != null)
                AslabFilePill(
                  icon: 'attach',
                  text: leave.file!,
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
