import 'package:flutter/material.dart';

import '../../../core/services/nilai_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../dosen_store.dart';
import 'dosen_laporan_page.dart';

/// Figma: "Riwayat Unduhan-Dosen" (dari "Lihat Semua" di Generate Laporan).
/// Tersinkron penuh ke Supabase (`public.report_downloads`).
class DosenRiwayatPage extends StatefulWidget {
  final DosenStore store;
  final VoidCallback? onLogoTap;

  const DosenRiwayatPage({super.key, required this.store, this.onLogoTap});

  @override
  State<DosenRiwayatPage> createState() => _DosenRiwayatPageState();
}

class _DosenRiwayatPageState extends State<DosenRiwayatPage> {
  /// 0 Semua, 1 Spreadsheet, 2 PDF.
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    NilaiSyncService.instance.refreshFromBackend();
  }

  @override
  Widget build(BuildContext context) {
    final nilaiSync = NilaiSyncService.instance;
    return ListenableBuilder(
      listenable: nilaiSync,
      builder: (context, _) {
        final remote = nilaiSync.reportDownloads;
        final sourceList = remote.isNotEmpty
            ? remote.map((r) => r.toDosenDownload()).toList()
            : widget.store.downloads;
        final shown = sourceList.where((d) {
          if (_tab == 1) return d.spreadsheet;
          if (_tab == 2) return !d.spreadsheet;
          return true;
        }).toList();
        final months = <String>[];
        for (final d in shown) {
          if (!months.contains(d.month)) months.add(d.month);
        }
        final latestPath = (remote.isNotEmpty &&
                shown.isNotEmpty &&
                remote.first.fileName == shown.first.name &&
                remote.first.localPath.isNotEmpty)
            ? remote.first.localPath
            : (shown.isNotEmpty
                ? 'Download/ITLG Mobile/${shown.first.name}'
                : '');

        return LabSubPage(
          onLogoTap: widget.onLogoTap,
          children: [
            const LabTitle(
              title: 'Riwayat Unduhan',
              subtitle: 'Laporan yang pernah anda unduh',
            ),
            LabTabs(
              labels: const ['Semua', 'Spreadsheet', 'PDF'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            // Figma: Bagian "Baru Diunduh Hari Ini" (5602:2845)
            if (shown.isNotEmpty)
              LabColumn(
                gap: 10,
                children: [
                  Text('Baru Diunduh Hari Ini',
                      style: labText(12, w: kBold, c: ItlgColors.textSubtle)),
                  LabCard(
                    gap: 12,
                    children: [
                      LabListItem(
                        leading: LabIconTile(
                            shown.first.spreadsheet ? 'table' : 'file'),
                        title: shown.first.name,
                        subtitle: 'Hari ini • ${shown.first.meta}',
                        titleSize: 12,
                        trailing: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LabTag.red('Baru'),
                            SizedBox(width: 8),
                            LabIcon('download',
                                size: 18, color: ItlgColors.primary),
                          ],
                        ),
                      ),
                      LabButtonPair(
                        left: LabOutlineButton(
                          icon: 'download',
                          label: 'Unduh Ulang',
                          onTap: () async {
                            final d = shown.first;
                            final res = await dosenDownloadReportFile(
                              fileName: d.name,
                              periode: d.month,
                              sections: widget.store.isiLaporan,
                              store: widget.store,
                            );
                            if (!context.mounted) return;
                            if (res.success) {
                              dosenShowDownloaded(context,
                                  location: res.location);
                            } else {
                              labToast(context, 'Gagal mengunduh ${d.name}');
                            }
                          },
                        ),
                        right: LabOutlineButton(
                          icon: 'file',
                          label: 'Lihat Lokasi File',
                          onTap: () => labToast(
                            context,
                            'Tersimpan di $latestPath',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            for (final m in months)
              LabColumn(
                gap: 10,
                children: [
                  Text(m,
                      style: labText(12, w: kBold, c: ItlgColors.textSubtle)),
                  LabCard(
                    gap: 8,
                    children: [
                      for (final d in shown.where((d) => d.month == m))
                        DosenDownloadItem(
                          download: d,
                          onTap: () async {
                            final res = await dosenDownloadReportFile(
                              fileName: d.name,
                              periode: d.month,
                              sections: widget.store.isiLaporan,
                              store: widget.store,
                            );
                            if (!context.mounted) return;
                            if (res.success) {
                              dosenShowDownloaded(context,
                                  location: res.location);
                            } else {
                              labToast(context, 'Gagal mengunduh ${d.name}');
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Belum ada riwayat unduhan untuk kategori ini.',
                  textAlign: TextAlign.center,
                  style: labText(12, c: ItlgColors.textSubtle),
                ),
              ),
          ],
        );
      },
    );
  }
}
