import 'package:flutter/material.dart';

import '../../../core/services/shift_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../widgets/aslab_ui.dart';

/// Halaman Riwayat Tukar Shift Asisten Lab.
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
    final displayCode = swap.swapCode.replaceFirst('#TS-', '#TJ-');
    final isIncoming = swap.isIncoming;
    labShowCustomSheet<void>(
      context,
      title: 'Detail Tukar Jadwal',
      child: LabColumn(
        gap: 14,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: ItlgShadows.outline,
            ),
            child: LabColumn(
              gap: 12,
              children: [
                PrakSpaceRow(
                  left: LabTag.grey(displayCode),
                  right: swap.isApproved
                      ? const LabChip.live('Disetujui')
                      : (swap.isRejected
                          ? const LabChip.danger('Ditolak')
                          : const LabChip.warn('Menunggu')),
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
                          Text(
                            isIncoming
                                ? 'Diajukan ${swap.requesterFirstName} • menunggu persetujuan anda'
                                : 'Diajukan anda • menunggu persetujuan ${swap.targetFirstName}',
                            style: labText(11,
                                w: kMedium, c: ItlgColors.textSubtle),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                LabInsetBox(
                  child: AslabSwapRow(
                    left: ('Jadwal ${swap.requesterFirstName}',
                        swap.fromShiftLabel),
                    right: ('Jadwal ${swap.targetFirstName}',
                        swap.toShiftLabel),
                  ),
                ),
              ],
            ),
          ),
          Text(
            swap.reason.isNotEmpty
                ? 'Alasan: ${swap.reason}${isIncoming ? ' Kalau disetujui, jadwal kalian berdua langsung diperbarui.' : ''}'
                : (isIncoming
                    ? 'Kalau disetujui, jadwal kalian berdua langsung diperbarui.'
                    : 'Pengajuan ini masih menunggu persetujuan ${swap.targetName}. Kamu bisa membatalkannya selama belum disetujui.'),
            style: labText(12, w: kMedium, c: ItlgColors.textMuted),
          ),
          if (swap.isPending && isIncoming)
            LabButtonPair(
              left: LabOutlineButton(
                icon: 'cross',
                label: 'Tolak',
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    await _sync.decideSwap(
                      swapCode: swap.swapCode,
                      accept: false,
                      decidedByName: AuthController.instance.userName,
                    );
                  } on StateError catch (e) {
                    if (mounted) labToast(context, e.message);
                    return;
                  }
                  if (mounted) {
                    await labShowResultDialog(
                      context,
                      icon: 'person_cross',
                      title: 'Permintaan Ditolak',
                      message:
                          'Pemohon akan menerima notifikasi bahwa permintaannya ditolak.',
                      button: 'Selesai',
                    );
                  }
                },
              ),
              right: LabPrimaryButton(
                icon: 'check',
                label: 'Setujui Penukaran',
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    await _sync.decideSwap(
                      swapCode: swap.swapCode,
                      accept: true,
                      decidedByName: AuthController.instance.userName,
                    );
                  } on StateError catch (e) {
                    if (mounted) labToast(context, e.message);
                    return;
                  }
                  if (!mounted) return;
                  await labShowResultDialog(
                    context,
                    icon: 'circle_check',
                    title: 'Tukar Jadwal Diterima',
                    message:
                        'Jadwal mengajar anda sudah diperbarui dan pemohon akan menerima notifikasi.',
                    button: 'Selesai',
                  );
                },
              ),
            )
          else if (swap.isPending && !isIncoming)
            LabSoftDangerButton(
              icon: 'cross',
              label: 'Batalkan Permintaan Tukar Jadwal',
              onTap: () async {
                Navigator.of(context).pop();
                final bool ok;
                try {
                  ok = await _sync.cancelSwap(
                    swapCode: swap.swapCode,
                    requesterName: AuthController.instance.userName,
                  );
                } on StateError catch (e) {
                  if (mounted) labToast(context, e.message);
                  return;
                }
                if (mounted) {
                  labToast(
                    context,
                    ok
                        ? 'Permintaan $displayCode dibatalkan'
                        : 'Hanya pemohon yang bisa membatalkan permintaan menunggu',
                  );
                }
              },
            ),
        ],
      ),
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
              title: 'Riwayat Tukar Jadwal',
              subtitle: 'Catatan penukaran jadwal mengajar anda dan asisten lain',
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
              labels: const ['Semua', 'Jadwal Saya', 'Asisten Lain'],
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
            child: LabTag.grey(swap.swapCode.replaceFirst('#TS-', '#TJ-')),
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
            left: ('Jadwal ${swap.requesterFirstName}', swap.fromShiftLabel),
            right: ('Jadwal ${swap.targetFirstName}', swap.toShiftLabel),
          ),
        ),
      ],
    );
  }
}
