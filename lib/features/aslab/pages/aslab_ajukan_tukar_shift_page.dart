import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';

/// Figma: "Ajukan Tukar Shift-Aslab".
class AslabAjukanTukarShiftPage extends StatefulWidget {
  final AslabNav nav;
  const AslabAjukanTukarShiftPage({super.key, required this.nav});

  @override
  State<AslabAjukanTukarShiftPage> createState() =>
      _AslabAjukanTukarShiftPageState();
}

class _AslabAjukanTukarShiftPageState extends State<AslabAjukanTukarShiftPage> {
  static const List<String> _shiftSaya = [
    'Rab, 30 Sep • 13:00–14:40 • Lab Jaringan 2',
    'Sen, 05 Okt • 08:00–09:40 • Lab Komputer 1',
    'Sen, 05 Okt • 13:00–14:40 • Lab Jaringan 2',
  ];
  static const List<String> _asisten = [
    'Feri Gunawan',
    'Sinta Marpaung',
    'Rizky Harahap',
  ];
  static const List<String> _shiftPengganti = [
    'Kam, 01 Okt • 08:00–09:40 • Lab Komputer 1',
    'Jum, 02 Okt • 10:00–11:40 • Lab Jaringan 2',
    'Sel, 06 Okt • 13:00–14:40 • Lab Komputer 1',
  ];

  final TextEditingController _alasan = TextEditingController();
  int _saya = 0;
  int _asst = 0;
  int _ganti = 0;

  @override
  void dispose() {
    _alasan.dispose();
    super.dispose();
  }

  Future<void> _pick(String title, List<String> options, int current,
      ValueChanged<int> onPicked) async {
    final i = await prakShowPicker(context,
        title: title, options: options, selected: current);
    if (i != null && mounted) setState(() => onPicked(i));
  }

  void _kirim() {
    Navigator.of(context).maybePop();
    labToast(context, 'Permintaan tukar shift dikirim ke ${_asisten[_asst]}');
  }

  @override
  Widget build(BuildContext context) {
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            const LabOverline(
              overline: 'Koordinasi Shift Jaga',
              title: 'Ajukan Tukar Shift',
            ),
            Text(
              'Pilih shift yang ingin ditukar dan asisten yang akan '
              'menggantikan.',
              style: labText(12, c: ItlgColors.textMuted),
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(
                  icon: 'arrow_right_left', text: 'Detail Penukaran'),
            ),
            PrakField(
              label: 'Shift Saya',
              child: PrakSelect(
                value: _shiftSaya[_saya],
                onTap: () => _pick('Shift Saya', _shiftSaya, _saya,
                    (i) => _saya = i),
              ),
            ),
            PrakField(
              label: 'Asisten Pengganti',
              child: PrakSelect(
                value: _asisten[_asst],
                onTap: () => _pick('Asisten Pengganti', _asisten, _asst,
                    (i) => _asst = i),
              ),
            ),
            PrakField(
              label: 'Shift Pengganti',
              child: PrakSelect(
                value: _shiftPengganti[_ganti],
                onTap: () => _pick('Shift Pengganti', _shiftPengganti,
                    _ganti, (i) => _ganti = i),
              ),
            ),
            PrakField(
              label: 'Alasan :',
              child: PrakTextArea(
                controller: _alasan,
                hint: 'Tulis alasan penukaran shift...',
              ),
            ),
          ],
        ),
        const PrakNotice.info(
          icon: 'bell',
          text: 'Asisten tujuan menerima notifikasi dan harus menyetujui '
              'sebelum jadwal berubah.',
        ),
        LabPrimaryButton(
          icon: 'send',
          label: 'Kirim Permintaan',
          large: true,
          onTap: _kirim,
        ),
      ],
    );
  }
}
