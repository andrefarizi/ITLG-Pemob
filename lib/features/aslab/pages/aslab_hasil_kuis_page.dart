import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';
import '../widgets/aslab_ui.dart';

/// Figma: "Hasil Kuis-Aslab".
class AslabHasilKuisPage extends StatefulWidget {
  final AslabNav nav;
  const AslabHasilKuisPage({super.key, required this.nav});

  @override
  State<AslabHasilKuisPage> createState() => _AslabHasilKuisPageState();
}

class _Result {
  final AslabStudent student;
  final int score;
  final String benar;
  final String waktu;

  /// Gaya chip di Figma berbeda: 0 putih polos, 1 kuning, 2 hijau berikon.
  final int chip;
  const _Result(this.student, this.score, this.benar, this.waktu, this.chip);

  bool get lulus => score >= 70;
}

class _AslabHasilKuisPageState extends State<AslabHasilKuisPage> {
  static const List<_Result> _all = [
    _Result(kRina, 90, '9 / 10 benar', '7 menit', 0),
    _Result(kDimas, 60, '6 / 10 benar', '10 menit', 1),
    _Result(kMaya, 100, '10 / 10 benar', '5 menit', 2),
  ];

  final TextEditingController _search = TextEditingController();
  String _query = '';

  /// 0 Semua, 1 Lulus, 2 Remedial.
  int _tab = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _match(_Result r) {
    if (_tab == 1 && !r.lulus) return false;
    if (_tab == 2 && r.lulus) return false;
    final q = _query.trim().toLowerCase();
    return q.isEmpty ||
        r.student.name.toLowerCase().contains(q) ||
        r.student.nim.contains(q);
  }

  Widget _chip(_Result r) {
    final text = '${r.lulus ? 'Lulus' : 'Remedial'} • ${r.score}';
    switch (r.chip) {
      case 1:
        return LabChip.warn(text);
      case 2:
        return LabChip.live(text);
      default:
        return Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(text,
                style: labText(12, w: kSemiBold, c: LabColors.green)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _all.where(_match).toList();
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        const LabTitle(
          title: 'Hasil Kuis',
          subtitle: 'Praktikum Pemrograman Mobile - TIF 3001 - Kelas C',
        ),
        PrakSearchField(
          hint: 'Cari nama atau NIM praktikan...',
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
        ),
        LabCard(
          children: [
            const PrakSpaceRow(
              left: LabTag.red('Kuis'),
              right: LabMeta(
                  icon: 'clock', text: 'Ditutup 28 Sep 2026, 08:10 WIB'),
            ),
            Text('Pre-Test Modul 4 : State Management',
                style: labText(16, w: kBold, c: Colors.black)),
            const LabStatRow(
              stats: [
                LabStat(icon: 'file', label: 'Mengerjakan', value: '22 / 24'),
                LabStat(icon: 'check', label: 'Rata-rata', value: '78,5'),
                LabStat(icon: 'clock', label: 'Tertinggi', value: '100'),
              ],
            ),
          ],
        ),
        LabTabs(
          labels: const ['Semua (22)', 'Lulus (18)', 'Remedial (4)'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        for (final r in items)
          LabCard(
            children: [
              Row(
                children: [
                  LabAvatar(r.student.initials),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LabColumn(
                      gap: 2,
                      children: [
                        Text(r.student.name, style: labText(14, w: kBold)),
                        Text(r.student.nim,
                            style: labText(11,
                                w: kMedium, c: ItlgColors.textSubtle)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _chip(r),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AslabFilePill(icon: 'circle_check', text: r.benar),
                  AslabFilePill(icon: 'clock', text: r.waktu),
                ],
              ),
            ],
          ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('Tidak ada hasil.',
                textAlign: TextAlign.center,
                style: labText(12, c: ItlgColors.textSubtle)),
          ),
      ],
    );
  }
}
