import 'package:flutter/material.dart';

import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Sanggah Nilai-Praktikan".
class PraktikanSanggahNilaiPage extends StatefulWidget {
  final PraktikanNav nav;
  final PrakCourse course;
  final PrakGrade grade;

  const PraktikanSanggahNilaiPage({
    super.key,
    required this.nav,
    required this.course,
    required this.grade,
  });

  @override
  State<PraktikanSanggahNilaiPage> createState() =>
      _PraktikanSanggahNilaiPageState();
}

class _PraktikanSanggahNilaiPageState extends State<PraktikanSanggahNilaiPage> {
  final TextEditingController _alasan = TextEditingController();

  /// Figma: komponen kedua (Tampilan & Navigasi) tercentang.
  final Set<int> _checked = {1};
  bool _bukti = false;

  @override
  void dispose() {
    _alasan.dispose();
    super.dispose();
  }

  void _kirim() {
    if (_checked.isEmpty) {
      labToast(context, 'Pilih minimal satu komponen yang disanggah');
      return;
    }
    Navigator.of(context).maybePop();
    labToast(context, 'Sanggahan terkirim ke asisten');
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.grade;
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            LabOverline(
              overline: 'Praktikum ${widget.course.name}',
              title: 'Sanggah Nilai\nModul ${g.modul}',
            ),
            LabStatRow(
              gap: 13,
              stats: [
                LabStat(
                    icon: 'trophy',
                    label: 'Nilai Saat Ini',
                    value: '${g.score ?? '–'} / 100'),
                const LabStat(
                    icon: 'clock',
                    label: 'Batas Sanggah',
                    value: '05 Okt 2026'),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(
                  icon: 'clipboard', text: 'Komponen yang Disanggah'),
            ),
            LabColumn(
              gap: 8,
              children: [
                for (var i = 0; i < g.components.length; i++)
                  PrakCheckOption(
                    title: g.components[i].$1,
                    subtitle:
                        'Nilai ${g.components[i].$2} / ${g.components[i].$3}',
                    checked: _checked.contains(i),
                    onTap: () => setState(() => _checked.contains(i)
                        ? _checked.remove(i)
                        : _checked.add(i)),
                  ),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(
                  icon: 'chat_bubble', text: 'Alasan Sanggahan'),
            ),
            PrakField(
              label: 'Penjelasan :',
              child: PrakTextArea(
                controller: _alasan,
                hint: 'Jelaskan bagian yang menurut anda perlu ditinjau '
                    'ulang...',
              ),
            ),
            LabOutlineButton(
              icon: _bukti ? 'check' : 'attach',
              label: _bukti ? 'Bukti Terlampir' : 'Lampirkan Bukti',
              onTap: () => setState(() => _bukti = !_bukti),
            ),
          ],
        ),
        const PrakNotice.info(
          icon: 'info',
          text: 'Sanggahan hanya dapat diajukan sebelum nilai divalidasi dosen '
              'dan disinkronkan ke portal akademik.',
        ),
        LabPrimaryButton(
          icon: 'send',
          label: 'Kirim Sanggahan',
          large: true,
          onTap: _kirim,
        ),
      ],
    );
  }
}
