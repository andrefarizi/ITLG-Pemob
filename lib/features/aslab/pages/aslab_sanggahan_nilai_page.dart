import 'package:flutter/material.dart';

import '../../../core/services/nilai_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../../shared/lab_actions.dart';
import '../widgets/aslab_ui.dart';

/// Figma: "Sanggahan Nilai-Aslab" (5815:2864) + "Pop up Sanggahan Disetujui" (5815:2849)
/// serta "Sanggahan Nilai-Dosen" (5818:3083) + "Pop up Sanggahan Disetujui-Dosen" (5818:3068).
class SanggahanNilaiReviewPage extends StatefulWidget {
  final bool isDosen;
  final VoidCallback? onLogoTap;

  const SanggahanNilaiReviewPage({
    super.key,
    this.isDosen = false,
    this.onLogoTap,
  });

  @override
  State<SanggahanNilaiReviewPage> createState() =>
      _SanggahanNilaiReviewPageState();
}

class _SanggahanNilaiReviewPageState extends State<SanggahanNilaiReviewPage> {
  final NilaiSyncService _sync = NilaiSyncService.instance;

  /// 0 Menunggu, 1 Disetujui, 2 Ditolak.
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _sync.refreshFromBackend();
  }

  Future<void> _decide(GradeAppealRecord a, bool approve) async {
    final comp = a.components.isNotEmpty ? a.components.first : 'Modul ${a.modul}';
    if (!approve) {
      final ctrl = TextEditingController();
      final reason = await labShowCustomSheet<String>(
        context,
        title: 'Alasan Penolakan Sanggahan',
        subtitle: 'Wajib isi alasan penolakan untuk ${a.userName} ($comp).',
        child: LabColumn(
          gap: 14,
          children: [
            PrakTextArea(
              controller: ctrl,
              height: 92,
              hint: 'Contoh: Hasil penilaian sudah sesuai rubrik modul.',
            ),
            LabPrimaryButton(
              icon: 'cross',
              label: 'Tolak Sanggahan',
              large: true,
              onTap: () {
                final text = ctrl.text.trim();
                if (text.isEmpty) {
                  labToast(context, 'Alasan penolakan wajib diisi');
                  return;
                }
                Navigator.of(context).pop(text);
              },
            ),
          ],
        ),
      );
      ctrl.dispose();
      if (reason == null || !mounted) return;
      await _sync.decideAppeal(
        appeal: a,
        approve: false,
        rejectionReason: reason,
        decidedBy: AuthController.instance.userName,
        byDosen: widget.isDosen,
      );
      if (!mounted) return;
      labToast(
        context,
        widget.isDosen
            ? 'Sanggahan ${a.userName} ($comp) ditolak'
            : 'Rekomendasi tolak untuk ${a.userName} ($comp) dikirim ke Dosen',
      );
      return;
    }

    await _sync.decideAppeal(
      appeal: a,
      approve: true,
      newScore: a.proposedScore,
      decidedBy: AuthController.instance.userName,
      byDosen: widget.isDosen,
    );
    if (!mounted) return;

    await labShowResultDialog(
      context,
      icon: 'circle_check',
      title: widget.isDosen ? 'Nilai Diperbarui' : 'Rekomendasi Terkirim',
      message: widget.isDosen
          ? 'Nilai akhir ${a.userName} berubah menjadi ${a.proposedScore} (${NilaiSyncService.letterForScore(a.proposedScore)}). Asisten dan praktikan menerima notifikasi.'
          : 'Rekomendasi persetujuan nilai ${a.userName} ($comp → ${a.proposedScore}) dikirim ke Dosen Pengampu untuk keputusan akhir.',
      button: 'Selesai',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sync,
      builder: (context, _) {
        final all = _sync.appeals;
        final pendingCount = widget.isDosen
            ? all.where((a) => a.isWaitingDosen).length
            : all.where((a) => a.isWaitingAslab).length;
        final shown = switch (_tab) {
          1 => widget.isDosen
              ? all.where((a) => a.isApproved).toList()
              : all
                  .where((a) => a.isApproved || a.isRecommendedApprove)
                  .toList(),
          2 => widget.isDosen
              ? all.where((a) => a.isRejected).toList()
              : all
                  .where((a) => a.isRejected || a.isRecommendedReject)
                  .toList(),
          _ => widget.isDosen
              ? all.where((a) => a.isWaitingDosen).toList()
              : all.where((a) => a.isWaitingAslab).toList(),
        };

        return LabSubPage(
          onLogoTap: widget.onLogoTap,
          children: [
            LabTitle(
              title: 'Sanggahan Nilai',
              subtitle: widget.isDosen
                  ? 'Sanggahan yang sudah diperiksa asisten dan menunggu keputusan akhir anda'
                  : 'Ajuan koreksi nilai dari praktikan beserta alasan dan buktinya',
            ),
            LabTabs(
              labels: ['Menunggu ($pendingCount)', 'Disetujui', 'Ditolak'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'Tidak ada sanggahan nilai pada tab ini.',
                  textAlign: TextAlign.center,
                  style: labText(12, c: ItlgColors.textSubtle),
                ),
              )
            else
              for (final a in shown)
                _AppealCard(
                  appeal: a,
                  isDosen: widget.isDosen,
                  onReject: () => _decide(a, false),
                  onApprove: () => _decide(a, true),
                ),
          ],
        );
      },
    );
  }
}

class _AppealCard extends StatelessWidget {
  final GradeAppealRecord appeal;
  final bool isDosen;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const _AppealCard({
    required this.appeal,
    required this.isDosen,
    required this.onReject,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final comp =
        appeal.components.isNotEmpty ? appeal.components.first : 'Modul ${appeal.modul}';
    final statusChip = appeal.isApproved
        ? const LabChip.live('Disetujui')
        : (appeal.isRejected
            ? const LabChip.danger('Ditolak')
            : (appeal.isRecommendedApprove
                ? const LabChip.info('Rekomendasi Setuju')
                : (appeal.isRecommendedReject
                    ? const LabChip.warn('Rekomendasi Tolak')
                    : const LabChip.warn('Menunggu'))));
    final canAct = isDosen ? appeal.isWaitingDosen : appeal.isWaitingAslab;

    return LabCard(
      gap: 14,
      children: [
        PrakSpaceRow(left: statusChip, right: LabTag.blue(comp)),
        LabPerson(
          initials: appeal.initials,
          name: appeal.userName,
          caption: '${appeal.userIdentifier} • Kom C • Sesi C1',
        ),
        LabStatRow(
          gap: 12,
          stats: [
            LabStat(
              icon: 'clipboard',
              label: 'Nilai Saat Ini',
              value: '${appeal.currentScore}',
            ),
            LabStat(
              icon: 'arrow_right',
              label: 'Usulan Nilai',
              value: '${appeal.proposedScore}',
            ),
          ],
        ),
        LabInsetBox(
          child: LabColumn(
            gap: 8,
            cross: CrossAxisAlignment.start,
            children: [
              Text('Alasan Sanggahan', style: labText(12, w: kBold)),
              Text(appeal.reason,
                  style: labText(12, c: ItlgColors.textMuted)),
              if (appeal.attachmentName != null &&
                  appeal.attachmentName!.isNotEmpty)
                GestureDetector(
                  onTap: () => labShowFilePreview(
                    context,
                    name: appeal.attachmentName!,
                    source: 'Bukti lampiran sanggahan • Siap diunduh',
                  ),
                  child: AslabFilePill(
                    icon: 'attach',
                    text: appeal.attachmentName!,
                    background: ItlgColors.surfaceDark,
                  ),
                ),
            ],
          ),
        ),
        if (isDosen &&
            appeal.assistantRecommendation != null &&
            appeal.assistantRecommendation!.isNotEmpty)
          Text(
            appeal.assistantRecommendation!,
            style: labText(12, w: kSemiBold, c: ItlgColors.secondary),
          ),
        if (canAct)
          LabButtonPair(
            left: LabOutlineButton(
              icon: 'cross',
              label: isDosen ? 'Tolak Sanggahan' : 'Rekomendasi Tolak',
              onTap: onReject,
            ),
            right: LabPrimaryButton(
              icon: 'check',
              label: isDosen ? 'Setujui & Ubah Nilai' : 'Rekomendasi Setuju',
              onTap: onApprove,
            ),
          ),
      ],
    );
  }
}
