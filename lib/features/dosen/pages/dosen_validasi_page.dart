import 'package:flutter/material.dart';

import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../aslab/pages/aslab_sanggahan_nilai_page.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../dosen_store.dart';
import '../widgets/dosen_ui.dart';
import 'dosen_minta_revisi_page.dart';
import 'dosen_rekap_nilai_page.dart';

/// Halaman Validasi Nilai Akhir Dosen.
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
    final nilai = NilaiSyncService.instance;
    if (nilai.pendingDosenAppealCount > 0) {
      labToast(context,
          'Putuskan dulu sanggahan nilai yang menunggu sebelum validasi',
          error: true);
      return;
    }
    // Validasi mengunci nilai & tidak bisa dibatalkan dari aplikasi.
    final ok = await labShowConfirmDialog(
      context,
      icon: 'circle_check',
      title: 'Validasi Nilai Akhir?',
      message: 'Nilai $kelasLabel akan dikunci dan tidak dapat diubah asisten '
          'setelah divalidasi.',
      confirmLabel: 'Validasi',
    );
    if (!ok || !mounted) return;
    try {
      await nilai.validateCourse(
        courseId: courseId,
        validatedBy: AuthController.instance.userName,
      );
    } on StateError catch (e) {
      if (mounted) labToast(context, e.message);
      return;
    }
    widget.store.validated = true;
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

  /// Bottom sheet Rincian Nilai per Modul (Dosen).
  void _showGradeDetail(
    DosenGrade g,
    String courseId,
    String courseName,
    String kelas,
    List<DosenGrade> allGrades,
  ) {
    final rows = NilaiSyncService.instance.moduleBreakdownForStudent(
      courseId: courseId,
      nim: g.nim,
      fallbackBase: int.tryParse(g.tugas),
    );
    ({String label, int score})? lowest;
    for (final r in rows) {
      if (r.finalScore != null &&
          (lowest == null || r.finalScore! < lowest.score)) {
        lowest = (label: r.label, score: r.finalScore!);
      }
    }
    final hasAppeal =
        NilaiSyncService.instance.pendingAppealForStudent(courseId, g.nim) !=
            null;
    final infoText = lowest != null
        ? '${lowest.label} paling rendah (${lowest.score}).${hasAppeal ? ' Nilai tugas sedang dalam sanggahan.' : ' Nilai sudah disinkronkan dari penilaian asisten.'}'
        : 'Rincian nilai per modul tersinkron langsung dari database.';

    labShowCustomSheet<void>(
      context,
      title: 'Rincian Nilai • ${g.name}',
      subtitle: '${g.nim} • $kelas • Nilai Akhir ${g.akhir} (${g.huruf})',
      child: LabColumn(
        gap: 14,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: ItlgColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text('Modul',
                            style: labText(11,
                                w: kBold, c: ItlgColors.textSubtle))),
                    Expanded(
                        flex: 2,
                        child: Text('Tugas',
                            textAlign: TextAlign.center,
                            style: labText(11,
                                w: kBold, c: ItlgColors.textSubtle))),
                    Expanded(
                        flex: 2,
                        child: Text('Kuis',
                            textAlign: TextAlign.center,
                            style: labText(11,
                                w: kBold, c: ItlgColors.textSubtle))),
                    Expanded(
                        flex: 2,
                        child: Text('Hadir',
                            textAlign: TextAlign.center,
                            style: labText(11,
                                w: kBold, c: ItlgColors.textSubtle))),
                    Expanded(
                        flex: 2,
                        child: Text('Nilai',
                            textAlign: TextAlign.right,
                            style: labText(11,
                                w: kBold, c: ItlgColors.textSubtle))),
                  ],
                ),
                const Divider(height: 18, color: Color(0xFFE7E9EC)),
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 16, color: Color(0xFFECEEF1)),
                  Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text(rows[i].label,
                              style: labText(12, w: kSemiBold))),
                      Expanded(
                          flex: 2,
                          child: Text(
                              rows[i].tugasScore != null
                                  ? '${rows[i].tugasScore}'
                                  : '—',
                              textAlign: TextAlign.center,
                              style: labText(
                                12,
                                w: (rows[i].tugasScore ?? 100) < 75
                                    ? kBold
                                    : kMedium,
                                c: (rows[i].tugasScore ?? 100) < 75
                                    ? ItlgColors.primary
                                    : ItlgColors.text,
                              ))),
                      Expanded(
                          flex: 2,
                          child: Text(
                              rows[i].kuisScore != null
                                  ? '${rows[i].kuisScore}'
                                  : '—',
                              textAlign: TextAlign.center,
                              style: labText(12))),
                      Expanded(
                          flex: 2,
                          child: Text(rows[i].hadir ? '✓' : 'Izin',
                              textAlign: TextAlign.center,
                              style: labText(12,
                                  w: kSemiBold, c: ItlgColors.text))),
                      Expanded(
                          flex: 2,
                          child: Text(
                              rows[i].finalScore != null
                                  ? '${rows[i].finalScore}'
                                  : '—',
                              textAlign: TextAlign.right,
                              style: labText(12,
                                  w: kBold, c: ItlgColors.primary))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          DosenInfoBox(icon: 'info', text: infoText),
        ],
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
        final pendingAppeals = nilaiSync.pendingDosenAppealCount;

        return LabTabBody(
          children: [
            LabCard(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: done
                        ? const LabChip.live('Tervalidasi',
                            key: ValueKey('ok'))
                        : (valRec.isRevisionRequested
                            ? const LabChip.danger('Revisi Diminta',
                                key: ValueKey('rev'))
                            : const LabChip.warn('Menunggu Validasi',
                                key: ValueKey('wait'))),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _pickCourse,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: ItlgShadows.outline,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Ganti Praktikum',
                              style: labText(12, w: kBold, c: Colors.black)),
                          const SizedBox(width: 8),
                          const LabIcon('chevron_down',
                              size: 12, color: ItlgColors.textSubtle),
                        ],
                      ),
                    ),
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
            // Kartu Pintasan "Sanggahan Nilai"
            LabListItem(
              leading: const LabIconTile('triangle_alert'),
              title: 'Sanggahan Nilai',
              subtitle: pendingAppeals > 0
                  ? '$pendingAppeals koreksi nilai menunggu keputusan anda'
                  : 'Semua sanggahan nilai sudah diputuskan',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pendingAppeals > 0) ...[
                    LabTag.red('$pendingAppeals Baru'),
                    const SizedBox(width: 6),
                  ],
                  const LabIcon('chevron_right',
                      size: 16, color: ItlgColors.primary),
                ],
              ),
              onTap: () => labPush(
                context,
                SanggahanNilaiReviewPage(
                  isDosen: true,
                  onLogoTap: widget.onHome,
                ),
              ),
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
                  label: othersCount > 0
                      ? 'Lihat $othersCount Praktikan Lainnya'
                      : 'Lihat Rekap Lengkap',
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
