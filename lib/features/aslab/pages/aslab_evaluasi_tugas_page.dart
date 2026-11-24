import 'package:flutter/material.dart';

import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../../shared/lab_actions.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';
import '../widgets/aslab_ui.dart';

/// Halaman Evaluasi Tugas Asisten Lab.
class AslabEvaluasiTugasPage extends StatefulWidget {
  final AslabNav nav;
  final String courseId;
  final int meetingNumber;
  const AslabEvaluasiTugasPage({
    super.key,
    required this.nav,
    this.courseId = 'pemob',
    this.meetingNumber = 4,
  });

  @override
  State<AslabEvaluasiTugasPage> createState() => _AslabEvaluasiTugasPageState();
}

class _Submission {
  final AslabStudent student;
  final bool graded;
  final List<(String, String)> files;

  /// Ukuran berkas per nama (mis. "352 KB"), diambil dari metadata unggahan.
  final Map<String, String> sizes;
  const _Submission(this.student, this.graded, this.files,
      {this.sizes = const {}});

  /// Item pertama yang benar-benar berkas (bukan tautan / penanda sanggahan).
  (String, String)? get firstFile {
    for (final f in files) {
      if (f.$1 == 'file' || f.$1 == 'attach') return f;
    }
    return null;
  }
}

class _AslabEvaluasiTugasPageState extends State<AslabEvaluasiTugasPage> {
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
    final nilaiSync = NilaiSyncService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([sync, nilaiSync]),
      builder: (context, _) {
        final course = sync.courseById(widget.courseId);
        final dynamicSubs = <_Submission>[];

        String initialsOf(String name) {
          final parts = name.trim().split(RegExp(r'\s+'));
          if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
            return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
          }
          return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'PR';
        }

        // Sanggahan hanya yang terkait modul/pertemuan ini.
        final appealsByNim = {
          for (final ap in nilaiSync.pendingAppealsForCourse(course.id))
            if (ap.modul == widget.meetingNumber) ap.userIdentifier: ap,
        };

        for (final rec
            in sync.submissionsForCourse(course.id, widget.meetingNumber)) {
          final ap = appealsByNim.remove(rec.userIdentifier);
          dynamicSubs.add(
            _Submission(
              AslabStudent(
                  initialsOf(rec.userName), rec.userName, rec.userIdentifier),
              rec.status == 'graded',
              [
                for (final f in rec.files) ('file', f.name),
                if (rec.repoUrl.isNotEmpty) ('link_chain', rec.repoUrl),
                if (ap != null) ('chat_bubble', 'Sanggahan Modul ${ap.modul}'),
              ],
              sizes: {
                for (final f in rec.files)
                  if (f.meta.split(' • ').length >= 2)
                    f.name: f.meta.split(' • ')[1],
              },
            ),
          );
        }
        // Sanggahan modul ini dari praktikan yang belum tercatat mengumpulkan.
        for (final ap in appealsByNim.values) {
          dynamicSubs.add(
            _Submission(
              AslabStudent(
                  initialsOf(ap.userName), ap.userName, ap.userIdentifier),
              false,
              [
                ('chat_bubble', 'Sanggahan Modul ${ap.modul}'),
                if (ap.attachmentName != null && ap.attachmentName!.isNotEmpty)
                  ('attach', ap.attachmentName!),
              ],
            ),
          );
        }
        final items = dynamicSubs.where(_match).toList();
        final waitingCount = dynamicSubs.where((s) => !s.graded).length;
        final gradedCount = dynamicSubs.where((s) => s.graded).length;
        // Kartu sanggahan tanpa pengumpulan tidak dihitung "Terkumpul".
        final totalCount =
            sync.submissionsForCourse(course.id, widget.meetingNumber).length;
        final meeting = sync.meetingFor(course.id, widget.meetingNumber);
        final tugasTitle = (meeting != null && meeting.tugasTitle.isNotEmpty)
            ? meeting.tugasTitle
            : course.tugasTitle;
        final tugasDeadline =
            (meeting != null && meeting.tugasDeadline.isNotEmpty)
                ? meeting.tugasDeadline
                : course.tugasDeadline;
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
                  left: LabTag.red('Tugas ${widget.meetingNumber}'),
                  right: LabMeta(icon: 'clock', text: tugasDeadline),
                ),
                Text(
                  tugasTitle.replaceFirst(
                      'Tugas ${widget.meetingNumber} : ', ''),
                  style: labText(16, w: kBold, c: Colors.black),
                ),
                LabStatRow(
                  stats: [
                    LabStat(
                      icon: 'file',
                      label: 'Terkumpul',
                      value: '$totalCount',
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
                onDownload: () {
                  final f = s.firstFile;
                  if (f != null) {
                    labShowFilePreview(
                      context,
                      name: f.$2,
                      size: s.sizes[f.$2] ?? 'Berkas',
                      source:
                          'Tugas ${widget.meetingNumber} • ${s.student.name}',
                    );
                  } else {
                    labToast(context,
                        '${s.student.name} hanya mengirim tautan, tidak ada berkas');
                  }
                },
                onGrade: () => widget.nav.penilaianTugas(
                  context,
                  student: s.student,
                  courseId: course.id,
                  meetingNumber: widget.meetingNumber,
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
