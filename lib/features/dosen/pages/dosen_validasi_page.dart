import 'package:flutter/material.dart';

import '../../../core/services/file_download_service.dart';
import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../shared/lab_actions.dart';
import '../dosen_store.dart';
import '../widgets/dosen_ui.dart';
import 'dosen_minta_revisi_page.dart';
import 'dosen_rekap_nilai_page.dart';

/// Figma: "Validasi Nilai Akhir-Dosen". Status "Tervalidasi" disimpan di
/// BE melalui [NilaiSyncService] dan langsung terkunci di Aslab & Praktikan.
class DosenValidasiPage extends StatefulWidget {
  final DosenStore store;

  /// Logo ITLG di halaman detail: kembali ke Beranda.
  final VoidCallback onHome;

  const DosenValidasiPage({
    super.key,
    required this.store,
    required this.onHome,
  });

  @override
  State<DosenValidasiPage> createState() => _DosenValidasiPageState();
}

class _DosenValidasiPageState extends State<DosenValidasiPage> {
  @override
  void initState() {
    super.initState();
    NilaiSyncService.instance.refreshFromBackend();
    PraktikumSyncService.instance.refreshFromBackend();
  }

  Future<void> _pickCourse() async {
    final courses = PraktikumSyncService.instance.courses;
    final currentId = NilaiSyncService.instance.selectedCourseId;
    final currentIdx = courses.indexWhere((c) => c.id == currentId);
    final picked = await dosenShowPicker(
      context,
      title: 'Pilih Praktikum',
      options: [for (final c in courses) '${c.name} (${c.kelas})'],
      selected: currentIdx < 0 ? 0 : currentIdx,
    );
    if (picked != null && picked < courses.length) {
      NilaiSyncService.instance.selectCourse(courses[picked].id);
    }
  }

  Future<void> _validate(String courseId, String kelasLabel) async {
    widget.store.validated = true;
    await NilaiSyncService.instance.validateCourse(
      courseId: courseId,
      validatedBy: AuthController.instance.userName,
    );
    if (!mounted) return;
    dosenShowResult(
      context,
      icon: 'circle_check',
      title: 'Nilai Tervalidasi',
      message: 'Nilai akhir $kelasLabel berhasil disinkronkan ke '
          'Portal Akademik.',
      button: 'Selesai',
    );
  }

  void _showGradeDetail(
    DosenGrade g,
    String courseId,
    String courseName,
    String kelas,
    List<DosenGrade> allGrades,
  ) {
    final val = NilaiSyncService.instance.validationFor(courseId);
    final statusVal = val.isValidated
        ? 'Tervalidasi'
        : (val.isRevisionRequested ? 'Revisi Diminta' : 'Menunggu Validasi');
    labShowInfoSheet(
      context,
      title: 'Detail Nilai • ${g.name}',
      rows: [
        ('card_account_details_outline', 'NIM', g.nim),
        ('book_open', 'Praktikum', '$courseName ($kelas)'),
        ('clipboard', 'Nilai Tugas', g.tugas),
        ('people_group', 'Presensi', g.presensi),
        ('trophy', 'Nilai Akhir', '${g.akhir} (${g.huruf})'),
        ('circle_check', 'Status', g.lulus ? 'Lulus • $statusVal' : 'Tidak Lulus • $statusVal'),
      ],
      primary: (
        'download',
        'Unduh Rekap Kelas (.xlsx)',
        () async {
          final fname = 'Rekap_Nilai_${courseId.toUpperCase()}.xlsx';
          final res = await FileDownloadService.instance.downloadFile(
            fileName: fname,
            source: 'Rekap Nilai Akhir • $courseName',
            spreadsheetRows: [
              ['NIM', 'Nama Praktikan', 'Tugas', 'Presensi', 'Nilai Akhir', 'Huruf', 'Status'],
              for (final r in allGrades)
                [r.nim, r.name, r.tugas, r.presensi, r.akhir, r.huruf, r.lulus ? 'Lulus' : 'Tidak Lulus'],
            ],
          );
          if (!mounted) return;
          labToast(
            context,
            res.success
                ? 'Tersimpan di ${res.location}'
                : 'Gagal mengunduh $fname',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final nilaiSync = NilaiSyncService.instance;
    final praktikumSync = PraktikumSyncService.instance;
    final presensiSync = PresensiSyncService.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([nilaiSync, praktikumSync, presensiSync]),
      builder: (context, _) {
        final courseId = nilaiSync.selectedCourseId;
        final course = praktikumSync.courseById(courseId);
        final valRec = nilaiSync.validationFor(courseId);
        final done = valRec.isValidated;
        final liveAll =
            nilaiSync.liveDosenGrades(store.grades, courseId: courseId);
        final livePreview = liveAll.take(5).toList();
        final summary = nilaiSync.summarizeGrades(liveAll);
        final othersCount = (liveAll.length - livePreview.length).clamp(0, 999);

        return LabTabBody(
          children: [
            LabCard(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: done
                        ? const LabChip.live('Tervalidasi', key: ValueKey('ok'))
                        : (valRec.isRevisionRequested
                            ? const LabChip.danger('Revisi Diminta',
                                key: ValueKey('rev'))
                            : const LabChip.warn('Menunggu Validasi',
                                key: ValueKey('wait'))),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _pickCourse,
                  child: DosenClassTitle(
                    code: course.kelas,
                    courseName: course.name,
                  ),
                ),
                LabStatRow(
                  stats: [
                    LabStat(
                      icon: 'people_group',
                      label: 'Praktikan',
                      value: '${summary.totalCount}',
                    ),
                    LabStat(
                      icon: 'trophy',
                      label: 'Rata-rata',
                      value: summary.avgScore,
                    ),
                    LabStat(
                      icon: 'check',
                      label: 'Lulus',
                      value: '${summary.passCount}',
                    ),
                  ],
                ),
                LabMeta(
                  icon: 'people_group',
                  text: 'Dinilai oleh ${course.asisten} & Tim Asisten',
                ),
              ],
            ),
            LabCard(
              children: [
                Row(
                  children: [
                    const LabSectionTitle(
                        icon: 'clipboard', text: 'Rekap Nilai Akhir'),
                    const Spacer(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _pickCourse,
                      child: Text('${course.meetings.length} / 12 Modul',
                          style: labText(12, c: ItlgColors.primary)),
                    ),
                  ],
                ),
                DosenGradeTable(
                  grades: livePreview,
                  onTapGrade: (g) => _showGradeDetail(
                      g, courseId, course.name, course.kelas, liveAll),
                ),
                LabOutlineButton(
                  icon: 'chevron_down',
                  label: 'Lihat $othersCount Praktikan Lainnya',
                  onTap: () => labPush(
                    context,
                    DosenRekapNilaiPage(
                      store: store,
                      courseId: courseId,
                      onLogoTap: widget.onHome,
                    ),
                  ),
                ),
              ],
            ),
            done
                ? const DosenInfoBox(
                    icon: 'circle_check',
                    text: 'Nilai akhir telah disinkronkan ke Portal Akademik dan '
                        'tidak dapat diubah lagi oleh asisten.',
                  )
                : const DosenInfoBox(
                    icon: 'arrow_cycle',
                    text: 'Setelah divalidasi, nilai akhir disinkronkan ke Portal '
                        'Akademik dan tidak dapat diubah lagi oleh asisten.',
                  ),
            if (done)
              const DosenDisabledButton(
                  icon: 'check', label: 'Sudah Divalidasi')
            else
              LabColumn(
                gap: 12,
                children: [
                  LabPrimaryButton(
                    icon: 'check',
                    label: 'Validasi & Sinkronkan Nilai',
                    large: true,
                    onTap: () => _validate(courseId, course.kelas),
                  ),
                  LabOutlineButton(
                    icon: 'pencil',
                    label: 'Minta Revisi ke Asisten',
                    large: true,
                    onTap: () => labPush(
                      context,
                      DosenMintaRevisiPage(
                        courseId: courseId,
                        onLogoTap: widget.onHome,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
