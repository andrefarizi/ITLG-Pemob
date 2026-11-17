import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../dosen_store.dart';
import '../widgets/dosen_ui.dart';
import 'dosen_riwayat_page.dart';

/// Pop-up setelah mengunduh laporan (Figma: "Pop up Laporan Diunduh").
void dosenShowDownloaded(BuildContext context) => dosenShowResult(
      context,
      icon: 'download',
      title: 'Laporan Diunduh',
      message: 'Berkas laporan tersimpan di folder Unduhan perangkat anda.',
      button: 'Selesai',
    );

/// Figma: "Generate Laporan-Dosen" (halaman tab, tombol Kembali
/// disembunyikan di Figma).
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
          onTap: () => dosenShowDownloaded(context),
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
            LabColumn(
              gap: 8,
              children: [
                for (final d in store.downloads.take(2))
                  DosenDownloadItem(
                    download: d,
                    onTap: () => dosenShowDownloaded(context),
                  ),
              ],
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

/// Label + kolom pilihan 48 px (inner shadow) dengan panah bawah.
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

/// Kartu format berkas 90 px. Terpilih: merah dengan cahaya.
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
