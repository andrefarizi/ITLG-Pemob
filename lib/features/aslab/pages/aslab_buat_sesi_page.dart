import 'package:flutter/material.dart';

import '../../../core/services/jadwal_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../../praktikan/widgets/prak_google_map.dart';
import '../../shared/lab_actions.dart';
import '../aslab_nav.dart';
import '../widgets/aslab_ui.dart';

/// Figma: "Buat Sesi Presensi-Aslab".
class AslabBuatSesiPage extends StatefulWidget {
  final AslabNav nav;
  final String courseId;
  final int meetingNumber;

  const AslabBuatSesiPage({
    super.key,
    required this.nav,
    this.courseId = 'pemob',
    this.meetingNumber = 5,
  });

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
  int _sesi = 0; // 0 = Sesi C1, 1 = Sesi C2
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

  Future<void> _mulai() async {
    if (!_qr && !_tombol) {
      labToast(context, 'Pilih minimal satu cara verifikasi');
      return;
    }
    final coords = _koordinat[_tt].split(',').map((e) => double.tryParse(e.trim())).toList();
    final radii = const [25.0, 50.0, 100.0];
    final durations = const [10, 15, 30];
    await PresensiSyncService.instance.startSession(
      courseId: widget.courseId,
      meetingNumber: widget.meetingNumber,
      labName: _titik[_tt].split(' • ').first,
      lat: coords.isNotEmpty ? (coords[0] ?? 3.5621) : 3.5621,
      lng: coords.length > 1 ? (coords[1] ?? 98.6600) : 98.6600,
      radiusMeters: radii[_rd],
      allowQr: _qr,
      allowButton: _tombol,
      requireSignature: _ttd,
      durationMinutes: durations[_bt],
      startedBy: AuthController.instance.userName,
    );
    if (!mounted) return;
    widget.nav.sesiAktif(context, replace: true);
  }

  @override
  Widget build(BuildContext context) {
    final course = PraktikumSyncService.instance.courseById(widget.courseId);
    final courseScheds = JadwalSyncService.instance.schedules
        .where((s) => s.courseId == widget.courseId)
        .toList();
    final sesiOptions = courseScheds.isNotEmpty
        ? [
            for (final s in courseScheds)
              'Kom C • ${s.sessionShort} (${s.dayShort}, ${s.startTime}–${s.endTime} WIB)',
          ]
        : const [
            'Kom C • Sesi C1 (08:00–09:40 WIB)',
            'Kom C • Sesi C2 (10:00–11:40 WIB)',
          ];
    final safeSesi = _sesi.clamp(0, sesiOptions.length - 1);
    final meetingObj = course.meetings.firstWhere(
      (m) => m.number == widget.meetingNumber,
      orElse: () => course.meetings.first,
    );
    final meetingDateShort = meetingObj.date.split(' • ').first;

    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            LabOverline(
              overline: 'Praktikum ${course.name} • ${course.kelas}',
              title: 'Buat Sesi\nPresensi',
            ),
            Row(
              children: [
                Flexible(
                  child: LabMeta(
                    icon: 'calendar',
                    text: 'Pertemuan ${widget.meetingNumber} • $meetingDateShort',
                  ),
                ),
                const SizedBox(width: 24),
                const Flexible(
                  child: LabMeta(icon: 'people_group', text: '24 Praktikan'),
                ),
              ],
            ),
            PrakField(
              label: 'Sesi Kom C (Durasi 1 jam 40 menit)',
              child: PrakSelect(
                value: sesiOptions[safeSesi],
                onTap: () => _pick(
                    'Pilih Sesi Kom C', sesiOptions, safeSesi, (i) => _sesi = i),
              ),
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
                      'Praktikan memindai QR yang berganti tiap 5 menit',
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
