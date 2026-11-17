import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Pilih Metode Presensi-Praktikan".
class PraktikanPilihMetodePage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanPilihMetodePage({super.key, required this.nav});

  @override
  State<PraktikanPilihMetodePage> createState() =>
      _PraktikanPilihMetodePageState();
}

class _PraktikanPilihMetodePageState extends State<PraktikanPilihMetodePage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final s = widget.nav.store;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (s.presensiSecondsLeft > 0) setState(() => s.presensiSecondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = widget.nav;
    return LabSubPage(
      onLogoTap: nav.home,
      children: [
        const PrakStepper(step: 0),
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabChip.live('Presensi Berlangsung'),
              right: LabPill(
                icon: 'clock',
                text: 'Sisa ${prakClock(nav.store.presensiSecondsLeft)}',
              ),
            ),
            const LabOverline(
              overline: 'Pertemuan 5 • TIF 3001 - Kelas C',
              title: 'Praktikum\nPemrograman Mobile',
            ),
            const PrakSessionMeta(),
          ],
        ),
        LabColumn(
          gap: 12,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabHeading(
                  icon: 'shield_check_outline', text: 'Pilih Cara Verifikasi'),
            ),
            _MethodCard(
              icon: 'qrcode',
              title: 'Pindai QR Code',
              description: 'Arahkan kamera ke QR dinamis yang ditampilkan '
                  'asisten di layar lab.',
              metaIcon: 'camera',
              meta: 'Butuh kamera',
              duration: '± 5 detik',
              onTap: () => nav.scanQr(context),
            ),
            _MethodCard(
              icon: 'gesture_tap_button',
              title: 'Tombol Hadir',
              description: 'Tanpa kamera. Tekan tombol hadir, lokasi anda '
                  'dicek berada di area lab.',
              metaIcon: 'location',
              meta: 'Butuh lokasi (GPS)',
              duration: '± 10 detik',
              onTap: () => nav.tombolHadir(context),
            ),
          ],
        ),
        const PrakNotice.info(
          icon: 'signature_freehand',
          text: 'Setelah verifikasi berhasil, anda diminta tanda tangan lalu '
              'presensi dikirim.',
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final String metaIcon;
  final String meta;
  final String duration;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.metaIcon,
    required this.meta,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LabCard(
      gap: 12,
      onTap: onTap,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ItlgColors.primary,
                borderRadius: BorderRadius.circular(9),
                boxShadow: LabShadows.neu,
              ),
              child: LabIcon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LabColumn(
                gap: 4,
                children: [
                  Text(title, style: labText(16, w: kBold, c: Colors.black)),
                  Text(description,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const LabIcon('chevron_right', size: 18, color: ItlgColors.primary),
          ],
        ),
        const PrakDivider(),
        Row(
          children: [
            LabMeta(icon: metaIcon, text: meta),
            const SizedBox(width: 16),
            LabMeta(icon: 'clock', text: duration),
          ],
        ),
      ],
    );
  }
}
