import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Hasil Kuis-Praktikan".
class PraktikanHasilKuisPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanHasilKuisPage({super.key, required this.nav});

  @override
  State<PraktikanHasilKuisPage> createState() => _PraktikanHasilKuisPageState();
}

class _PraktikanHasilKuisPageState extends State<PraktikanHasilKuisPage> {
  bool _all = false;

  /// Pembahasan: (jawaban yang ditampilkan, benar?).
  static const List<(String, bool)> _review = [
    ('Jawaban anda: C • Hot Reload', true),
    ('Jawaban anda: A • setState()', true),
    ('Jawaban anda: B • StatefulWidget', true),
    ('Jawaban anda: D • Jawaban benar: B • Provider', false),
    ('Jawaban anda: C • initState()', true),
    ('Jawaban anda: A • ChangeNotifier', true),
    ('Jawaban anda: B • notifyListeners()', true),
    ('Jawaban anda: A • Jawaban benar: B • Consumer', false),
    ('Jawaban anda: C • Ephemeral state', true),
    ('Jawaban anda: A • dispose()', true),
  ];

  @override
  Widget build(BuildContext context) {
    final shown = _all ? _review.length : 4;
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          decoration: BoxDecoration(
            color: ItlgColors.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            boxShadow: ItlgShadows.outline,
          ),
          child: Column(
            children: [
              const PrakIconWell('trophy'),
              const SizedBox(height: 13),
              Text('Pre-Test Selesai',
                  textAlign: TextAlign.center, style: labText(22, w: kBold)),
              const SizedBox(height: 4),
              Text('Kuis Modul 4 : State Management',
                  textAlign: TextAlign.center,
                  style: labText(14, c: ItlgColors.textMuted)),
              const SizedBox(height: 13),
              const PrakBigScore('80'),
              const SizedBox(height: 13),
              const LabStatRow(
                stats: [
                  LabStat(icon: 'check', label: 'Benar', value: '8'),
                  LabStat(icon: 'cross', label: 'Salah', value: '2'),
                  LabStat(icon: 'clock', label: 'Waktu', value: '05:28'),
                ],
              ),
            ],
          ),
        ),
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabSectionTitle(
                  icon: 'clipboard', text: 'Pembahasan'),
              right: PrakSideLink(
                _all ? 'Ringkas' : 'Lihat Semua',
                onTap: () => setState(() => _all = !_all),
              ),
            ),
            LabColumn(
              gap: 8,
              children: [
                for (var i = 0; i < shown; i++)
                  LabListItem(
                    leading: PrakNumberTile('${i + 1}'),
                    title: 'Soal ${i + 1}',
                    subtitle: _review[i].$1,
                    titleSize: 12,
                    trailing: _review[i].$2
                        ? const LabIcon('circle_check',
                            size: 18, color: LabColors.green)
                        : const LabIcon('cross',
                            size: 18, color: ItlgColors.primary),
                  ),
              ],
            ),
          ],
        ),
        const PrakNotice.info(
          icon: 'info',
          text: 'Nilai pre-test tidak memengaruhi nilai akhir, hanya untuk '
              'mengukur kesiapan sebelum praktikum.',
        ),
        LabPrimaryButton(
          icon: 'book_open',
          label: 'Lanjut ke Materi Modul 4',
          large: true,
          onTap: () => widget.nav.detailMateri(context, replace: true),
        ),
      ],
    );
  }
}
