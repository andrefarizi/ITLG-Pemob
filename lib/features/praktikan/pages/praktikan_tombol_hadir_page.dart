import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/location_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../widgets/prak_google_map.dart';
import '../widgets/praktikan_ui.dart';

/// Halaman Tombol Hadir & Lokasi Praktikan.
class PraktikanTombolHadirPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanTombolHadirPage({super.key, required this.nav});

  @override
  State<PraktikanTombolHadirPage> createState() =>
      _PraktikanTombolHadirPageState();
}

class _PraktikanTombolHadirPageState extends State<PraktikanTombolHadirPage> {
  bool _inside = false;

  /// Lokasi dari aplikasi pemalsu GPS (mock location) → presensi ditolak.
  bool _mocked = false;

  /// Akurasi GPS lebih buruk dari [kMaxGpsAccuracy] → belum bisa presensi.
  bool _inaccurate = false;
  LatLng? _userPos;
  LatLng? _lastGeocodedPos;
  double? _distance;
  double? _accuracy;
  String _timeText = '--:-- WIB';
  bool _loading = true;
  String _addressTitle = 'Mendeteksi lokasi...';
  String _addressDetail = 'Mengambil data GPS perangkat';

  StreamSubscription<Position>? _posSub;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
    PresensiSyncService.instance.loadLabBuildings().then((_) {
      if (mounted) setState(() {});
    });
  }

  /// Lab sesi presensi yang sedang berlangsung (hanya untuk teks tampilan;
  /// pengecekan jarak tetap memakai [LocationService]).
  String get _labName {
    final lab = PresensiSyncService.instance.activeSession.labName;
    return lab.isEmpty ? 'lab' : lab;
  }

  String get _labPlace =>
      PresensiSyncService.instance.labPlaceLabel(_labName);

  /// Titik & radius lab dari sesi yang sedang dibuka Aslab.
  double get _targetLat {
    final s = PresensiSyncService.instance.activeSession;
    return (s.lat == 0 && s.lng == 0) ? kLabLat : s.lat;
  }

  double get _targetLng {
    final s = PresensiSyncService.instance.activeSession;
    return (s.lat == 0 && s.lng == 0) ? kLabLng : s.lng;
  }

  double get _radius {
    final r = PresensiSyncService.instance.activeSession.radiusMeters;
    return r > 0 ? r : kLabRadius;
  }

  /// "Pertemuan 7 • Sel, 24 Nov 2026 • 19:04" dari sesi aktif (WIB).
  String get _sessionSubtitle {
    final session = PresensiSyncService.instance.activeSession;
    final t = session.startedAt.toUtc().add(const Duration(hours: 7));
    const hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    String two(int v) => v.toString().padLeft(2, '0');
    return 'Pertemuan ${session.meetingNumber} • ${hari[t.weekday - 1]}, '
        '${two(t.day)} ${bulan[t.month - 1]} ${t.year} • '
        'dibuka ${two(t.hour)}:${two(t.minute)} WIB';
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    _timeText = '$h:$m WIB';
  }

  Future<void> _initLocationTracking() async {
    await _checkLocation();
    if (!mounted) return;
    final allowed = await LocationService.instance.ensurePermission();
    if (!allowed || !mounted) return;

    await _posSub?.cancel();
    _posSub = LocationService.instance.getPositionStream().listen(
      (pos) => _applyPosition(pos, forceGeocode: false),
      onError: (Object e) {
        debugPrint('[TombolHadir] Stream lokasi error: $e');
      },
    );
  }

  Future<void> _applyPosition(
    Position pos, {
    required bool forceGeocode,
    bool showToast = false,
  }) async {
    if (!mounted) return;
    final dist =
        LocationService.distanceToPoint(pos, _targetLat, _targetLng);
    final mocked = pos.isMocked;
    final inaccurate = pos.accuracy > kMaxGpsAccuracy;
    // Sah hanya bila GPS asli, cukup akurat, dan di dalam radius lab sesi.
    final isInside = !mocked && !inaccurate && dist <= _radius;
    final nextPos = LatLng(pos.latitude, pos.longitude);
    _updateCurrentTime();

    final needGeocode = forceGeocode ||
        _lastGeocodedPos == null ||
        LocationService.distanceInMeters(
              _lastGeocodedPos!.latitude,
              _lastGeocodedPos!.longitude,
              nextPos.latitude,
              nextPos.longitude,
            ) >=
            15.0;

    setState(() {
      _userPos = nextPos;
      _distance = dist;
      _accuracy = pos.accuracy;
      _inside = isInside;
      _mocked = mocked;
      _inaccurate = inaccurate;
      _loading = false;
    });

    if (needGeocode) {
      _lastGeocodedPos = nextPos;
      final addr = await LocationService.instance
          .getAddress(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _addressTitle = addr.title;
        _addressDetail = addr.detail;
      });
    }

    if (!mounted) return;
    if (showToast) {
      labToast(
        context,
        mocked
            ? 'Lokasi palsu terdeteksi. Matikan aplikasi pemalsu GPS.'
            : inaccurate
                ? 'Sinyal GPS kurang akurat (± ${pos.accuracy.toStringAsFixed(0)} m). '
                    'Pindah ke dekat jendela lalu perbarui lokasi.'
                : isInside
                    ? 'Terverifikasi di $_labName (${dist.toStringAsFixed(0)} m)'
                    : 'Lokasi: $_addressTitle (${dist.toStringAsFixed(0)} m dari lab)',
      );
    }
  }

  Future<void> _checkLocation({bool showToast = false}) async {
    setState(() => _loading = true);
    _updateCurrentTime();

    final pos = await LocationService.instance.getCurrentPosition();
    if (!mounted) return;

    if (pos != null) {
      await _applyPosition(pos, forceGeocode: true, showToast: showToast);
    } else {
      // Jika GPS perangkat tidak aktif / izin belum diberikan
      setState(() {
        _loading = false;
        _inside = false;
        _mocked = false;
        _inaccurate = false;
        _addressTitle = 'GPS Tidak Terdeteksi';
        _addressDetail = 'Aktifkan GPS perangkat dan izinkan akses lokasi';
      });
      if (showToast) {
        labToast(
            context, 'Gagal mengambil GPS. Pastikan lokasi perangkat aktif.');
      }
    }
  }

  String get _currentCoordText {
    if (_userPos != null) {
      return '${_userPos!.latitude.toStringAsFixed(4)}, ${_userPos!.longitude.toStringAsFixed(4)}';
    }
    return 'Mencari koordinat...';
  }

  String get _distanceText {
    if (_distance != null) {
      if (_distance! >= 1000) {
        return '${(_distance! / 1000).toStringAsFixed(1)} km';
      }
      return '${_distance!.toStringAsFixed(0)} meter';
    }
    return '-- meter';
  }

  String get _accuracyText {
    if (_accuracy != null) {
      return '± ${_accuracy!.toStringAsFixed(0)} meter';
    }
    return '--';
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
        if (!_loading && !_inside)
          PrakNotice.danger(
            icon: 'triangle_alert',
            text: _mocked
                ? 'Lokasi palsu terdeteksi (aplikasi pemalsu GPS). Matikan '
                    'aplikasi tersebut, lalu perbarui lokasi.'
                : _inaccurate
                    ? 'Sinyal GPS kurang akurat. Tunggu sebentar atau pindah ke '
                        'dekat jendela, lalu perbarui lokasi.'
                    : 'Anda berada di luar area lab. Dekati $_labName hingga '
                        'jarak kurang dari ${_radius.toStringAsFixed(0)} meter, '
                        'lalu perbarui lokasi.',
          ),
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabSectionTitle(
                  icon: 'location', text: 'Verifikasi Lokasi'),
              right: _loading
                  ? const LabChip.idle('Mendeteksi...')
                  : (_inside
                      ? const LabChip.live('Di Dalam Area')
                      : LabChip.danger(_mocked
                          ? 'Lokasi Palsu'
                          : (_inaccurate ? 'GPS Kurang Akurat' : 'Di Luar Area'))),
            ),
            // Google Maps Nyata dengan Lokasi GPS Perangkat Aktual
            PrakGoogleMap(
              inside: _inside,
              userPos: _userPos,
              labName: _labName,
              labLat: _targetLat,
              labLng: _targetLng,
              radius: _radius,
            ),
            LabInsetBox(
              child: LabColumn(
                gap: 10,
                children: [
                  if (_inside)
                    _Address(
                      icon: 'location',
                      label: 'Lokasi Anda Saat Ini',
                      title: _labPlace,
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
                    _Address(
                      icon: 'door',
                      label: 'Titik Presensi',
                      title: _labPlace,
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
              left: LabMeta(
                  icon: 'door',
                  text:
                      '$_labName • Radius ${_radius.toStringAsFixed(0)} m'),
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
        if (!_loading && _inside) ...[
          LabListItem(
            leading: const LabIconTile('book_open'),
            title: 'Praktikum ${PraktikumSyncService.instance.courseById(PresensiSyncService.instance.activeSession.courseId).name}',
            subtitle: _sessionSubtitle,
            titleSize: 12,
          ),
          LabColumn(
            gap: 10,
            children: [
              LabPrimaryButton(
                icon: 'gesture_tap_button',
                label: 'Saya Hadir',
                large: true,
                onTap: () => nav.tandaTangan(
                  context,
                  method: 'location',
                  lat: _userPos?.latitude,
                  lng: _userPos?.longitude,
                  distanceMeters: _distance,
                ),
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
