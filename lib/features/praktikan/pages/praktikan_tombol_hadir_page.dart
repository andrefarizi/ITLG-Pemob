import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/location_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../widgets/praktikan_ui.dart';
import '../widgets/prak_google_map.dart';

/// Figma: "Tombol Hadir & Lokasi-Praktikan" dan "(Di Luar Area)".
/// Mengambil lokasi GPS aktual pengguna secara akurat (misal: Fore Coffee Dr. Mansyur)
/// dan menghitung jarak aktual ke Lab Komputer 1.
class PraktikanTombolHadirPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanTombolHadirPage({super.key, required this.nav});

  @override
  State<PraktikanTombolHadirPage> createState() =>
      _PraktikanTombolHadirPageState();
}

class _PraktikanTombolHadirPageState extends State<PraktikanTombolHadirPage> {
  bool _inside = false;
  LatLng? _userPos;
  double _distance = 820;
  double _accuracy = 5;
  String _timeText = '08:03 WIB';
  bool _loading = false;
  String _addressTitle = 'Jl. Dr. Mansyur, Padang Bulan';
  String _addressDetail = 'Fore Coffee, Jl. Dr. Mansyur, Medan';

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    _timeText = '$h:$m WIB';
  }

  Future<void> _checkLocation({bool showToast = false}) async {
    setState(() => _loading = true);
    _updateCurrentTime();

    final pos = await LocationService.instance.getCurrentPosition();
    if (!mounted) return;

    if (pos != null) {
      final dist = LocationService.distanceToLab(pos);
      final isInside = dist <= kLabRadius;
      final addr = await LocationService.instance
          .getAddress(pos.latitude, pos.longitude);

      setState(() {
        _userPos = LatLng(pos.latitude, pos.longitude);
        _distance = dist;
        _accuracy = pos.accuracy;
        _inside = isInside;
        _addressTitle = addr.title;
        _addressDetail = addr.detail;
        _loading = false;
      });

      if (showToast) {
        labToast(
          context,
          isInside
              ? 'Terverifikasi di Lab Komputer 1 (${dist.toStringAsFixed(0)} m)'
              : 'Lokasi: $_addressTitle (${dist.toStringAsFixed(0)} m dari lab)',
        );
      }
    } else {
      // Fallback jika sensor GPS belum dapat sinyal
      setState(() {
        _inside = false;
        _userPos = const LatLng(3.5684, 98.6548);
        _distance = 820;
        _accuracy = 5;
        _addressTitle = 'Jl. Dr. Mansyur, Padang Bulan';
        _addressDetail = 'Fore Coffee, Jl. Dr. Mansyur, Medan';
        _loading = false;
      });
      if (showToast) {
        labToast(context, 'Memperbarui lokasi GPS...');
      }
    }
  }

  String get _currentCoordText {
    if (_userPos != null) {
      return '${_userPos!.latitude.toStringAsFixed(4)}, ${_userPos!.longitude.toStringAsFixed(4)}';
    }
    return _inside ? '3.5621, 98.6600' : '3.5684, 98.6548';
  }

  String get _distanceText {
    return '${_distance.toStringAsFixed(0)} meter';
  }

  String get _accuracyText {
    return '± ${_accuracy.toStringAsFixed(0)} meter';
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
            // ── Google Maps Nyata dengan Marker Posisi Anda & Radius 50m ─
            PrakGoogleMap(inside: _inside, userPos: _userPos),
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
                  else ...[
                    _Address(
                      icon: 'location',
                      label: 'Lokasi Anda Saat Ini',
                      title: _addressTitle,
                      detail: _addressDetail,
                    ),
                    const _Address(
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
                      text: _currentCoordText,
                    ),
                    right: LabMeta(
                      icon: 'clock',
                      text: 'Diperbarui $_timeText',
                    ),
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
                onTap: () => _checkLocation(showToast: true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LabIcon('arrow_cycle',
                          size: 12, color: ItlgColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        _loading ? 'Memperbarui...' : 'Perbarui Lokasi',
                        style: labText(12, c: ItlgColors.primary),
                      ),
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
