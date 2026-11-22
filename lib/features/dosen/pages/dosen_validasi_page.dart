import 'package:flutter/material.dart';

import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
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
  Future<void> _validate() async {
    widget.store.validated = true;
    await NilaiSyncService.instance.validateCourse(
      courseId: 'pemob',
      validatedBy: AuthController.instance.userName,
    );
    if (!mounted) return;
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
    final nilaiSync = NilaiSyncService.instance;
    final praktikumSync = PraktikumSyncService.instance;
    final presensiSync = PresensiSyncService.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([nilaiSync, praktikumSync, presensiSync]),
      builder: (context, _) {
        final valRec = nilaiSync.validationFor('pemob');
        final done = valRec.isValidated;
        final liveAll = nilaiSync.liveDosenGrades(store.grades, courseId: 'pemob');
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
                const DosenClassTitle(),
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
                    Text('12 Modul',
                        style: labText(12, c: ItlgColors.primary)),
                  ],
                ),
                DosenGradeTable(grades: livePreview),
                LabOutlineButton(
                  icon: 'chevron_down',
                  label: 'Lihat $othersCount Praktikan Lainnya',
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
      },
    );
  }
}
