import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/location_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../widgets/praktikan_ui.dart';
import '../widgets/prak_google_map.dart';

/// Figma: "Tombol Hadir & Lokasi-Praktikan" dan "(Di Luar Area)".
/// GPS nyata via geolocator; Google Maps via google_maps_flutter.
class PraktikanTombolHadirPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanTombolHadirPage({super.key, required this.nav});

  @override
  State<PraktikanTombolHadirPage> createState() =>
      _PraktikanTombolHadirPageState();
}

class _PraktikanTombolHadirPageState
    extends State<PraktikanTombolHadirPage> {
  // ── GPS state ────────────────────────────────────────────────────────────
  Position? _pos;
  bool _loading = true;
  String _updateTime = '--:--';
  bool _inside = false;
  double _distance = 0;
  double _accuracy = 0;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _loading = true);
    final pos = await LocationService.instance.getCurrentPosition();
    if (!mounted) return;
    if (pos == null) {
      setState(() {
        _loading = false;
        _pos = null;
        _inside = false;
      });
      return;
    }
    final inside = LocationService.isInsideLab(pos);
    final dist = LocationService.distanceToLab(pos);
    final now = TimeOfDay.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    setState(() {
      _pos = pos;
      _inside = inside;
      _distance = dist;
      _accuracy = pos.accuracy;
      _updateTime = '$h:$m WIB';
      _loading = false;
    });
  }

  String get _distanceText {
    if (_loading) return '---';
    if (_pos == null) return 'Tidak dapat diakses';
    return '${_distance.toStringAsFixed(0)} meter';
  }

  String get _accuracyText {
    if (_loading || _pos == null) return '---';
    return '± ${_accuracy.toStringAsFixed(0)} meter';
  }

  String get _coordText {
    if (_pos == null) return '---';
    return '${_pos!.latitude.toStringAsFixed(4)}, '
        '${_pos!.longitude.toStringAsFixed(4)}';
  }

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
        if (!_loading && !_inside && _pos != null)
          const PrakNotice.danger(
            icon: 'triangle_alert',
            text: 'Anda berada di luar area lab. Dekati Lab Komputer 1 hingga '
                'jarak kurang dari 50 meter, lalu perbarui lokasi.',
          ),
        if (!_loading && _pos == null)
          const PrakNotice.danger(
            icon: 'triangle_alert',
            text: 'Tidak dapat mengakses GPS. Pastikan izin lokasi diizinkan '
                'dan GPS aktif, lalu perbarui lokasi.',
          ),
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabSectionTitle(
                  icon: 'location', text: 'Verifikasi Lokasi'),
              right: _loading
                  ? const LabChip.idle('Memuat...')
                  : (_inside
                      ? const LabChip.live('Di Dalam Area')
                      : const LabChip.danger('Di Luar Area')),
            ),
            // ── Google Maps ──────────────────────────────────────────────
            _loading
                ? const PrakMapLoading()
                : PrakGoogleMap(userPos: _pos, inside: _inside),
            LabInsetBox(
              child: LabColumn(
                gap: 10,
                children: [
                  if (!_loading && _inside && _pos != null)
                    _Address(
                      icon: 'location',
                      label: 'Lokasi Anda Saat Ini',
                      title: 'Lab Komputer 1, Gedung C Lantai 2',
                      detail:
                          'Fasilkom-TI USU, Jl. Alumni, Padang Bulan, Medan',
                    )
                  else if (!_loading && _pos != null) ...[
                    _Address(
                      icon: 'location',
                      label: 'Lokasi Anda Saat Ini',
                      title: 'Di Luar Area Lab',
                      detail: 'Koordinat: $_coordText',
                    ),
                    const _Address(
                      icon: 'door',
                      label: 'Titik Presensi',
                      title: 'Lab Komputer 1, Gedung C Lantai 2',
                      detail:
                          'Fasilkom-TI USU, Jl. Alumni, Padang Bulan, Medan',
                    ),
                  ] else if (!_loading && _pos == null)
                    const _Address(
                      icon: 'location',
                      label: 'Lokasi',
                      title: 'GPS tidak tersedia',
                      detail: 'Izin lokasi diperlukan untuk verifikasi.',
                    ),
                  const PrakDivider(),
                  PrakSpaceRow(
                    left: LabMeta(
                      icon: 'crosshairs_gps',
                      text: _coordText,
                    ),
                    right: LabMeta(
                        icon: 'clock',
                        text: 'Diperbarui $_updateTime'),
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
                  value: _distanceText,
                ),
                LabStat(
                  icon: 'crosshairs_gps',
                  label: 'Akurasi GPS',
                  value: _accuracyText,
                ),
              ],
            ),
            PrakSpaceRow(
              left: const LabMeta(
                  icon: 'door', text: 'Lab Komputer 1 • Radius 50 m'),
              right: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _fetchLocation,
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
        if (!_loading && _inside) ...[
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
        ] else if (!_loading) ...[
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
