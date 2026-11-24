import 'package:flutter/material.dart';

import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../dosen_store.dart';
import '../widgets/dosen_ui.dart';

/// Halaman Peringatan Dini Dosen.
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
  final TextEditingController _search = TextEditingController();
  String _query = '';
  int _courseFilter = 0;
  int _sessionFilter = 0;

  /// 0 Semua, 1 Kehadiran, 2 Nilai.
  int _tab = 0;

  static const List<String> _courseOptions = [
    'Semua',
    'Pemrograman Mobile',
    'Desain Interaksi',
    'ADJ',
    'Machine Learning',
  ];
  static const List<String> _sessionOptions = ['C1 & C2', 'Sesi C1', 'Sesi C2'];

  @override
  void initState() {
    super.initState();
    NilaiSyncService.instance.refreshFromBackend();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
        final q = _query.trim().toLowerCase();
        final shown = all.where((s) {
          if (_tab == 1 && !s.lowAttendance) return false;
          if (_tab == 2 && !s.lowScore) return false;
          if (_courseFilter != 0) {
            final expectedAsisten = switch (_courseFilter) {
              1 => 'andi',
              2 => 'feri',
              3 => 'sinta',
              4 => 'rizky',
              _ => '',
            };
            if (expectedAsisten.isNotEmpty &&
                !s.asisten.toLowerCase().contains(expectedAsisten)) {
              return false;
            }
          }
          if (_sessionFilter != 0) {
            final nimNum = int.tryParse(s.nim.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            final isC1 = s.kelas.toLowerCase().contains('c1') ||
                (!s.kelas.toLowerCase().contains('c2') && nimNum.isOdd);
            if (_sessionFilter == 1 && !isC1) return false;
            if (_sessionFilter == 2 && isC1) return false;
          }
          if (q.isNotEmpty &&
              !s.name.toLowerCase().contains(q) &&
              !s.nim.contains(q)) {
            return false;
          }
          return true;
        }).toList();

        return LabTabBody(
          children: [
            const LabTitle(
              title: 'Peringatan Dini',
              subtitle:
                  'Praktikan dengan kehadiran atau nilai di bawah batas minimal',
            ),
            DosenSearchField(
              hint: 'Cari nama atau NIM praktikan...',
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              filterActive: _courseFilter != 0 || _sessionFilter != 0,
              onFilter: () async {
                final picked = await dosenShowPicker(
                  context,
                  title: 'Filter Mata Kuliah',
                  options: _courseOptions,
                  selected: _courseFilter,
                );
                if (picked != null && mounted) {
                  setState(() => _courseFilter = picked);
                }
              },
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await dosenShowPicker(
                      context,
                      title: 'Filter Mata Kuliah',
                      options: _courseOptions,
                      selected: _courseFilter,
                    );
                    if (picked != null && mounted) {
                      setState(() => _courseFilter = picked);
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ItlgShadows.outline,
                    ),
                    child: Text(
                      'Mata Kuliah: ${_courseOptions[_courseFilter]}',
                      style: labText(11, w: kBold, c: ItlgColors.text),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await dosenShowPicker(
                      context,
                      title: 'Filter Sesi',
                      options: _sessionOptions,
                      selected: _sessionFilter,
                    );
                    if (picked != null && mounted) {
                      setState(() => _sessionFilter = picked);
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ItlgShadows.outline,
                    ),
                    child: Text(
                      'Sesi: ${_sessionOptions[_sessionFilter]}',
                      style: labText(11, w: kBold, c: ItlgColors.text),
                    ),
                  ),
                ),
              ],
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
          value: s.score < 0 ? '-' : '${s.score}',
          fraction: s.score < 0 ? 0 : s.score / 100,
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
