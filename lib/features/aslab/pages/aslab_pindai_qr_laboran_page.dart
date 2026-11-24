import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/services/notification_sync_service.dart';
import '../../../core/services/shift_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';

/// Shift milik asisten yang login pada HARI INI (WIB). Null bila tidak ada —
/// jangan pernah jatuh ke shift asisten lain.
ShiftRecord? _resolveMyShift(ShiftSyncService shiftSync) {
  final myName = AuthController.instance.userName;
  final wd = DateTime.now().toUtc().add(const Duration(hours: 7)).weekday;
  final today = wd == DateTime.sunday ? -1 : wd - 1;
  final mine = shiftSync.allShifts
      .where((s) => s.asistenName == myName && s.dayIndex == today)
      .toList();
  if (mine.isEmpty) return null;
  return mine.firstWhere(
    (s) => s.attendanceStatus.toLowerCase() == 'belum',
    orElse: () => mine.first,
  );
}

/// Bottom sheet input kode akses presensi mengajar.
Future<bool> showAslabCheckInCodeSheet(BuildContext context) async {
  final controller = TextEditingController();
  final shiftSync = ShiftSyncService.instance;
  await shiftSync.refreshFromBackend();
  if (!context.mounted) {
    controller.dispose();
    return false;
  }

  String checkedInRoom = 'Lab Jaringan 1';
  bool submitting = false;

  final result = await labShowCustomSheet<bool>(
    context,
    title: 'Masukkan Kode Akses',
    subtitle:
        'Minta kode ke Laboran yang bertugas. Kode berlaku sampai ${shiftSync.accessValidUntil} dan hanya untuk jadwal mengajar hari ini.',
    child: StatefulBuilder(
      builder: (ctx, setSheetState) {
        return LabColumn(
          gap: 14,
          children: [
            PrakField(
              label: 'Kode Akses',
              child: PrakInput(
                controller: controller,
                hint: 'ITLG-____',
                leadingIcon: 'key',
              ),
            ),
            LabPrimaryButton(
              icon: 'check',
              label: submitting ? 'Memverifikasi...' : 'Check-In Sekarang',
              large: true,
              onTap: () async {
                if (submitting) return;
                final input = controller.text.trim().toUpperCase();
                if (input.isEmpty) {
                  labToast(ctx, 'Masukkan kode akses dari Laboran');
                  return;
                }
                setSheetState(() => submitting = true);
                await shiftSync.refreshFromBackend();
                final expected = shiftSync.accessCode.trim().toUpperCase();
                if (!ctx.mounted) return;
                if (shiftSync.isAccessCodeExpired) {
                  setSheetState(() => submitting = false);
                  labToast(ctx,
                      'Kode akses sudah kedaluwarsa. Minta Laboran membuat kode baru.');
                  return;
                }
                if (input != expected) {
                  setSheetState(() => submitting = false);
                  labToast(
                    ctx,
                    'Kode akses tidak cocok. Periksa kode harian aktif di layar Laboran.',
                  );
                  return;
                }

                final myShift = _resolveMyShift(shiftSync);
                if (myShift == null) {
                  labToast(context, 'Tidak ada jadwal mengajar kamu hari ini',
                      error: true);
                  return;
                }
                checkedInRoom = myShift.room;
                try {
                  await shiftSync.updateShiftAttendance(
                    shiftId: myShift.id,
                    status: 'hadir',
                  );
                } on StateError catch (e) {
                  if (context.mounted) labToast(context, e.message);
                  return;
                }
                NotificationSyncService.instance.push(
                  role: 'laboran',
                  icon: 'key',
                  title: 'Check-In Asisten Berhasil',
                  body:
                      '${AuthController.instance.userName} check-in mengajar di ${myShift.room} (${myShift.shiftLabel}) dengan kode akses.',
                  targetKey: 'presensi',
                  important: false,
                );
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop(true);
              },
            ),
          ],
        );
      },
    ),
  );
  // Lepas controller setelah animasi tutup sheet selesai.
  Future<void>.delayed(const Duration(milliseconds: 600), controller.dispose);
  if (result == true && context.mounted) {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    await labShowResultDialog(
      context,
      icon: 'circle_check',
      title: 'Check-In Berhasil',
      message:
          'Kehadiran mengajar tercatat pukul $hh:$mm WIB di $checkedInRoom. Laboran langsung melihat status kamu.',
      button: 'Selesai',
    );
    return true;
  }
  return false;
}

/// Halaman Pindai QR Laboran Asisten Lab.
class AslabPindaiQrLaboranPage extends StatefulWidget {
  final VoidCallback? onLogoTap;
  const AslabPindaiQrLaboranPage({super.key, this.onLogoTap});

  @override
  State<AslabPindaiQrLaboranPage> createState() =>
      _AslabPindaiQrLaboranPageState();
}

class _AslabPindaiQrLaboranPageState extends State<AslabPindaiQrLaboranPage> {
  final MobileScannerController _scanner = MobileScannerController();
  final ShiftSyncService _shiftSync = ShiftSyncService.instance;
  bool _done = false;
  DateTime? _lastInvalidToast;
  int _remaining = 13 * 60 + 20;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _shiftSync.refreshFromBackend();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0 && mounted) setState(() => _remaining--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _handleQrScanned(String rawValue) async {
    if (_done) return;
    final scanned = rawValue.trim().toUpperCase();
    if (scanned.isEmpty) return;

    if (!_shiftSync.isQrPayloadValid(scanned)) {
      final now = DateTime.now();
      if (_lastInvalidToast == null ||
          now.difference(_lastInvalidToast!).inSeconds >= 3) {
        _lastInvalidToast = now;
        if (mounted) {
          labToast(
            context,
            'QR tidak cocok atau kedaluwarsa. Pindai QR terbaru dari Laboran.',
          );
        }
      }
      return;
    }

    final myShift = _resolveMyShift(_shiftSync);
    if (myShift == null) {
      labToast(context, 'Tidak ada jadwal mengajar kamu hari ini', error: true);
      return;
    }
    _done = true;
    try {
      await _shiftSync.updateShiftAttendance(
        shiftId: myShift.id,
        status: 'hadir',
      );
    } on StateError catch (e) {
      _done = false;
      if (mounted) labToast(context, e.message);
      return;
    }
    NotificationSyncService.instance.push(
      role: 'laboran',
      icon: 'qrcode',
      title: 'Check-In Asisten via QR',
      body:
          '${AuthController.instance.userName} check-in mengajar di ${myShift.room} (${myShift.shiftLabel}).',
      targetKey: 'presensi',
      important: false,
    );
    if (!mounted) return;
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    await labShowResultDialog(
      context,
      icon: 'circle_check',
      title: 'Check-In Berhasil',
      message:
          'Kehadiran mengajar tercatat pukul $hh:$mm WIB di ${myShift.room}. Laboran langsung melihat status kamu.',
      button: 'Selesai',
      onPressed: () => Navigator.of(context).maybePop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _shiftSync,
      builder: (context, _) {
        final myShift = _resolveMyShift(_shiftSync);
        return LabSubPage(
          onLogoTap: widget.onLogoTap,
          children: [
            const LabTitle(
              title: 'Presensi Mengajar',
              subtitle:
                  'Pindai QR yang ditampilkan Laboran di meja Laboran untuk mencatat kehadiran mengajar.',
            ),
            // Area kamera gelap dengan pill "Kamera Aktif"
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 340,
                color: const Color(0xFF1F2226),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _scanner,
                      onDetect: (capture) {
                        for (final b in capture.barcodes) {
                          final raw = b.rawValue;
                          if (raw != null && raw.trim().isNotEmpty) {
                            _handleQrScanned(raw);
                            break;
                          }
                        }
                      },
                    ),
                    // Overlay gelap lembut di tepi agar siku pemindai jelas
                    Container(color: const Color(0x550A0B0C)),
                    const Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Center(child: LabChip.live('Kamera Aktif')),
                    ),
                    Center(
                      child: SizedBox(
                        width: 190,
                        height: 190,
                        child: CustomPaint(
                          painter: _QrBracketsPainter(),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 18,
                      child: Text(
                        'Arahkan kamera ke QR di layar Laboran',
                        textAlign: TextAlign.center,
                        style: labText(12, w: kSemiBold, c: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            LabCard(
              gap: 12,
              children: [
                PrakSpaceRow(
                  left: const LabChip.live('Check-In Dibuka'),
                  right: LabMeta(
                      icon: 'calendar', text: 'Sisa ${prakClock(_remaining)}'),
                ),
                Text(myShift?.courseName ?? 'Tidak ada jadwal mengajar hari ini',
                    style: labText(20, w: kBold, c: Colors.black)),
                if (myShift != null)
                  Row(
                    children: [
                      Flexible(
                        child: LabMeta(
                            icon: 'clock',
                            text: '${myShift.shiftLabel} • ${myShift.timeRange}'),
                      ),
                      const SizedBox(width: 14),
                      Flexible(
                          child: LabMeta(icon: 'location', text: myShift.room)),
                    ],
                  ),
                const LabMeta(icon: 'person', text: 'Laboran: Reagan Brian'),
                LabInsetBox(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: LabIcon('shield_check_outline',
                            size: 18, color: LabColors.blueDark),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Validasi Jadwal Mengajar',
                                style: labText(12, w: kBold)),
                            const SizedBox(height: 2),
                            Text(
                              'Kode QR diperbarui tiap 60 detik dan hanya berlaku untuk jadwal mengajar hari ini.',
                              style: labText(11, c: ItlgColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            LabColumn(
              gap: 14,
              children: [
                LabOutlineButton(
                  icon: 'qrcode',
                  label: 'Pindai QR',
                  large: true,
                  onTap: () async {
                    await _shiftSync.refreshFromBackend();
                    await _scanner.start();
                    if (!context.mounted) return;
                    labToast(
                      context,
                      'Kamera aktif. Arahkan ke QR Laboran atau masukkan Kode Akses.',
                    );
                  },
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final ok = await showAslabCheckInCodeSheet(context);
                    if (ok && mounted) navigator.maybePop(true);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Tidak bisa memindai? Masukkan Kode Akses',
                      textAlign: TextAlign.center,
                      style: labText(13, w: kBold, c: ItlgColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _QrBracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    const r = 18.0;
    const len = 34.0;
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(len, 0),
      p,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - len, 0)
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r)
        ..lineTo(w, len),
      p,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, h - len)
        ..lineTo(0, h - r)
        ..quadraticBezierTo(0, h, r, h)
        ..lineTo(len, h),
      p,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w - len, h)
        ..lineTo(w - r, h)
        ..quadraticBezierTo(w, h, w, h - r)
        ..lineTo(w, h - len),
      p,
    );

    // Garis pindai hijau
    final linePaint = Paint()
      ..color = LabColors.green
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(14, 24), Offset(w - 14, 24), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
