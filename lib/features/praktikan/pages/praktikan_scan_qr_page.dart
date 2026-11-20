import 'package:flutter/material.dart';

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
    super.dispose();
  }

  void _verified() => widget.nav.tandaTangan(context);

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
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _verified,
          child: Container(
            height: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: PrakColors.camera,
              borderRadius: BorderRadius.circular(24),
              boxShadow: ItlgShadows.outline,
            ),
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
                        child: Image.asset('assets/praktikan_viewfinder.png',
                            fit: BoxFit.fill),
                      ),
                      AnimatedBuilder(
                        animation: _scan,
                        builder: (_, __) => Positioned(
                          left: 24,
                          width: 152,
                          // Figma: komponen "Garis Scan QR (Animasi)", pusat
                          // garis bergerak y 30 <-> 170, Ease In and Out 1,6 s.
                          top: 28.5 +
                              140 * Curves.easeInOut.transform(_scan.value),
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
        ),
        LabCard(
          children: [
            const PrakSpaceRow(
              left: LabChip.live('Presensi Berlangsung'),
              right: LabPill(icon: 'calendar', text: 'Minggu ke-4'),
            ),
            Text('Praktikum\nPemrograman Mobile',
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
                          'QR diperbarui tiap 15 detik dan hanya berlaku pada '
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
        ),
        LabOutlineButton(
          icon: 'arrow_cycle',
          label: 'Pindai Ulang',
          large: true,
          onTap: _verified,
        ),
        PrakLink(
          'Tidak bisa memindai? Gunakan Tombol Hadir',
          onTap: () => nav.tombolHadir(context, replace: true),
        ),
      ],
    );
  }
}
