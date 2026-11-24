import 'package:flutter/material.dart';

import '../../../core/services/file_download_service.dart';
import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../dosen_store.dart';
import '../widgets/dosen_ui.dart';

/// Halaman Rekap Nilai Akhir Dosen.
class DosenRekapNilaiPage extends StatefulWidget {
  final DosenStore store;
  final String courseId;
  final VoidCallback? onLogoTap;

  const DosenRekapNilaiPage({
    super.key,
    required this.store,
    this.courseId = 'pemob',
    this.onLogoTap,
  });

  @override
  State<DosenRekapNilaiPage> createState() => _DosenRekapNilaiPageState();
}

class _DosenRekapNilaiPageState extends State<DosenRekapNilaiPage> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  late String _activeCourseId = widget.courseId;

  /// 0 Semua, 1 Lulus, 2 Tidak Lulus.
  int _tab = 0;

  Future<void> _pickCourse() async {
    final courses = PraktikumSyncService.instance.courses;
    final idx = courses.indexWhere((c) => c.id == _activeCourseId);
    final picked = await dosenShowPicker(
      context,
      title: 'Ganti Praktikum',
      options: [for (final c in courses) '${c.name} (${c.kelas})'],
      selected: idx < 0 ? 0 : idx,
    );
    if (picked != null && picked < courses.length && mounted) {
      setState(() => _activeCourseId = courses[picked].id);
      NilaiSyncService.instance.selectCourse(courses[picked].id);
    }
  }

  @override
  void initState() {
    super.initState();
    NilaiSyncService.instance.refreshFromBackend();
    PraktikumSyncService.instance.refreshFromBackend();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _exportRecap(String courseName, List<DosenGrade> grades) async {
    final fname = 'Rekap_Nilai_${_activeCourseId.toUpperCase()}.xlsx';
    final res = await FileDownloadService.instance.downloadFile(
      fileName: fname,
      source: 'Rekap Nilai Akhir • $courseName',
      spreadsheetRows: [
        ['NIM', 'Nama Praktikan', 'Tugas', 'Presensi', 'Nilai Akhir', 'Huruf', 'Status'],
        for (final g in grades)
          [
            g.nim,
            g.name,
            g.tugas,
            g.presensi,
            g.akhir,
            g.huruf,
            g.lulus ? 'Lulus' : 'Tidak Lulus',
          ],
      ],
    );
    if (res.success) {
      await NilaiSyncService.instance.recordReportDownload(
        title: 'Rekap Nilai Akhir $courseName',
        courseName: courseName,
        fileName: res.fileName,
        format: 'XLSX',
        sizeLabel: res.formattedSize,
        localPath: res.location,
        downloadedBy: AuthController.instance.userName,
      );
    }
    if (!mounted) return;
    labToast(
      context,
      res.success ? 'Tersimpan di ${res.location}' : 'Gagal mengunduh $fname',
    );
  }

  void _showStudentDetail(
    DosenGrade g,
    String courseName,
    String kelas,
    List<DosenGrade> allGrades,
  ) {
    final rows = NilaiSyncService.instance.moduleBreakdownForStudent(
      courseId: _activeCourseId,
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
    final hasAppeal = NilaiSyncService.instance
            .pendingAppealForStudent(_activeCourseId, g.nim) !=
        null;
    final infoText = lowest != null
        ? '${lowest.label} paling rendah (${lowest.score}).${hasAppeal ? ' Nilai tugas sedang dalam sanggahan.' : ' Nilai sudah disinkronkan dari penilaian asisten.'}'
        : 'Rincian nilai per modul tersinkron otomatis.';

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
    final nilaiSync = NilaiSyncService.instance;
    final praktikumSync = PraktikumSyncService.instance;
    final presensiSync = PresensiSyncService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([nilaiSync, praktikumSync, presensiSync]),
      builder: (context, _) {
        final course = praktikumSync.courseById(_activeCourseId);
        final all = nilaiSync.liveDosenGrades(
          widget.store.grades,
          courseId: _activeCourseId,
        );
        final lulus = all.where((g) => g.lulus).length;
        final q = _query.trim().toLowerCase();
        final shown = all.where((g) {
          if (_tab == 1 && !g.lulus) return false;
          if (_tab == 2 && g.lulus) return false;
          return q.isEmpty ||
              g.name.toLowerCase().contains(q) ||
              g.nim.contains(q);
        }).toList();

        return LabSubPage(
          onLogoTap: widget.onLogoTap,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LabTitle(
                    title: 'Rekap Nilai Akhir',
                    subtitle:
                        '${course.name} (${course.kelas}) • ${all.length} praktikan',
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _pickCourse,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ItlgShadows.outline,
                    ),
                    child: Text('Ganti Praktikum',
                        style: labText(11, w: kBold, c: ItlgColors.primary)),
                  ),
                ),
              ],
            ),
            DosenSearchField(
              hint: 'Cari nama atau NIM praktikan...',
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              filterActive: _tab != 0,
              onFilter: () async {
                final i = await dosenShowPicker(
                  context,
                  title: 'Filter Status Kelulusan',
                  options: [
                    'Semua (${all.length})',
                    'Lulus ($lulus)',
                    'Tidak Lulus (${all.length - lulus})',
                  ],
                  selected: _tab,
                );
                if (i != null && mounted) setState(() => _tab = i);
              },
            ),
            LabTabs(
              labels: [
                'Semua (${all.length})',
                'Lulus ($lulus)',
                'Tidak Lulus (${all.length - lulus})',
              ],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
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
                      onTap: () => _exportRecap(course.name, shown),
                      child: Text('Unduh .xlsx',
                          style: labText(12, c: ItlgColors.primary)),
                    ),
                  ],
                ),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Tidak ada praktikan yang cocok.',
                      textAlign: TextAlign.center,
                      style: labText(12, c: ItlgColors.textSubtle),
                    ),
                  )
                else
                  DosenGradeTable(
                    grades: shown,
                    onTapGrade: (g) => _showStudentDetail(
                        g, course.name, course.kelas, all),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
