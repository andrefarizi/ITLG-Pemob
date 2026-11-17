import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../dosen_store.dart';
import 'dosen_laporan_page.dart';

/// Figma: "Riwayat Unduhan-Dosen" (dari "Lihat Semua" di Generate Laporan).
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
  Widget build(BuildContext context) {
    final shown = widget.store.downloads.where((d) {
      if (_tab == 1) return d.spreadsheet;
      if (_tab == 2) return !d.spreadsheet;
      return true;
    }).toList();
    final months = <String>[];
    for (final d in shown) {
      if (!months.contains(d.month)) months.add(d.month);
    }

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
        for (final m in months)
          LabColumn(
            gap: 10,
            children: [
              Text(m, style: labText(12, w: kBold, c: ItlgColors.textSubtle)),
              for (final d in shown.where((d) => d.month == m))
                DosenDownloadItem(
                  download: d,
                  onTap: () => dosenShowDownloaded(context),
                ),
            ],
          ),
      ],
    );
  }
}
