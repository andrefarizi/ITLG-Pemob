import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../dosen_store.dart';

/// Figma: "Generate Laporan-Dosen" (halaman tab, tombol Kembali
/// disembunyikan di Figma).
class DosenLaporanPage extends StatefulWidget {
  final DosenStore store;
  const DosenLaporanPage({super.key, required this.store});

  @override
  State<DosenLaporanPage> createState() => _DosenLaporanPageState();
}

class _DosenLaporanPageState extends State<DosenLaporanPage> {
  static const List<List<String>> _isi = [
    ['Rekap Pelaksanaan Praktikum', 'Jadwal, modul, dan kehadiran per pertemuan'],
    ['Pelaporan Nilai Akhir', 'Akumulasi nilai tervalidasi seluruh praktikan'],
    ['Rekap Kedisiplinan Asisten', 'Presensi dan ketepatan waktu asisten'],
  ];

  Future<void> _pick({
    required String title,
    required List<String> options,
    required int selected,
    required ValueChanged<int> onPicked,
  }) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: ItlgColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: LabColumn(
            gap: 8,
            children: [
              Text(title, style: labText(16, w: kBold, c: Colors.black)),
              const SizedBox(height: 4),
              for (var i = 0; i < options.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(i),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ItlgShadows.outline,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            options[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: labText(12,
                                w: i == selected ? kBold : FontWeight.w400),
                          ),
                        ),
                        if (i == selected)
                          const LabIcon('check',
                              size: 16, color: ItlgColors.primary),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => onPicked(picked));
  }

  void _download() {
    final store = widget.store;
    if (store.isiLaporan.isEmpty) {
      labToast(context, 'Pilih minimal satu isi laporan');
      return;
    }
    final ext = store.format == 0 ? '.xlsx' : '.pdf';
    labToast(context, 'Laporan $ext sedang diunduh');
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
              onTap: () => _pick(
                title: 'Pilih Praktikum',
                options: store.praktikumOptions,
                selected: store.praktikumIndex,
                onPicked: (i) => store.praktikumIndex = i,
              ),
            ),
            _Select(
              label: 'Periode',
              value: store.periodeOptions[store.periodeIndex],
              onTap: () => _pick(
                title: 'Pilih Periode',
                options: store.periodeOptions,
                selected: store.periodeIndex,
                onPicked: (i) => store.periodeIndex = i,
              ),
            ),
            LabColumn(
              gap: 8,
              children: [
                Text('Isi Laporan', style: labText(14)),
                for (var i = 0; i < _isi.length; i++)
                  _ReportOption(
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
          onTap: _download,
        ),
        LabCard(
          children: [
            Row(
              children: [
                const LabSectionTitle(icon: 'clock', text: 'Riwayat Unduhan'),
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      labToast(context, 'Riwayat lengkap belum tersedia'),
                  child: Text('Lihat Semua',
                      style: labText(12, c: ItlgColors.primary)),
                ),
              ],
            ),
            LabColumn(
              gap: 8,
              children: [
                LabListItem(
                  leading: const LabIconTile('table'),
                  title: 'Rekap_PemMobile_C.xlsx',
                  subtitle: '21 Sep 2026 • 248 KB',
                  titleSize: 12,
                  trailing: const LabIcon('download',
                      size: 18, color: ItlgColors.primary),
                  onTap: () =>
                      labToast(context, 'Mengunduh Rekap_PemMobile_C.xlsx'),
                ),
                LabListItem(
                  leading: const LabIconTile('file'),
                  title: 'Nilai_BasisData_B.pdf',
                  subtitle: '14 Sep 2026 • 1,1 MB',
                  titleSize: 12,
                  trailing: const LabIcon('download',
                      size: 18, color: ItlgColors.primary),
                  onTap: () =>
                      labToast(context, 'Mengunduh Nilai_BasisData_B.pdf'),
                ),
              ],
            ),
          ],
        ),
      ],
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

/// Pilihan isi laporan. Tercentang: kartu putih timbul. Tidak: putih cekung.
class _ReportOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool checked;
  final VoidCallback onTap;

  const _ReportOption({
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const pad = EdgeInsets.symmetric(horizontal: 14, vertical: 12);
    final content = Row(
      children: [
        checked
            ? Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ItlgColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child:
                    const LabIcon('check', size: 14, color: Colors.white),
              )
            : const InnerShadowBox(
                width: 22,
                height: 22,
                radius: 6,
                color: LabColors.tile,
                shadows: LabShadows.track,
              ),
        const SizedBox(width: 10),
        Expanded(
          child: LabColumn(
            gap: 2,
            children: [
              Text(title, style: labText(12, w: kBold)),
              Text(subtitle,
                  style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
            ],
          ),
        ),
      ],
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: checked
          ? Container(
              padding: pad,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: ItlgShadows.outline,
              ),
              child: content,
            )
          : InnerShadowBox(
              radius: 12,
              color: Colors.white,
              padding: pad,
              child: content,
            ),
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
