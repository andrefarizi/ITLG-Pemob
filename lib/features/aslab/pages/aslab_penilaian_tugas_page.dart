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

/// Figma: "Penilaian Tugas-Aslab".
///
/// Nilai tiap rubrik bisa diketik; total dan batang progres ikut berubah.
class AslabPenilaianTugasPage extends StatefulWidget {
  final AslabNav nav;
  final AslabStudent student;
  final String courseId;
  final int meetingNumber;

  const AslabPenilaianTugasPage({
    super.key,
    required this.nav,
    this.student = kRina,
    this.courseId = 'pemob',
    this.meetingNumber = 4,
  });

  @override
  State<AslabPenilaianTugasPage> createState() =>
      _AslabPenilaianTugasPageState();
}

class _AslabPenilaianTugasPageState extends State<AslabPenilaianTugasPage> {
  static const List<(String, String, int, int)> _rubrik = [
    ('Kebenaran Implementasi', 'Sesuai spesifikasi modul & alur program', 35,
        40),
    ('Pengujian & Hasil', 'Berjalan tanpa error dan hasil sesuai', 38, 40),
    ('Kerapian Laporan', 'Struktur, penjelasan, tangkapan layar', 15, 20),
  ];

  late final List<TextEditingController> _scores;
  late final TextEditingController _catatan;

  @override
  void initState() {
    super.initState();
    final pendingAppeal = NilaiSyncService.instance
        .pendingAppealForStudent(widget.courseId, widget.student.nim);
    final targetModul = pendingAppeal?.modul ?? widget.meetingNumber;
    final existing = PraktikumSyncService.instance
        .submissionFor(widget.courseId, targetModul, widget.student.nim);
    final prevScore = existing?.score;
    if (prevScore != null) {
      final s0 = ((prevScore * 40) / 100).round().clamp(0, 40);
      final s1 = ((prevScore * 40) / 100).round().clamp(0, 40);
      final s2 = (prevScore - s0 - s1).clamp(0, 20);
      _scores = [
        TextEditingController(text: '$s0'),
        TextEditingController(text: '$s1'),
        TextEditingController(text: '$s2'),
      ];
    } else {
      _scores = [
        for (final r in _rubrik) TextEditingController(text: '${r.$3}'),
      ];
    }
    _catatan = TextEditingController(
      text: (existing?.feedback != null && existing!.feedback!.isNotEmpty)
          ? existing.feedback!
          : 'Implementasi sudah baik dan sesuai instruksi modul.',
    );
  }

  @override
  void dispose() {
    for (final c in _scores) {
      c.dispose();
    }
    _catatan.dispose();
    super.dispose();
  }

  int _value(int i) {
    final v = int.tryParse(_scores[i].text.trim()) ?? 0;
    return v.clamp(0, _rubrik[i].$4).toInt();
  }

  int get _total {
    var t = 0;
    for (var i = 0; i < _rubrik.length; i++) {
      t += _value(i);
    }
    return t;
  }

  Future<void> _simpan() async {
    if (NilaiSyncService.instance.isCourseValidated(widget.courseId)) {
      labToast(
        context,
        'Nilai kelas ini sudah divalidasi dosen dan tidak dapat diubah',
      );
      return;
    }
    final pendingAppeal = NilaiSyncService.instance
        .pendingAppealForStudent(widget.courseId, widget.student.nim);
    final targetModul = pendingAppeal?.modul ?? widget.meetingNumber;
    await PraktikumSyncService.instance.gradeTugasSubmission(
      courseId: widget.courseId,
      meetingNumber: targetModul,
      userIdentifier: widget.student.nim,
      userName: widget.student.name,
      score: _total,
      feedback: _catatan.text.trim(),
    );
    if (pendingAppeal != null) {
      await NilaiSyncService.instance.resolveAppeal(
        courseId: widget.courseId,
        modul: targetModul,
        userIdentifier: widget.student.nim,
        newScore: _total,
        feedback: _catatan.text.trim(),
      );
    }
    if (!mounted) return;
    Navigator.of(context).maybePop();
    labToast(
      context,
      pendingAppeal != null
          ? 'Sanggahan Modul $targetModul selesai • Nilai ${widget.student.name}: $_total / 100'
          : 'Nilai ${widget.student.name} disimpan: $_total / 100',
    );
  }

  String _formatSubmittedAt(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return 'Dikumpulkan $hh:$mm WIB, ${local.day} ${months[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final sync = PraktikumSyncService.instance;
    final nilaiSync = NilaiSyncService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([sync, nilaiSync]),
      builder: (context, _) {
        final course = sync.courseById(widget.courseId);
        final pendingAppeal =
            nilaiSync.pendingAppealForStudent(course.id, s.nim);
        final targetModul = pendingAppeal?.modul ?? widget.meetingNumber;
        final meeting = sync.meetingFor(course.id, targetModul);
        final existing = sync.submissionFor(course.id, targetModul, s.nim);
        final isGraded = existing?.status == 'graded' && pendingAppeal == null;
        final tugasTitle = (meeting != null && meeting.tugasTitle.isNotEmpty)
            ? meeting.tugasTitle
            : course.tugasTitle;
        final hasRealFiles = existing != null &&
            (existing.files.isNotEmpty || existing.repoUrl.isNotEmpty);

        return LabSubPage(
          onLogoTap: widget.nav.home,
          children: [
            LabCard(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: pendingAppeal != null
                      ? LabChip.danger(
                          'Sanggah Nilai • Modul ${pendingAppeal.modul}')
                      : (isGraded
                          ? const LabChip.live('Sudah Dinilai')
                          : const LabChip.warn('Belum Dinilai')),
                ),
                LabOverline(
                  overline: 'Praktikum ${course.name}',
                  title: pendingAppeal != null
                      ? 'Tinjau Sanggahan Modul ${pendingAppeal.modul}'
                      : tugasTitle,
                ),
                LabPerson(
                  initials: s.initials,
                  name: s.name,
                  caption: '${s.nim} • ${course.kelas}',
                ),
                if (pendingAppeal != null)
                  LabMeta(
                    icon: 'chat_bubble',
                    text: 'Alasan: ${pendingAppeal.reason}',
                  ),
                if (existing != null && existing.note.isNotEmpty)
                  LabMeta(
                    icon: 'file',
                    text: 'Catatan praktikan: ${existing.note}',
                  ),
                LabMeta(
                  icon: 'clock',
                  text: existing != null
                      ? _formatSubmittedAt(existing.updatedAt)
                      : 'Dikumpulkan Senin 10:12 WIB, 29 September 2026',
                ),
              ],
            ),
            LabCard(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: LabSectionTitle(
                      icon: 'download', text: 'Berkas Praktikan'),
                ),
                LabColumn(
                  gap: 8,
                  children: [
                    if (pendingAppeal?.attachmentName != null &&
                        pendingAppeal!.attachmentName!.isNotEmpty)
                      _FileRow(
                        icon: 'attach',
                        title: pendingAppeal.attachmentName!,
                        meta: 'Lampiran Bukti Sanggahan',
                        action: 'download',
                        onTap: () => labShowFilePreview(
                          context,
                          name: pendingAppeal.attachmentName!,
                          source: 'Bukti Sanggahan • ${s.name}',
                        ),
                      ),
                    if (hasRealFiles) ...[
                      for (final f in existing.files)
                        _FileRow(
                          icon: 'file',
                          title: f.name,
                          meta: f.meta,
                          action: 'download',
                          onTap: () => labShowFilePreview(
                            context,
                            name: f.name,
                            size: f.meta,
                            source: 'Tugas $targetModul • ${s.name}',
                          ),
                        ),
                      if (existing.repoUrl.isNotEmpty)
                        _FileRow(
                          icon: 'link_chain',
                          title: existing.repoUrl,
                          meta: 'Tautan Repositori Kode',
                          action: 'chevron_right',
                          onTap: () => labShowLink(
                            context,
                            url: existing.repoUrl.startsWith('http')
                                ? existing.repoUrl
                                : 'https://${existing.repoUrl}',
                          ),
                        ),
                    ] else ...[
                      _FileRow(
                        icon: 'file',
                        title: 'laporan_tugas$targetModul.pdf',
                        meta: 'Laporan PDF • 1,2 MB',
                        action: 'download',
                        onTap: () => labShowFilePreview(
                          context,
                          name: 'laporan_tugas$targetModul.pdf',
                          size: '1,2 MB',
                          source: 'Tugas $targetModul • ${s.name}',
                        ),
                      ),
                      _FileRow(
                        icon: 'link_chain',
                        title:
                            'github.com/${s.name.toLowerCase().replaceAll(' ', '')}/tugas-$targetModul',
                        meta: 'Tautan Repositori Kode',
                        action: 'chevron_right',
                        onTap: () => labShowLink(
                          context,
                          url:
                              'https://github.com/${s.name.toLowerCase().replaceAll(' ', '')}/tugas-$targetModul',
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            LabCard(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: LabSectionTitle(
                      icon: 'clipboard', text: 'Rubrik Penilaian'),
                ),
                for (var i = 0; i < _rubrik.length; i++)
                  LabColumn(
                    gap: 8,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: LabColumn(
                              gap: 2,
                              children: [
                                Text(_rubrik[i].$1,
                                    style: labText(12, w: kBold)),
                                Text(_rubrik[i].$2,
                                    style: labText(11,
                                        w: kMedium, c: ItlgColors.textSubtle)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AslabScoreInput(
                            controller: _scores[i],
                            max: _rubrik[i].$4,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                      PrakTrack(
                        fraction: _value(i) / _rubrik[i].$4,
                        color: ItlgColors.primary,
                      ),
                    ],
                  ),
                Container(height: 1, color: const Color(0x80B5B9BC)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text('Total Nilai',
                          style: labText(16, w: kBold, c: Colors.black)),
                    ),
                    Text('$_total',
                        style: labText(22, w: kBold, c: ItlgColors.primary)),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('/ 100',
                          style: labText(11,
                              w: kMedium, c: ItlgColors.textSubtle)),
                    ),
                  ],
                ),
              ],
            ),
            LabCard(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: LabSectionTitle(
                      icon: 'chat_bubble', text: 'Feedback untuk Praktikan'),
                ),
                PrakField(
                  label: 'Catatan Evaluasi :',
                  child: PrakTextArea(controller: _catatan, height: 120),
                ),
              ],
            ),
            LabPrimaryButton(
              icon: 'check',
              label: 'Simpan Nilai',
              large: true,
              onTap: _simpan,
            ),
          ],
        );
      },
    );
  }
}

/// Baris berkas 58 px dengan kotak ikon timbul 36 px.
class _FileRow extends StatelessWidget {
  final String icon;
  final String title;
  final String meta;
  final String action;
  final VoidCallback onTap;

  const _FileRow({
    required this.icon,
    required this.title,
    required this.meta,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LabListItem(
      leading: LabIconTile(icon),
      title: title,
      subtitle: meta,
      titleSize: 12,
      trailing: LabIcon(action, size: 18, color: ItlgColors.primary),
      onTap: onTap,
    );
  }
}
