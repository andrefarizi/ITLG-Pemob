import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Scan QR Presensi-Praktikan".
///
/// Sesuai prototipe: ketuk area kamera atau "Pindai Ulang" untuk lanjut ke
/// Tanda Tangan. Garis hijau bergerak naik-turun sebagai animasi pindai.
class PraktikanScanQrPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanScanQrPage({super.key, required this.nav});

  @override
  State<PraktikanScanQrPage> createState() => _PraktikanScanQrPageState();
}

class _PraktikanScanQrPageState extends State<PraktikanScanQrPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _scan.dispose();
    _camera.dispose();
    super.dispose();
  }

  final MobileScannerController _camera = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handled = false;
  DateTime? _lastInvalidToast;

  void _verified(String courseId, int meetingNumber) => widget.nav.tandaTangan(
        context,
        method: 'qr',
        courseId: courseId,
        meetingNumber: meetingNumber,
      );

  void _onDetect(BarcodeCapture capture) {
    if (_handled || !mounted) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null || raw.isEmpty) continue;
      final res = PresensiSyncService.instance.validateScannedQr(raw);
      if (res.error == null) {
        _handled = true;
        _camera.stop();
        _verified(res.courseId, res.meetingNumber);
      } else {
        final now = DateTime.now();
        if (_lastInvalidToast == null ||
            now.difference(_lastInvalidToast!) > const Duration(seconds: 2)) {
          _lastInvalidToast = now;
          labToast(context, res.error!);
        }
      }
      break;
    }
  }

  Future<void> _rescan() async {
    _handled = false;
    _lastInvalidToast = null;
    try {
      await _camera.stop();
    } catch (_) {}
    try {
      await _camera.start();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final nav = widget.nav;
    return LabSubPage(
      onLogoTap: nav.home,
      children: [
        const PrakStepper(step: 0),
        const LabTitle(
          title: 'Presensi Praktikum',
          subtitle:
              'Pindai QR Code dinamis yang ditampilkan asisten di layar lab',
        ),
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: PrakColors.camera,
            borderRadius: BorderRadius.circular(24),
            boxShadow: ItlgShadows.outline,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _camera,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Kamera tidak dapat diakses. Izinkan akses kamera '
                        'di pengaturan perangkat.',
                        textAlign: TextAlign.center,
                        style: labText(12, c: Colors.white),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const LabChip.live('Kamera Aktif'),
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          children: [
                            // Garis 6 px di luar vektor 192 px -> gambar 198 px.
                            Positioned(
                              left: 1,
                              top: 1,
                              width: 198,
                              height: 198,
                              child: Image.asset(
                                  'assets/praktikan_viewfinder.png',
                                  fit: BoxFit.fill),
                            ),
                            AnimatedBuilder(
                              animation: _scan,
                              builder: (_, __) => Positioned(
                                left: 24,
                                width: 152,
                                top: 28.5 +
                                    140 *
                                        Curves.easeInOut
                                            .transform(_scan.value),
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: LabColors.green,
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('Arahkan kamera ke QR Code di layar asisten',
                          textAlign: TextAlign.center,
                          style: labText(12, c: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ListenableBuilder(
          listenable: PresensiSyncService.instance,
          builder: (_, __) {
            final session = PresensiSyncService.instance.activeSession;
            final course =
                PraktikumSyncService.instance.courseById(session.courseId);
            return LabCard(
              children: [
                PrakSpaceRow(
                  left: session.isActive
                      ? const LabChip.live('Presensi Berlangsung')
                      : const LabChip.idle('Sesi Ditutup'),
                  right: LabPill(
                    icon: 'calendar',
                    text: 'Minggu ke-${session.meetingNumber}',
                  ),
                ),
                Text('Praktikum\n${course.name}',
                    style: labText(22, w: kBold, c: Colors.black)),
                const PrakSessionMeta(),
                LabInsetBox(
                  child: Row(
                    children: [
                      const LabIcon('shield_check_outline',
                          size: 20, color: ItlgColors.secondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LabColumn(
                          gap: 2,
                          children: [
                            Text('Validasi Sesi Aktif',
                                style: labText(12, w: kBold)),
                            Text(
                              'QR diperbarui tiap 5 menit dan hanya berlaku pada '
                              'sesi yang sedang berjalan.',
                              style: labText(12, c: ItlgColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        LabOutlineButton(
          icon: 'arrow_cycle',
          label: 'Pindai Ulang',
          large: true,
          onTap: _rescan,
        ),
        PrakLink(
          'Tidak bisa memindai? Gunakan Tombol Hadir',
          onTap: () => nav.tombolHadir(context, replace: true),
        ),
      ],
    );
  }
}
