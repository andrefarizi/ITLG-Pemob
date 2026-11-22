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

  const AslabPenilaianTugasPage({
    super.key,
    required this.nav,
    this.student = kRina,
    this.courseId = 'pemob',
  });

  @override
  State<AslabPenilaianTugasPage> createState() =>
      _AslabPenilaianTugasPageState();
}

class _AslabPenilaianTugasPageState extends State<AslabPenilaianTugasPage> {
  static const List<(String, String, int, int)> _rubrik = [
    ('Kebenaran Relasi Database', 'Kardinalitas, primary & foreign key', 35,
        40),
    ('Eksekusi Query', 'Query berjalan dan hasil sesuai', 38, 40),
    ('Kerapian Laporan', 'Struktur, penjelasan, tangkapan layar', 15, 20),
  ];

  late final List<TextEditingController> _scores = [
    for (final r in _rubrik) TextEditingController(text: '${r.$3}'),
  ];
  final TextEditingController _catatan = TextEditingController(
      text: 'Relasi antar tabel sudah tepat. Query JOIN pada soal 3 masih '
          'menghasilkan duplikasi, gunakan DISTINCT atau perbaiki kondisi '
          'JOIN.');

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
    final targetModul = pendingAppeal?.modul ?? 4;
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

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final course = PraktikumSyncService.instance.courseById(widget.courseId);
    final pendingAppeal =
        NilaiSyncService.instance.pendingAppealForStudent(course.id, s.nim);
    final targetModul = pendingAppeal?.modul ?? 4;
    final existing =
        PraktikumSyncService.instance.submissionFor(course.id, targetModul, s.nim);
    final isGraded = existing?.status == 'graded' && pendingAppeal == null;
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: pendingAppeal != null
                  ? LabChip.danger('Sanggah Nilai • Modul ${pendingAppeal.modul}')
                  : (isGraded
                      ? const LabChip.live('Sudah Dinilai')
                      : const LabChip.warn('Belum Dinilai')),
            ),
            LabOverline(
              overline: 'Praktikum ${course.name}',
              title: pendingAppeal != null
                  ? 'Tinjau Sanggahan Modul ${pendingAppeal.modul}'
                  : course.tugasTitle,
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
            const LabMeta(
              icon: 'clock',
              text: 'Dikumpulkan Senin 10:12 WIB, 29 September 2026',
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child:
                  LabSectionTitle(icon: 'download', text: 'Berkas Praktikan'),
            ),
            LabColumn(
              gap: 8,
              children: [
                _FileRow(
                  icon: 'file',
                  title: 'laporan_erd.pdf',
                  meta: 'Laporan PDF • 1,2 MB',
                  action: 'download',
                  onTap: () => labToast(context, 'laporan_erd.pdf diunduh'),
                ),
                _FileRow(
                  icon: 'database_outline',
                  title: 'query_tugas4.sql',
                  meta: 'Script Query SQL • 14 KB',
                  action: 'download',
                  onTap: () => labToast(context, 'query_tugas4.sql diunduh'),
                ),
                _FileRow(
                  icon: 'link_chain',
                  title: 'github.com/rinanovita/erd-toko',
                  meta: 'Tautan Repositori Kode',
                  action: 'chevron_right',
                  onTap: () => labShowLink(
                      context, url: 'https://github.com/rinanovita/erd-toko'),
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
                            Text(_rubrik[i].$1, style: labText(12, w: kBold)),
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
