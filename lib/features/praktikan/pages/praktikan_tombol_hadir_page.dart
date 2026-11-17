import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Tombol Hadir & Lokasi-Praktikan" dan "(Di Luar Area)".
/// "Perbarui Lokasi" berpindah di antara kedua keadaan, seperti prototipe.
class PraktikanTombolHadirPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanTombolHadirPage({super.key, required this.nav});

  @override
  State<PraktikanTombolHadirPage> createState() =>
      _PraktikanTombolHadirPageState();
}

class _PraktikanTombolHadirPageState extends State<PraktikanTombolHadirPage> {
  bool _inside = true;

  @override
  Widget build(BuildContext context) {
    final nav = widget.nav;
    final store = nav.store;
    return LabSubPage(
      onLogoTap: nav.home,
      children: [
        const PrakStepper(step: 0),
        const LabTitle(
          title: 'Tombol Hadir',
          subtitle:
              'Pastikan anda berada di area laboratorium, lalu tekan Saya Hadir',
        ),
        if (!_inside)
          const PrakNotice.danger(
            icon: 'triangle_alert',
            text: 'Anda berada di luar area lab. Dekati Lab Komputer 1 hingga '
                'jarak kurang dari 50 meter, lalu perbarui lokasi.',
          ),
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabSectionTitle(
                  icon: 'location', text: 'Verifikasi Lokasi'),
              right: _inside
                  ? const LabChip.live('Di Dalam Area')
                  : const LabChip.danger('Di Luar Area'),
            ),
            PrakLocationMap(inside: _inside),
            LabInsetBox(
              child: LabColumn(
                gap: 10,
                children: [
                  if (_inside)
                    const _Address(
                      icon: 'location',
                      label: 'Lokasi Anda Saat Ini',
                      title: 'Lab Komputer 1, Gedung C Lantai 2',
                      detail:
                          'Fasilkom-TI USU, Jl. Alumni, Padang Bulan, Medan',
                    )
                  else ...const [
                    _Address(
                      icon: 'location',
                      label: 'Lokasi Anda Saat Ini',
                      title: 'Jl. Dr. Mansyur, Padang Bulan',
                      detail: 'Kec. Medan Baru, Kota Medan, Sumatera Utara',
                    ),
                    _Address(
                      icon: 'door',
                      label: 'Titik Presensi',
                      title: 'Lab Komputer 1, Gedung C Lantai 2',
                      detail:
                          'Fasilkom-TI USU, Jl. Alumni, Padang Bulan, Medan',
                    ),
                  ],
                  const PrakDivider(),
                  PrakSpaceRow(
                    left: LabMeta(
                      icon: 'crosshairs_gps',
                      text: _inside ? '3.5621, 98.6600' : '3.5640, 98.6612',
                    ),
                    right: const LabMeta(
                        icon: 'clock', text: 'Diperbarui 08:03 WIB'),
                  ),
                ],
              ),
            ),
            LabStatRow(
              gap: 13,
              stats: [
                LabStat(
                  icon: 'map_marker_radius_outline',
                  label: 'Jarak dari Lab',
                  value: _inside ? '12 meter' : '240 meter',
                ),
                LabStat(
                  icon: 'crosshairs_gps',
                  label: 'Akurasi GPS',
                  value: _inside ? '± 5 meter' : '± 8 meter',
                ),
              ],
            ),
            PrakSpaceRow(
              left: const LabMeta(
                  icon: 'door', text: 'Lab Komputer 1 • Radius 50 m'),
              right: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _inside = !_inside),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LabIcon('arrow_cycle',
                          size: 12, color: ItlgColors.primary),
                      const SizedBox(width: 4),
                      Text('Perbarui Lokasi',
                          style: labText(12, c: ItlgColors.primary)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_inside) ...[
          const LabListItem(
            leading: LabIconTile('book_open'),
            title: 'Praktikum Pemrograman Mobile',
            subtitle: 'Pertemuan 5 • Sen, 05 Okt 2026 • 08:00–09:40',
            titleSize: 12,
          ),
          LabColumn(
            gap: 10,
            children: [
              LabPrimaryButton(
                icon: 'gesture_tap_button',
                label: 'Saya Hadir',
                large: true,
                onTap: () => nav.tandaTangan(context),
              ),
              Text('Waktu dan lokasi anda dicatat saat tombol ditekan.',
                  textAlign: TextAlign.center,
                  style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
            ],
          ),
        ] else ...[
          LabColumn(
            gap: 12,
            children: [
              const PrakDisabledButton('Saya Hadir'),
              LabOutlineButton(
                icon: 'qrcode',
                label: 'Gunakan Pindai QR',
                large: true,
                onTap: () => nav.scanQr(context, replace: true),
              ),
            ],
          ),
          PrakLink(
            'Tidak dapat hadir? Ajukan Izin',
            onTap: () => nav.ajukanIzin(
                context, store.mobile, store.mobile.meetings.first),
          ),
        ],
      ],
    );
  }
}

class _Address extends StatelessWidget {
  final String icon;
  final String label;
  final String title;
  final String detail;

  const _Address({
    required this.icon,
    required this.label,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabIcon(icon, size: 16, color: ItlgColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: LabColumn(
            gap: 2,
            children: [
              Text(label,
                  style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
              Text(title, style: labText(12, w: kBold)),
              Text(detail, style: labText(12, c: ItlgColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
