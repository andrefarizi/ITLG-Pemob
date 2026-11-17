import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../dosen_store.dart';
import '../widgets/dosen_ui.dart';

/// Figma: "Rekap Nilai Akhir-Dosen" (dari "Lihat 19 Praktikan Lainnya").
class DosenRekapNilaiPage extends StatefulWidget {
  final DosenStore store;
  final VoidCallback? onLogoTap;

  const DosenRekapNilaiPage({super.key, required this.store, this.onLogoTap});

  @override
  State<DosenRekapNilaiPage> createState() => _DosenRekapNilaiPageState();
}

class _DosenRekapNilaiPageState extends State<DosenRekapNilaiPage> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  /// 0 Semua, 1 Lulus, 2 Tidak Lulus.
  int _tab = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.store.grades;
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
          subtitle: 'TIF 3001 - Kelas C • ${all.length} praktikan',
        ),
        DosenSearchField(
          hint: 'Cari nama atau NIM praktikan...',
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
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
                Text('12 Modul', style: labText(12, c: ItlgColors.primary)),
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
              DosenGradeTable(grades: shown),
          ],
        ),
      ],
    );
  }
}
