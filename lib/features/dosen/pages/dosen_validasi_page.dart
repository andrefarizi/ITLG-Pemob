import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../dosen_store.dart';

/// Figma: "Validasi Nilai Akhir-Dosen" (halaman tab, tombol Kembali
/// disembunyikan di Figma).
class DosenValidasiPage extends StatefulWidget {
  final DosenStore store;
  const DosenValidasiPage({super.key, required this.store});

  @override
  State<DosenValidasiPage> createState() => _DosenValidasiPageState();
}

class _DosenValidasiPageState extends State<DosenValidasiPage> {
  void _validate() {
    if (widget.store.validated) {
      labToast(context, 'Nilai akhir kelas ini sudah divalidasi');
      return;
    }
    setState(() => widget.store.validated = true);
    labToast(context, 'Nilai akhir disinkronkan ke Portal Akademik');
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return LabTabBody(
      children: [
        LabCard(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: store.validated
                    ? const LabChip.live('Tervalidasi', key: ValueKey('ok'))
                    : const LabChip.warn('Menunggu Validasi',
                        key: ValueKey('wait')),
              ),
            ),
            const _ClassTitle(),
            const LabStatRow(
              stats: [
                LabStat(icon: 'people_group', label: 'Praktikan', value: '24'),
                LabStat(icon: 'trophy', label: 'Rata-rata', value: '84,2'),
                LabStat(icon: 'check', label: 'Lulus', value: '23'),
              ],
            ),
            const LabMeta(
              icon: 'people_group',
              text: 'Dinilai oleh Andi Pratama & Feri Gunawan',
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
                Text('12 Modul', style: labText(12, c: ItlgColors.primary)),
              ],
            ),
            _GradeTable(grades: store.grades),
            LabOutlineButton(
              icon: 'chevron_down',
              label: 'Lihat 19 Praktikan Lainnya',
              onTap: () => labToast(
                  context, 'Daftar lengkap 24 praktikan belum tersedia'),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: LabColors.tagBlueBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const LabIcon('arrow_cycle',
                  size: 18, color: ItlgColors.secondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Setelah divalidasi, nilai akhir disinkronkan ke Portal '
                  'Akademik dan tidak dapat diubah lagi oleh asisten.',
                  style: labText(12, c: LabColors.blueDark),
                ),
              ),
            ],
          ),
        ),
        LabColumn(
          gap: 12,
          children: [
            LabPrimaryButton(
              icon: 'check',
              label: 'Validasi & Sinkronkan Nilai',
              large: true,
              onTap: _validate,
            ),
            LabOutlineButton(
              icon: 'pencil',
              label: 'Minta Revisi ke Asisten',
              large: true,
              onTap: () => labToast(context,
                  'Permintaan revisi dikirim ke Andi Pratama & Feri Gunawan'),
            ),
          ],
        ),
      ],
    );
  }
}

/// "TIF 3001 - Kelas C" (Bold 16 merah tua) + judul Bold 22.
class _ClassTitle extends StatelessWidget {
  const _ClassTitle();

  @override
  Widget build(BuildContext context) {
    return LabColumn(
      gap: 6,
      children: [
        Text('TIF 3001 - Kelas C',
            style: labText(16, w: kBold, c: ItlgColors.primaryDark)),
        Text('Praktikum\nPemrograman Mobile',
            style: labText(22, w: kBold, c: Colors.black)),
      ],
    );
  }
}

/// Tabel rekap nilai: kolom 130 / 44 / 52 / 60 dengan jarak 8 (lebar 310).
class _GradeTable extends StatelessWidget {
  final List<DosenGrade> grades;
  const _GradeTable({required this.grades});

  static const int _fName = 130;
  static const int _fTugas = 44;
  static const int _fPresensi = 52;
  static const int _fAkhir = 60;

  Widget _row(List<Widget> cells) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: _fName, child: cells[0]),
          const SizedBox(width: 8),
          Expanded(flex: _fTugas, child: cells[1]),
          const SizedBox(width: 8),
          Expanded(flex: _fPresensi, child: cells[2]),
          const SizedBox(width: 8),
          Expanded(flex: _fAkhir, child: cells[3]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final head = labText(11, w: kMedium, c: ItlgColors.textSubtle);
    final cell = labText(12, w: kMedium);
    return LabInsetBox(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          _row([
            Text('Praktikan', style: head),
            Text('Tugas', textAlign: TextAlign.center, style: head),
            Text('Presensi', textAlign: TextAlign.center, style: head),
            Text('Akhir', textAlign: TextAlign.right, style: head),
          ]),
          for (final g in grades)
            _row([
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labText(12, w: kBold)),
                  const SizedBox(height: 2),
                  Text(g.nim,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                ],
              ),
              Text(g.tugas, textAlign: TextAlign.center, style: cell),
              Text(g.presensi, textAlign: TextAlign.center, style: cell),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(g.akhir,
                      style: labText(14, w: kBold, c: ItlgColors.primary)),
                  const SizedBox(width: 4),
                  LabTag.blue(g.huruf),
                ],
              ),
            ]),
        ],
      ),
    );
  }
}
