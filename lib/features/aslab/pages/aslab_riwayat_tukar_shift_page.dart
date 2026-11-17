import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';
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
  /// 0 Semua, 1 Shift Saya, 2 Asisten Lain.
  int _tab = 0;

  bool _match(AslabSwap s) {
    if (_tab == 1) return s.mine;
    if (_tab == 2) return !s.mine;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.nav.store.swaps.where(_match).toList();
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        const LabTitle(
          title: 'Riwayat Tukar Shift',
          subtitle: 'Catatan penukaran shift jaga anda dan asisten lain',
        ),
        const LabStatRow(
          stats: [
            LabStat(icon: 'arrow_right_left', label: 'Total', value: '6'),
            LabStat(icon: 'circle_check', label: 'Disetujui', value: '5'),
            LabStat(icon: 'cross', label: 'Ditolak', value: '1'),
          ],
        ),
        LabTabs(
          labels: const ['Semua', 'Shift Saya', 'Asisten Lain'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        for (final s in items) _SwapCard(swap: s),
      ],
    );
  }
}

class _SwapCard extends StatelessWidget {
  final AslabSwap swap;
  const _SwapCard({required this.swap});

  @override
  Widget build(BuildContext context) {
    return LabCard(
      children: [
        PrakSpaceRow(
          left: Align(
            alignment: Alignment.centerLeft,
            child: LabTag.grey(swap.code),
          ),
          right: swap.approved
              ? const LabChip.live('Disetujui')
              : const LabChip.danger('Ditolak'),
        ),
        Row(
          children: [
            AslabAvatarPair(swap.initials.$1, swap.initials.$2),
            const SizedBox(width: 10),
            Expanded(
              child: LabColumn(
                gap: 2,
                children: [
                  Text(swap.names, style: labText(14, w: kBold)),
                  Text(swap.meta,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                ],
              ),
            ),
          ],
        ),
        LabInsetBox(child: AslabSwapRow(left: swap.left, right: swap.right)),
      ],
    );
  }
}
