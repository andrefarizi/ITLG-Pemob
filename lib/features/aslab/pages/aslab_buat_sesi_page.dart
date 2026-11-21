import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../../praktikan/widgets/prak_google_map.dart';
import '../../shared/lab_actions.dart';
import '../aslab_nav.dart';
import '../widgets/aslab_ui.dart';

/// Figma: "Buat Sesi Presensi-Aslab".
class AslabBuatSesiPage extends StatefulWidget {
  final AslabNav nav;
  const AslabBuatSesiPage({super.key, required this.nav});

  @override
  State<AslabBuatSesiPage> createState() => _AslabBuatSesiPageState();
}

class _AslabBuatSesiPageState extends State<AslabBuatSesiPage> {
  static const List<String> _titik = [
    'Lab Komputer 1 • Gedung C Lantai 2',
    'Lab Komputer 2 • Gedung C Lantai 2',
    'Lab Jaringan 2 • Gedung D Lantai 1',
  ];
  /// Koordinat tiap titik lokasi (urutan sama dengan [_titik]).
  static const List<String> _koordinat = [
    '3.5621, 98.6600',
    '3.5623, 98.6604',
    '3.5617, 98.6612',
  ];
  static const List<String> _radius = [
    '25 meter dari titik lab',
    '50 meter dari titik lab',
    '100 meter dari titik lab',
  ];
  static const List<String> _batas = [
    '10 menit sejak sesi dibuka',
    '15 menit sejak sesi dibuka',
    '30 menit sejak sesi dibuka',
  ];

  bool _qr = true;
  bool _tombol = true;
  bool _ttd = true;
  int _tt = 0;
  int _rd = 1;
  int _bt = 1;

  Future<void> _pick(String title, List<String> options, int current,
      ValueChanged<int> onPicked) async {
    final i = await prakShowPicker(context,
        title: title, options: options, selected: current);
    if (i != null && mounted) setState(() => onPicked(i));
  }

  void _openMap() {
    labShowInfoSheet(
      context,
      title: 'Titik Lokasi di Peta',
      header: const PrakGoogleMap(inside: true),
      rows: [
        ('location', 'Titik', _titik[_tt]),
        ('crosshairs_gps', 'Koordinat', _koordinat[_tt]),
        ('map_marker_radius_outline', 'Radius', _radius[_rd]),
      ],
      note: 'Praktikan hanya bisa menekan Tombol Hadir di dalam radius ini.',
      primary: (
        'location',
        'Pindahkan Titik',
        () => _pick('Titik Lokasi', _titik, _tt, (i) => _tt = i),
      ),
    );
  }

  void _mulai() {
    if (!_qr && !_tombol) {
      labToast(context, 'Pilih minimal satu cara verifikasi');
      return;
    }
    widget.nav.sesiAktif(context, replace: true);
  }

  @override
  Widget build(BuildContext context) {
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        const LabCard(
          children: [
            LabOverline(
              overline: 'Praktikum Pemrograman Mobile • Kelas C',
              title: 'Buat Sesi\nPresensi',
            ),
            Row(
              children: [
                Flexible(
                  child: LabMeta(
                    icon: 'calendar',
                    text: 'Pertemuan 5 • Sen, 05 Okt 2026',
                  ),
                ),
                SizedBox(width: 24),
                Flexible(
                  child: LabMeta(icon: 'people_group', text: '24 Praktikan'),
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
                  icon: 'shield_check_outline', text: 'Cara Verifikasi'),
            ),
            Text(
              'Pilih cara praktikan membuktikan kehadiran. Boleh lebih dari '
              'satu.',
              style: labText(12, c: ItlgColors.textMuted),
            ),
            LabColumn(
              gap: 8,
              children: [
                PrakCheckOption(
                  title: 'QR Code Dinamis',
                  subtitle:
                      'Praktikan memindai QR yang berganti tiap 15 detik',
                  checked: _qr,
                  onTap: () => setState(() => _qr = !_qr),
                ),
                PrakCheckOption(
                  title: 'Tombol Hadir + Lokasi',
                  subtitle: 'Praktikan menekan tombol hadir di dalam area lab',
                  checked: _tombol,
                  onTap: () => setState(() => _tombol = !_tombol),
                ),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(icon: 'location', text: 'Area Lokasi'),
            ),
            PrakField(
              label: 'Titik Lokasi',
              child: PrakSelect(
                value: _titik[_tt],
                onTap: () =>
                    _pick('Titik Lokasi', _titik, _tt, (i) => _tt = i),
              ),
            ),
            LabInsetBox(
              child: LabColumn(
                gap: 10,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LabIcon('location',
                          size: 16, color: ItlgColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LabColumn(
                          gap: 2,
                          children: [
                            Text('Alamat Titik Presensi',
                                style: labText(11,
                                    w: kMedium, c: ItlgColors.textSubtle)),
                            Text(
                              _titik[_tt].replaceAll(' • ', ', '),
                              style: labText(12, w: kBold),
                            ),
                            Text(
                              'Fasilkom-TI USU, Jl. Alumni, Padang Bulan, '
                              'Medan',
                              style: labText(12, c: ItlgColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const PrakDivider(),
                  PrakSpaceRow(
                    left: LabMeta(
                        icon: 'crosshairs_gps', text: _koordinat[_tt]),
                    right: PrakSideLink('Ubah di Peta', onTap: _openMap),
                  ),
                ],
              ),
            ),
            PrakField(
              label: 'Radius Area',
              child: PrakSelect(
                value: _radius[_rd],
                onTap: () =>
                    _pick('Radius Area', _radius, _rd, (i) => _rd = i),
              ),
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(
                  icon: 'signature_freehand', text: 'Tanda Tangan & Waktu'),
            ),
            LabListItem(
              leading: const LabIconTile('signature_freehand'),
              title: 'Wajib Tanda Tangan',
              subtitle: 'Praktikan menandatangani sebelum presensi dikirim',
              titleSize: 12,
              trailing: AslabToggle(
                value: _ttd,
                onChanged: (v) => setState(() => _ttd = v),
              ),
              onTap: () => setState(() => _ttd = !_ttd),
            ),
            PrakField(
              label: 'Batas Waktu Presensi',
              child: PrakSelect(
                value: _batas[_bt],
                onTap: () => _pick(
                    'Batas Waktu Presensi', _batas, _bt, (i) => _bt = i),
              ),
            ),
          ],
        ),
        LabPrimaryButton(
          icon: 'qrcode',
          label: 'Mulai Sesi Presensi',
          large: true,
          onTap: _mulai,
        ),
      ],
    );
  }
}
