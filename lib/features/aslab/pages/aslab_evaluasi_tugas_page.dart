import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';
import '../widgets/aslab_ui.dart';

/// Figma: "Evaluasi Tugas-Aslab".
class AslabEvaluasiTugasPage extends StatefulWidget {
  final AslabNav nav;
  final String courseId;
  const AslabEvaluasiTugasPage({
    super.key,
    required this.nav,
    this.courseId = 'pemob',
  });

  @override
  State<AslabEvaluasiTugasPage> createState() => _AslabEvaluasiTugasPageState();
}

class _Submission {
  final AslabStudent student;
  final bool graded;
  final List<(String, String)> files;
  const _Submission(this.student, this.graded, this.files);
}

class _AslabEvaluasiTugasPageState extends State<AslabEvaluasiTugasPage> {
  static const List<_Submission> _all = [
    _Submission(kRina, false, [
      ('file', 'laporan_erd.pdf'),
      ('database_outline', 'query.sql'),
    ]),
    _Submission(kDimas, false, [
      ('file', 'laporan.pdf'),
      ('link_chain', 'github.com/dimas'),
    ]),
    _Submission(kMaya, true, [
      ('file', 'laporan_tugas4.pdf'),
      ('database_outline', 'tugas4.sql'),
    ]),
  ];

  final TextEditingController _search = TextEditingController();
  String _query = '';

  /// 0 Menunggu, 1 Sudah Dinilai, 2 Terlambat.
  int _tab = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _match(_Submission s) {
    if (_tab == 0 && s.graded) return false;
    if (_tab == 1 && !s.graded) return false;
    if (_tab == 2) return false;
    final q = _query.trim().toLowerCase();
    return q.isEmpty ||
        s.student.name.toLowerCase().contains(q) ||
        s.student.nim.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final sync = PraktikumSyncService.instance;
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final course = sync.courseById(widget.courseId);
        final dynamicSubs = <_Submission>[];
        final seenNims = <String>{};
        for (final rec in sync.submissionsForCourse(course.id, 4)) {
          seenNims.add(rec.userIdentifier);
          final parts = rec.userName.trim().split(RegExp(r'\s+'));
          final initials = parts.length >= 2
              ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
              : (rec.userName.isNotEmpty
                  ? rec.userName.substring(0, 1).toUpperCase()
                  : 'PR');
          dynamicSubs.add(
            _Submission(
              AslabStudent(initials, rec.userName, rec.userIdentifier),
              rec.status == 'graded',
              [
                for (final f in rec.files) ('file', f.name),
                if (rec.repoUrl.isNotEmpty) ('link_chain', rec.repoUrl),
              ],
            ),
          );
        }
        final seedFiltered =
            _all.where((s) => !seenNims.contains(s.student.nim)).toList();
        final combined = [...dynamicSubs, ...seedFiltered];
        final items = combined.where(_match).toList();
        final waitingExtra =
            dynamicSubs.where((s) => !s.graded).length;
        final gradedExtra =
            dynamicSubs.where((s) => s.graded).length;
        final waitingCount = 6 + waitingExtra;
        final gradedCount = 14 + gradedExtra;
        final totalCount = (20 + dynamicSubs.length).clamp(0, 24);
        return LabSubPage(
          onLogoTap: widget.nav.home,
          children: [
            LabTitle(
              title: 'Evaluasi Tugas',
              subtitle: 'Praktikum ${course.name} • ${course.kelas}',
            ),
            PrakSearchField(
              hint: 'Cari nama atau NIM praktikan...',
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              filterActive: _tab != 0,
              onFilter: () async {
                final i = await prakShowPicker(
                  context,
                  title: 'Filter Status Tugas',
                  options: [
                    'Menunggu ($waitingCount)',
                    'Sudah Dinilai',
                    'Terlambat',
                  ],
                  selected: _tab,
                );
                if (i != null && mounted) setState(() => _tab = i);
              },
            ),
            LabCard(
              children: [
                PrakSpaceRow(
                  left: const LabTag.red('Tugas 4'),
                  right: LabMeta(icon: 'clock', text: course.tugasDeadline),
                ),
                Text(
                  course.tugasTitle.replaceFirst('Tugas 4 : ', ''),
                  style: labText(16, w: kBold, c: Colors.black),
                ),
                LabStatRow(
                  stats: [
                    LabStat(
                      icon: 'file',
                      label: 'Terkumpul',
                      value: '$totalCount / 24',
                    ),
                    LabStat(
                      icon: 'check',
                      label: 'Dinilai',
                      value: '$gradedCount',
                    ),
                    LabStat(
                      icon: 'clock',
                      label: 'Menunggu',
                      value: '$waitingCount',
                    ),
                  ],
                ),
              ],
            ),
            LabTabs(
              labels: ['Menunggu ($waitingCount)', 'Sudah Dinilai', 'Terlambat'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            for (final s in items)
              _SubmissionCard(
                item: s,
                onDownload: () => labToast(
                    context, 'Berkas ${s.student.name} sedang diunduh'),
                onGrade: () => widget.nav.penilaianTugas(
                  context,
                  student: s.student,
                  courseId: course.id,
                ),
              ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Tidak ada pengumpulan.',
                    textAlign: TextAlign.center,
                    style: labText(12, c: ItlgColors.textSubtle)),
              ),
          ],
        );
      },
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final _Submission item;
  final VoidCallback onDownload;
  final VoidCallback onGrade;

  const _SubmissionCard({
    required this.item,
    required this.onDownload,
    required this.onGrade,
  });

  @override
  Widget build(BuildContext context) {
    final s = item.student;
    return LabCard(
      children: [
        Row(
          children: [
            LabAvatar(s.initials),
            const SizedBox(width: 10),
            Expanded(
              child: LabColumn(
                gap: 2,
                children: [
                  Text(s.name, style: labText(14, w: kBold)),
                  Text(s.nim,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            item.graded
                ? const LabChip.live('Sudah Dinilai')
                : const LabChip.warn('Belum Dinilai'),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in item.files)
              AslabFilePill(icon: f.$1, text: f.$2),
          ],
        ),
        LabButtonPair(
          left: LabOutlineButton(
              icon: 'download', label: 'Unduh Tugas', onTap: onDownload),
          right: LabPrimaryButton(
            icon: 'pencil',
            label: item.graded ? 'Ubah Nilai' : 'Beri Nilai',
            onTap: onGrade,
          ),
        ),
      ],
    );
  }
}
