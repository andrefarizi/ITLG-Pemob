import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../dosen_store.dart';
import '../widgets/dosen_ui.dart';
import 'dosen_minta_revisi_page.dart';
import 'dosen_rekap_nilai_page.dart';

/// Figma: "Validasi Nilai Akhir-Dosen". Status "Tervalidasi" disimpan di
/// store (di Figma memakai variabel validasi/menunggu & validasi/selesai).
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
  void _validate() {
    setState(() => widget.store.validated = true);
    dosenShowResult(
      context,
      icon: 'circle_check',
      title: 'Nilai Tervalidasi',
      message: 'Nilai akhir TIF 3001 - Kelas C berhasil disinkronkan ke '
          'Portal Akademik.',
      button: 'Selesai',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final done = store.validated;
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
                    : const LabChip.warn('Menunggu Validasi',
                        key: ValueKey('wait')),
              ),
            ),
            const DosenClassTitle(),
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
            DosenGradeTable(grades: store.previewGrades),
            LabOutlineButton(
              icon: 'chevron_down',
              label: 'Lihat 19 Praktikan Lainnya',
              onTap: () => labPush(
                context,
                DosenRekapNilaiPage(store: store, onLogoTap: widget.onHome),
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
          const DosenDisabledButton(icon: 'check', label: 'Sudah Divalidasi')
        else
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
                onTap: () => labPush(
                  context,
                  DosenMintaRevisiPage(onLogoTap: widget.onHome),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
