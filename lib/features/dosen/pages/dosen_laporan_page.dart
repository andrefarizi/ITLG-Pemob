import 'package:flutter/material.dart';

import '../../praktikan/praktikan_store.dart';

import '../../../core/services/file_download_service.dart';
import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/services/shift_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../shared/profil_data.dart';
import '../dosen_store.dart';
import '../widgets/dosen_ui.dart';
import 'dosen_riwayat_page.dart';

/// Dialog Laporan Diunduh.
void dosenShowDownloaded(
  BuildContext context, {
  String? location,
}) =>
    dosenShowResult(
      context,
      icon: 'download',
      title: 'Laporan Diunduh',
      message: 'Berkas laporan tersimpan di folder Unduhan perangkat anda.',
      button: 'Selesai',
    );

/// Unduh berkas laporan nyata (XLSX atau PDF) ke folder `Download/ITLG Mobile/`
Future<DeviceDownloadResult> dosenDownloadReportFile({
  required String fileName,
  required String periode,
  required Set<int> sections,
  required DosenStore store,
  String? courseName,
}) {
  final prak = PraktikumSyncService.instance;
  final presensi = PresensiSyncService.instance;
  final nilai = NilaiSyncService.instance;
  final shift = ShiftSyncService.instance;
  // Hanya praktikum yang dipilih (bila ada), dengan data SELURUH kelas.
  // Unduh ulang dari riwayat hanya membawa nama berkas: simpulkan praktikum
  // dari nama berkas ("Laporan_Pemrograman_Mobile_...") agar isinya sama.
  final inferred = courseName ??
      prak.courses
          .where((c) => fileName.contains(c.name.replaceAll(' ', '_')))
          .map((c) => c.name)
          .firstOrNull;
  final courses = inferred == null
      ? prak.courses
      : prak.courses.where((c) => c.name == inferred).toList();

  final lines = <String>[
    'LAPORAN PRAKTIKUM ITLG - FASILKOM-TI USU',
    'Berkas  : $fileName',
    'Periode : $periode',
    'Dosen   : ${ProfilData.dosen.name}',
    '============================================================',
  ];

  final rows = <List<String>>[
    ['Praktikum', 'Asisten', 'Kehadiran (%)', 'Rata-rata Nilai', 'Status Validasi', 'Rating Asisten'],
  ];

  for (final c in courses) {
    final recs = presensi.recordsForCourse(c.id);
    final hadir = recs.where((r) => r.status == PrakAttend.hadir).length;
    final izin = recs.where((r) => r.status == PrakAttend.izin).length;
    final alpa = recs.where((r) => r.status == PrakAttend.alpa).length;
    final attPct = recs.isEmpty ? null : ((hadir * 100) / recs.length).round();
    final avgNum = prak.classAverageScoreForCourse(c.id);
    final avg =
        avgNum == null ? '-' : avgNum.toStringAsFixed(1).replaceAll('.', ',');
    final val = nilai.validationFor(c.id);
    final valStatus = val.isValidated
        ? 'Tervalidasi'
        : (val.isRevisionRequested ? 'Revisi Diminta' : 'Menunggu');
    final rating = prak.averageRatingLabelForCourse(c.id);
    final attLabel = attPct == null ? '-' : '$attPct%';

    rows.add([
      c.name,
      c.asisten,
      attLabel,
      avg,
      valStatus,
      rating == '-' ? '-' : '$rating / 5',
    ]);
    lines.add('${c.name} (${c.kelas}) | Asisten: ${c.asisten}');
    if (sections.contains(0)) {
      lines.add(
          '  - Kehadiran: $attLabel ($hadir Hadir, $izin Izin, $alpa Alpa dari ${recs.length} catatan)');
    }
    if (sections.contains(1)) {
      lines.add('  - Rata-rata Nilai: $avg | Validasi Dosen: $valStatus');
    }
  }

  // Pelaporan Nilai Akhir: rincian per praktikan dari data nyata.
  if (sections.contains(1)) {
    for (final c in courses) {
      final grades = nilai.liveDosenGrades(const [], courseId: c.id);
      if (grades.isEmpty) continue;
      lines.add('------------------------------------------------------------');
      lines.add('NILAI AKHIR ${c.name.toUpperCase()}:');
      rows.add([]);
      rows.add(['${c.name} • Praktikan', 'NIM', 'Tugas', 'Presensi', 'Akhir', 'Huruf']);
      for (final g in grades) {
        lines.add('  - ${g.name} (${g.nim}): tugas ${g.tugas}, presensi ${g.presensi}, akhir ${g.akhir} (${g.huruf})');
        rows.add([g.name, g.nim, g.tugas, g.presensi, g.akhir, g.huruf]);
      }
    }
  }

  if (sections.contains(2)) {
    lines.add('------------------------------------------------------------');
    lines.add('REKAP KEDISIPLINAN ASISTEN (Rata-rata ${shift.averageDisciplinePct}%):');
    rows.add([]);
    rows.add(['Asisten Lab', 'Shift', 'Ruangan', 'Status Presensi', 'Kedisiplinan', '']);
    for (final sh in shift.dutyAssistants) {
      lines.add(
        '  - ${sh.asistenName} (${sh.shiftLabel}, ${sh.room}): ${sh.attendanceStatus} | ${sh.disciplinePct}%',
      );
      rows.add([
        sh.asistenName,
        sh.shiftLabel,
        sh.room,
        sh.attendanceStatus,
        '${sh.disciplinePct}%',
        '',
      ]);
    }
  }

  return FileDownloadService.instance.downloadFile(
    fileName: fileName,
    source: 'Generate Laporan Dosen • $periode',
    contentLines: lines,
    spreadsheetRows: rows,
  );
}

/// Halaman Generate Laporan Dosen.
class DosenLaporanPage extends StatefulWidget {
  final DosenStore store;
  final VoidCallback onHome;

  const DosenLaporanPage({
    super.key,
    required this.store,
    required this.onHome,
  });

  @override
  State<DosenLaporanPage> createState() => _DosenLaporanPageState();
}

class _DosenLaporanPageState extends State<DosenLaporanPage> {
  static const List<List<String>> _isi = [
    ['Rekap Pelaksanaan Praktikum', 'Jadwal, modul, dan kehadiran per pertemuan'],
    ['Pelaporan Nilai Akhir', 'Akumulasi nilai tervalidasi seluruh praktikan'],
    ['Rekap Kedisiplinan Asisten', 'Presensi dan ketepatan waktu asisten'],
  ];

  Future<void> _pickPraktikum() async {
    final store = widget.store;
    final i = await dosenShowPicker(
      context,
      title: 'Pilih Praktikum',
      options: store.praktikumOptions,
      selected: store.praktikumIndex,
    );
    if (i != null && mounted) setState(() => store.praktikumIndex = i);
  }

  Future<void> _pickPeriode() async {
    final store = widget.store;
    final i = await dosenShowPicker(
      context,
      title: 'Pilih Periode',
      options: store.periodeOptions,
      selected: store.periodeIndex,
    );
    if (i != null && mounted) setState(() => store.periodeIndex = i);
  }

  Future<void> _generateAndDownload() async {
    final store = widget.store;
    final ext = store.format == 0 ? 'xlsx' : 'pdf';
    final prakLabel = store.praktikumOptions[store.praktikumIndex]
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final now = DateTime.now();
    final dateTag =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final fileName = 'Laporan_${prakLabel}_$dateTag.$ext';
    final periode = store.periodeOptions[store.periodeIndex];

    final res = await dosenDownloadReportFile(
      fileName: fileName,
      periode: periode,
      sections: store.isiLaporan,
      store: store,
      courseName:
          store.praktikumOptions[store.praktikumIndex].split(' • ').first,
    );
    if (!mounted) return;
    if (!res.success) {
      labToast(context, 'Gagal mengunduh laporan');
      return;
    }

    const monthsFull = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    const monthsShort = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final monthHeader = '${monthsFull[now.month - 1]} ${now.year}';
    final meta =
        '${now.day.toString().padLeft(2, '0')} ${monthsShort[now.month - 1]} ${now.year} • ${res.formattedSize}';

    setState(() {
      store.downloads.insert(
        0,
        DosenDownload(monthHeader, res.fileName, meta, store.format == 0),
      );
    });
    await NilaiSyncService.instance.recordReportDownload(
      title: 'Laporan ${store.praktikumOptions[store.praktikumIndex]}',
      courseName: store.praktikumOptions[store.praktikumIndex],
      fileName: res.fileName,
      format: store.format == 0 ? 'XLSX' : 'PDF',
      sizeLabel: res.formattedSize,
      localPath: res.location,
      downloadedBy: ProfilData.dosen.name,
    );
    if (!mounted) return;
    dosenShowDownloaded(context, location: res.location);
  }

  Future<void> _redownloadItem(DosenDownload d) async {
    final res = await dosenDownloadReportFile(
      fileName: d.name,
      periode: d.month,
      sections: widget.store.isiLaporan,
      store: widget.store,
    );
    if (!mounted) return;
    if (res.success) {
      dosenShowDownloaded(context, location: res.location);
    } else {
      labToast(context, 'Gagal mengunduh ${d.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return LabTabBody(
      children: [
        LabCard(
          children: [
            const LabOverline(
              overline: 'Pelaporan Praktikum',
              title: 'Generate Laporan',
            ),
            Text(
              'Unduh rekap akhir pelaksanaan praktikum dan pelaporan nilai '
              'dengan satu kali klik.',
              style: labText(12, c: ItlgColors.textMuted),
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(icon: 'file', text: 'Pengaturan Laporan'),
            ),
            _Select(
              label: 'Praktikum',
              value: store.praktikumOptions[store.praktikumIndex],
              onTap: _pickPraktikum,
            ),
            _Select(
              label: 'Periode',
              value: store.periodeOptions[store.periodeIndex],
              onTap: _pickPeriode,
            ),
            LabColumn(
              gap: 8,
              children: [
                Text('Isi Laporan', style: labText(14)),
                for (var i = 0; i < _isi.length; i++)
                  DosenCheckOption(
                    title: _isi[i][0],
                    subtitle: _isi[i][1],
                    checked: store.isiLaporan.contains(i),
                    onTap: () => setState(() {
                      if (!store.isiLaporan.remove(i)) store.isiLaporan.add(i);
                    }),
                  ),
              ],
            ),
            LabColumn(
              gap: 8,
              children: [
                Text('Format Berkas', style: labText(14)),
                Row(
                  children: [
                    Expanded(
                      child: _FormatCard(
                        icon: 'table',
                        title: 'Spreadsheet',
                        ext: '.xlsx',
                        selected: store.format == 0,
                        onTap: () => setState(() => store.format = 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FormatCard(
                        icon: 'file',
                        title: 'PDF',
                        ext: '.pdf',
                        selected: store.format == 1,
                        onTap: () => setState(() => store.format = 1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        LabPrimaryButton(
          icon: 'download',
          label: 'Unduh Laporan',
          large: true,
          onTap: _generateAndDownload,
        ),
        LabCard(
          children: [
            Row(
              children: [
                const LabSectionTitle(icon: 'clock', text: 'Riwayat Unduhan'),
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => labPush(
                    context,
                    DosenRiwayatPage(store: store, onLogoTap: widget.onHome),
                  ),
                  child: Text('Lihat Semua',
                      style: labText(12, c: ItlgColors.primary)),
                ),
              ],
            ),
            ListenableBuilder(
              listenable: NilaiSyncService.instance,
              builder: (_, __) {
                final remote = NilaiSyncService.instance.reportDownloads;
                final items = remote.isNotEmpty
                    ? remote.map((r) => r.toDosenDownload()).toList()
                    : store.downloads;
                return LabColumn(
                  gap: 8,
                  children: [
                    for (final d in items.take(2))
                      DosenDownloadItem(
                        download: d,
                        onTap: () => _redownloadItem(d),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Baris berkas unduhan: ikon tabel/berkas, nama, tanggal & ukuran, ikon unduh.
class DosenDownloadItem extends StatelessWidget {
  final DosenDownload download;
  final VoidCallback onTap;

  const DosenDownloadItem({
    super.key,
    required this.download,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LabListItem(
      leading: LabIconTile(download.spreadsheet ? 'table' : 'file'),
      title: download.name,
      subtitle: download.meta,
      titleSize: 12,
      trailing:
          const LabIcon('download', size: 18, color: ItlgColors.primary),
      onTap: onTap,
    );
  }
}

/// Label + kolom pilihan dengan panah bawah.
class _Select extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _Select({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LabColumn(
      gap: 8,
      children: [
        Text(label, style: labText(14)),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: InnerShadowBox(
            radius: 12,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labText(12),
                  ),
                ),
                const SizedBox(width: 8),
                const LabIcon('chevron_down',
                    size: 16, color: ItlgColors.textSubtle),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu format berkas. Terpilih: merah dengan cahaya.
class _FormatCard extends StatelessWidget {
  final String icon;
  final String title;
  final String ext;
  final bool selected;
  final VoidCallback onTap;

  const _FormatCard({
    required this.icon,
    required this.title,
    required this.ext,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        height: 90,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? ItlgColors.primary : LabColors.chipIdle,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? ItlgShadows.primary : ItlgShadows.outline,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabIcon(icon,
                size: 22,
                color: selected ? Colors.white : ItlgColors.primary),
            const SizedBox(height: 8),
            Text(title,
                style: labText(14,
                    w: kBold,
                    c: selected ? ItlgColors.surfaceWhite : ItlgColors.text)),
            const SizedBox(height: 2),
            Text(ext,
                style: labText(11,
                    w: kMedium,
                    c: selected ? Colors.white : ItlgColors.textSubtle)),
          ],
        ),
      ),
    );
  }
}
