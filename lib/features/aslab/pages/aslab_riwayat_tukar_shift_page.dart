import 'package:flutter/material.dart';

import '../../../core/services/shift_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../../shared/lab_actions.dart';
import '../aslab_nav.dart';
import '../widgets/aslab_ui.dart';

/// Figma: "Riwayat Tukar Shift-Aslab".
class AslabRiwayatTukarShiftPage extends StatefulWidget {
  final AslabNav nav;
  const AslabRiwayatTukarShiftPage({super.key, required this.nav});

  @override
  State<AslabRiwayatTukarShiftPage> createState() =>
      _AslabRiwayatTukarShiftPageState();
}

class _AslabRiwayatTukarShiftPageState
    extends State<AslabRiwayatTukarShiftPage> {
  final ShiftSyncService _sync = ShiftSyncService.instance;

  /// 0 Semua, 1 Shift Saya, 2 Asisten Lain.
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _sync.refreshFromBackend();
  }

  void _showDetail(ShiftSwapRecord swap) {
    final statusLabel = swap.isApproved
        ? 'Disetujui'
        : (swap.isRejected ? 'Ditolak' : 'Menunggu Konfirmasi');
    labShowInfoSheet(
      context,
      title: 'Detail Tukar Shift ${swap.swapCode}',
      rows: [
        ('person', 'Asisten', swap.pairNames),
        ('clock', 'Shift Asal', swap.fromShiftLabel),
        ('arrow_right_left', 'Shift Tujuan', swap.toShiftLabel),
        ('circle_check', 'Status', statusLabel),
      ],
      note: swap.reason.isNotEmpty ? swap.reason : swap.metaNote,
      primary: swap.isPending
          ? (
              'check',
              'Setujui Penukaran',
              () async {
                await _sync.decideSwap(
                  swapCode: swap.swapCode,
                  accept: true,
                  decidedByName: AuthController.instance.userName,
                );
                if (mounted) {
                  labToast(context, 'Tukar shift ${swap.swapCode} disetujui');
                }
              },
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sync,
      builder: (context, _) {
        final items = _sync.swapsForTab(_tab);
        final total = _sync.allSwaps.length;
        final approved = _sync.approvedSwapCount;
        final rejected = _sync.rejectedSwapCount;

        return LabSubPage(
          onLogoTap: widget.nav.home,
          children: [
            const LabTitle(
              title: 'Riwayat Tukar Shift',
              subtitle: 'Catatan penukaran shift jaga anda dan asisten lain',
            ),
            LabStatRow(
              stats: [
                LabStat(
                    icon: 'arrow_right_left', label: 'Total', value: '$total'),
                LabStat(
                    icon: 'circle_check',
                    label: 'Disetujui',
                    value: '$approved'),
                LabStat(icon: 'cross', label: 'Ditolak', value: '$rejected'),
              ],
            ),
            LabTabs(
              labels: const ['Semua', 'Shift Saya', 'Asisten Lain'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            for (final s in items)
              _SwapCard(swap: s, onTap: () => _showDetail(s)),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Belum ada riwayat tukar shift pada kategori ini.',
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

class _SwapCard extends StatelessWidget {
  final ShiftSwapRecord swap;
  final VoidCallback onTap;
  const _SwapCard({required this.swap, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Widget chip;
    if (swap.isApproved) {
      chip = const LabChip.live('Disetujui');
    } else if (swap.isRejected) {
      chip = const LabChip.danger('Ditolak');
    } else {
      chip = const LabChip.warn('Menunggu');
    }

    return LabCard(
      onTap: onTap,
      children: [
        PrakSpaceRow(
          left: Align(
            alignment: Alignment.centerLeft,
            child: LabTag.grey(swap.swapCode),
          ),
          right: chip,
        ),
        Row(
          children: [
            AslabAvatarPair(swap.requesterInitials, swap.targetInitials),
            const SizedBox(width: 10),
            Expanded(
              child: LabColumn(
                gap: 2,
                children: [
                  Text(swap.pairNames, style: labText(14, w: kBold)),
                  Text(swap.metaNote,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                ],
              ),
            ),
          ],
        ),
        LabInsetBox(
          child: AslabSwapRow(
            left: ('Shift ${swap.requesterFirstName}', swap.fromShiftLabel),
            right: ('Shift ${swap.targetFirstName}', swap.toShiftLabel),
          ),
        ),
      ],
    );
  }
}
