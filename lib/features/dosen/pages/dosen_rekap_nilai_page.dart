import 'package:flutter/material.dart';

import '../../../core/services/file_download_service.dart';
import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../shared/lab_actions.dart';
import '../dosen_store.dart';
import '../widgets/dosen_ui.dart';

/// Figma: "Rekap Nilai Akhir-Dosen" (dari "Lihat 19 Praktikan Lainnya").
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

  /// 0 Semua, 1 Lulus, 2 Tidak Lulus.
  int _tab = 0;

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
    final fname = 'Rekap_Nilai_${widget.courseId.toUpperCase()}.xlsx';
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
    final val = NilaiSyncService.instance.validationFor(widget.courseId);
    final statusVal = val.isValidated
        ? 'Tervalidasi'
        : (val.isRevisionRequested ? 'Revisi Diminta' : 'Menunggu Validasi');
    labShowInfoSheet(
      context,
      title: 'Rincian Nilai • ${g.name}',
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
        () => _exportRecap(courseName, allGrades),
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
        final course = praktikumSync.courseById(widget.courseId);
        final all = nilaiSync.liveDosenGrades(
          widget.store.grades,
          courseId: widget.courseId,
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
            LabTitle(
              title: 'Rekap Nilai Akhir',
              subtitle:
                  '${course.name} (${course.kelas}) • ${all.length} praktikan',
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
