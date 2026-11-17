import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    final all = widget.store.students;
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
        const LabStatRow(
          stats: [
            LabStat(icon: 'triangle_alert', label: 'Berisiko', value: '5'),
            LabStat(icon: 'person_cross', label: 'Kehadiran', value: '3'),
            LabStat(icon: 'statistic_down', label: 'Nilai', value: '2'),
          ],
        ),
        LabTabs(
          labels: const ['Semua (5)', 'Kehadiran', 'Nilai'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        for (final s in shown)
          DosenStudentCard(
            student: s,
            onDetail: () => widget.onOpenDetail(s),
            onContact: () => widget.onOpenHubungi(s),
          ),
      ],
    );
  }
}

/// Kartu praktikan berisiko: nama, status, dua batang progress, dan (opsional)
/// tombol Lihat Detail / Hubungi Asisten. Dipakai juga di Detail Peringatan.
class DosenStudentCard extends StatelessWidget {
  final DosenStudent student;
  final VoidCallback? onDetail;
  final VoidCallback? onContact;

  const DosenStudentCard({
    super.key,
    required this.student,
    this.onDetail,
    this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final s = student;
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
            s.highRisk
                ? const LabChip.danger('Risiko Tinggi')
                : const LabChip.warn('Perlu Perhatian'),
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
