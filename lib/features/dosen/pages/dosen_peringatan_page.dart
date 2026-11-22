import 'package:flutter/material.dart';

import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../dosen_store.dart';

/// Figma: "Peringatan Dini-Dosen".
class DosenPeringatanPage extends StatefulWidget {
  final DosenStore store;
  final ValueChanged<DosenStudent> onOpenDetail;
  final ValueChanged<DosenStudent> onOpenHubungi;

  const DosenPeringatanPage({
    super.key,
    required this.store,
    required this.onOpenDetail,
    required this.onOpenHubungi,
  });

  @override
  State<DosenPeringatanPage> createState() => _DosenPeringatanPageState();
}

class _DosenPeringatanPageState extends State<DosenPeringatanPage> {
  /// 0 Semua, 1 Kehadiran, 2 Nilai.
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    NilaiSyncService.instance.refreshFromBackend();
  }

  @override
  Widget build(BuildContext context) {
    final nilaiSync = NilaiSyncService.instance;
    final praktikumSync = PraktikumSyncService.instance;
    final presensiSync = PresensiSyncService.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([nilaiSync, praktikumSync, presensiSync]),
      builder: (context, _) {
        final all = nilaiSync.liveAtRiskStudents(widget.store.students);
        final lowAttCount = all.where((s) => s.lowAttendance).length;
        final lowScoreCount = all.where((s) => s.lowScore).length;
        final shown = all.where((s) {
          if (_tab == 1) return s.lowAttendance;
          if (_tab == 2) return s.lowScore;
          return true;
        }).toList();

        return LabTabBody(
          children: [
            const LabTitle(
              title: 'Peringatan Dini',
              subtitle:
                  'Praktikan dengan kehadiran atau nilai di bawah batas minimal',
            ),
            LabStatRow(
              stats: [
                LabStat(
                    icon: 'triangle_alert',
                    label: 'Berisiko',
                    value: '${all.length}'),
                LabStat(
                    icon: 'person_cross',
                    label: 'Kehadiran',
                    value: '$lowAttCount'),
                LabStat(
                    icon: 'statistic_down',
                    label: 'Nilai',
                    value: '$lowScoreCount'),
              ],
            ),
            LabTabs(
              labels: ['Semua (${all.length})', 'Kehadiran', 'Nilai'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            for (final s in shown)
              DosenStudentCard(
                student: s,
                latestFollowUp: nilaiSync.latestFollowUpForStudent(s.nim),
                onDetail: () => widget.onOpenDetail(s),
                onContact: () => widget.onOpenHubungi(s),
              ),
          ],
        );
      },
    );
  }
}

/// Kartu praktikan berisiko: nama, status, dua batang progress, dan (opsional)
/// tombol Lihat Detail / Hubungi Asisten. Dipakai juga di Detail Peringatan.
class DosenStudentCard extends StatelessWidget {
  final DosenStudent student;
  final AssistantFollowUpRecord? latestFollowUp;
  final VoidCallback? onDetail;
  final VoidCallback? onContact;

  const DosenStudentCard({
    super.key,
    required this.student,
    this.latestFollowUp,
    this.onDetail,
    this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final s = student;
    final fu = latestFollowUp;
    return LabCard(
      children: [
        Row(
          children: [
            Expanded(
              child: LabPerson(
                initials: s.initials,
                name: s.name,
                caption: '${s.nim} • ${s.kelas}',
              ),
            ),
            const SizedBox(width: 8),
            fu != null
                ? const LabChip.info('Ditindaklanjuti')
                : (s.highRisk
                    ? const LabChip.danger('Risiko Tinggi')
                    : const LabChip.warn('Perlu Perhatian')),
          ],
        ),
        LabProgress(
          label: 'Kehadiran (min. 75%)',
          value: '${s.attendance}%',
          fraction: s.attendance / 100,
          color: s.lowAttendance ? ItlgColors.primary : LabColors.green,
        ),
        LabProgress(
          label: 'Rata-rata Nilai (min. 70)',
          value: '${s.score}',
          fraction: s.score / 100,
          color: s.lowScore ? ItlgColors.primary : LabColors.green,
        ),
        if (fu != null)
          LabMeta(
            icon: 'chat_bubble',
            text:
                'Tindak lanjut ${fu.followUpType} ke ${fu.assistantName} • ${fu.formattedClock}',
          ),
        if (onDetail != null && onContact != null)
          LabButtonPair(
            left: LabOutlineButton(
                icon: 'eye', label: 'Lihat Detail', onTap: onDetail),
            right: LabPrimaryButton(
                icon: 'chat_bubble',
                label: 'Hubungi Asisten',
                onTap: onContact),
          ),
      ],
    );
  }
}
