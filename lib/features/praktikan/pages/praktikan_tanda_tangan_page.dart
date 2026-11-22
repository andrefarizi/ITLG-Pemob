import 'package:flutter/material.dart';

import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Tanda Tangan Presensi-Praktikan".
///
/// Contoh tanda tangan dari Figma tampil di awal. "Hapus" mengosongkan area,
/// lalu praktikan bisa menggambar tanda tangannya sendiri dengan jari.
class PraktikanTandaTanganPage extends StatefulWidget {
  final PraktikanNav nav;
  final String method;
  final double? lat;
  final double? lng;
  final double? distanceMeters;

  const PraktikanTandaTanganPage({
    super.key,
    required this.nav,
    this.method = 'location',
    this.lat,
    this.lng,
    this.distanceMeters,
  });

  @override
  State<PraktikanTandaTanganPage> createState() =>
      _PraktikanTandaTanganPageState();
}

class _PraktikanTandaTanganPageState extends State<PraktikanTandaTanganPage> {
  final List<List<Offset>> _strokes = [];
  bool _agree = true;
  bool _submitting = false;

  bool get _signed => _strokes.any((s) => s.length > 1);

  void _clear() => setState(() {
        _strokes.clear();
      });

  Future<void> _kirim() async {
    if (_submitting) return;
    if (!_signed) {
      labToast(context, 'Bubuhkan tanda tangan terlebih dahulu');
      return;
    }
    if (!_agree) {
      labToast(context, 'Centang pernyataan kehadiran terlebih dahulu');
      return;
    }
    setState(() => _submitting = true);
    final auth = AuthController.instance;
    final session = PresensiSyncService.instance.activeSession;
    await PresensiSyncService.instance.submitPresence(
      courseId: session.courseId,
      meetingNumber: session.meetingNumber,
      userIdentifier: auth.userIdentifier,
      userName: auth.userName,
      method: widget.method,
      lat: widget.lat ?? session.lat,
      lng: widget.lng ?? session.lng,
      distanceMeters: widget.distanceMeters ?? 12.0,
      hasSignature: true,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    final nav = widget.nav;
    prakShowPresensiBerhasil(
      context,
      onPilihMeja: nav.pilihMejaFromPresensi,
      onBeranda: nav.home,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        const PrakStepper(step: 1),
        const LabTitle(
          title: 'Tanda Tangan',
          subtitle: 'Bubuhkan tanda tangan sebagai bukti kehadiran anda',
        ),
        LabCard(
          children: [
            PrakSpaceRow(
              left: Text('Verifikasi Berhasil', style: labText(14, w: kBold)),
              right: LabChip.live(
                  widget.method == 'qr' ? 'QR Terverifikasi' : 'Lokasi Sesuai'),
            ),
            LabColumn(
              gap: 8,
              cross: CrossAxisAlignment.start,
              children: [
                const LabMeta(
                  icon: 'book_open',
                  text: 'Praktikum Pemrograman Mobile • Pertemuan 5',
                ),
                const LabMeta(
                  icon: 'location',
                  text: 'Lab Komputer 1, Gedung C Lantai 2',
                ),
                const LabMeta(
                  icon: 'map_marker_radius_outline',
                  text: 'Fasilkom-TI USU, Jl. Alumni, Padang Bulan, Medan',
                ),
                LabMeta(
                  icon: 'crosshairs_gps',
                  text: widget.lat != null && widget.lng != null
                      ? '${widget.lat!.toStringAsFixed(4)}, ${widget.lng!.toStringAsFixed(4)} • ${(widget.distanceMeters ?? 12).toStringAsFixed(0)} meter dari titik presensi'
                      : '3.5621, 98.6600 • 12 meter dari titik presensi',
                ),
                LabMeta(
                  icon: 'clock',
                  text:
                      'Hari ini • ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} WIB',
                ),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabSectionTitle(
                  icon: 'signature_freehand', text: 'Tanda Tangan'),
              right: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _clear,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LabIcon('eraser',
                          size: 14, color: ItlgColors.primary),
                      const SizedBox(width: 4),
                      Text('Hapus', style: labText(12, c: ItlgColors.primary)),
                    ],
                  ),
                ),
              ),
            ),
            _signaturePad(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _agree = !_agree),
              child: Row(
                children: [
                  PrakCheckBox(_agree),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Saya menyatakan benar hadir pada pertemuan ini.',
                        style: labText(12)),
                  ),
                ],
              ),
            ),
          ],
        ),
        LabPrimaryButton(
          icon: 'send',
          label: 'Kirim Presensi',
          large: true,
          onTap: _kirim,
        ),
      ],
    );
  }

  /// Area 338 x 170 (putih cekung): tanda tangan, garis, dan petunjuk.
  Widget _signaturePad() {
    return InnerShadowBox(
      radius: 12,
      height: 170,
      color: Colors.white,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => setState(() {
          _strokes.add([d.localPosition]);
        }),
        onPanUpdate: (d) =>
            setState(() => _strokes.last.add(d.localPosition)),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _SignaturePainter(_strokes)),
            ),
            Positioned(
              left: 25,
              right: 25,
              top: 131.25,
              child: Container(height: 1.5, color: LabColors.divider),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Text(
                'Tanda tangani di atas garis menggunakan jari',
                textAlign: TextAlign.center,
                style: labText(11, w: kMedium, c: ItlgColors.textSubtle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PrakColors.camera
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final s in strokes) {
      if (s.isEmpty) continue;
      if (s.length == 1) {
        canvas.drawCircle(s.first, 1.25, Paint()..color = PrakColors.camera);
        continue;
      }
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (var i = 1; i < s.length; i++) {
        path.lineTo(s[i].dx, s[i].dy);
      }
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
