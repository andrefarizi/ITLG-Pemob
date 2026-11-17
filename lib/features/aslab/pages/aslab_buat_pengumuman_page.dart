import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';

/// Figma: "Buat Pengumuman-Aslab".
class AslabBuatPengumumanPage extends StatefulWidget {
  final AslabNav nav;
  const AslabBuatPengumumanPage({super.key, required this.nav});

  @override
  State<AslabBuatPengumumanPage> createState() =>
      _AslabBuatPengumumanPageState();
}

class _AslabBuatPengumumanPageState extends State<AslabBuatPengumumanPage> {
  static const List<(String, String)> _kategori = [
    ('calendar', 'Perubahan Jadwal'),
    ('info', 'Umum'),
    ('triangle_alert', 'Penting'),
  ];
  static const List<String> _tujuan = [
    'Pemrograman Mobile • TIF 3001 - Kelas C',
    'Basis Data • TIF 2104 - Kelas C',
    'Semua praktikan yang saya ampu',
  ];
  static const List<String> _jadwal = [
    'Kam, 01 Okt 2026 • 13:00–14:40',
    'Jum, 02 Okt 2026 • 08:00–09:40',
    'Sab, 03 Okt 2026 • 10:00–11:40',
  ];
  static const List<String> _ruang = [
    'Lab Komputer 1',
    'Lab Komputer 2',
    'Lab Jaringan 2',
  ];

  final TextEditingController _judul =
      TextEditingController(text: 'Praktikum pengganti Pertemuan 3');
  final TextEditingController _isi = TextEditingController(
      text: 'Pertemuan 3 dipindahkan karena bertepatan dengan libur '
          'nasional. Mohon hadir sesuai jadwal baru.');
  int _kat = 0;
  int _to = 0;
  int _jd = 0;
  int _rg = 0;

  @override
  void dispose() {
    _judul.dispose();
    _isi.dispose();
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
    labToast(context, 'Pengumuman terkirim ke praktikan');
  }

  @override
  Widget build(BuildContext context) {
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            const LabOverline(
              overline: 'Pengumuman & Perubahan Jadwal',
              title: 'Buat Pengumuman',
            ),
            Text(
              'Praktikan menerima notifikasi begitu pengumuman dikirim.',
              style: labText(12, c: ItlgColors.textMuted),
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(
                  icon: 'bullhorn_outline', text: 'Isi Pengumuman'),
            ),
            PrakField(
              label: 'Kategori',
              child: PrakOptionChips(
                options: _kategori,
                index: _kat,
                onChanged: (i) => setState(() => _kat = i),
              ),
            ),
            PrakField(
              label: 'Ditujukan Kepada',
              child: PrakSelect(
                value: _tujuan[_to],
                onTap: () => _pick(
                    'Ditujukan Kepada', _tujuan, _to, (i) => _to = i),
              ),
            ),
            PrakField(label: 'Judul', child: PrakInput(controller: _judul)),
            PrakField(
              label: 'Isi Pengumuman :',
              child: PrakTextArea(controller: _isi, height: 96),
            ),
            if (_kat == 0) ...[
              PrakField(
                label: 'Jadwal Baru',
                child: PrakSelect(
                  value: _jadwal[_jd],
                  onTap: () =>
                      _pick('Jadwal Baru', _jadwal, _jd, (i) => _jd = i),
                ),
              ),
              PrakField(
                label: 'Ruangan',
                child: PrakSelect(
                  value: _ruang[_rg],
                  onTap: () => _pick('Ruangan', _ruang, _rg, (i) => _rg = i),
                ),
              ),
            ],
          ],
        ),
        LabPrimaryButton(
          icon: 'send',
          label: 'Kirim Pengumuman',
          large: true,
          onTap: _kirim,
        ),
      ],
    );
  }
}
