import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';
import '../widgets/aslab_ui.dart';

/// Figma: "Sesi Aktif & QR Presensi-Aslab".
///
/// QR berganti tiap 15 detik (hitung mundur berjalan, gambar QR dibalik
/// sebagai tanda kode baru).
class AslabSesiAktifPage extends StatefulWidget {
  final AslabNav nav;
  const AslabSesiAktifPage({super.key, required this.nav});

  @override
  State<AslabSesiAktifPage> createState() => _AslabSesiAktifPageState();
}

class _AslabSesiAktifPageState extends State<AslabSesiAktifPage> {
  Timer? _timer;

  /// Figma: 12 detik tersisa.
  int _left = 12;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_left > 1) {
          _left--;
        } else {
          _left = 15;
          _generation++;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _akhiri() {
    labToast(context, 'Sesi presensi diakhiri');
    widget.nav.goTab(AslabTab.absensi);
  }

  @override
  Widget build(BuildContext context) {
    final nav = widget.nav;
    return LabSubPage(
      onLogoTap: nav.home,
      children: [
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabChip.live('Sesi Berlangsung'),
              right: AslabElapsedPill(start: nav.store.sessionStart),
            ),
            const AslabClassTitle(),
            const Row(
              children: [
                Flexible(
                  child:
                      LabMeta(icon: 'clock', text: 'Senin • 08:00–09:40 WIB'),
                ),
                SizedBox(width: 24),
                Flexible(
                  child: LabMeta(icon: 'location', text: 'Lab Komputer 1'),
                ),
              ],
            ),
            const Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                LabTag.blue('QR Dinamis'),
                LabTag.blue('Tombol + Lokasi 50 m'),
                LabTag.blue('Wajib Tanda Tangan'),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            const PrakSpaceRow(
              left: LabSectionTitle(icon: 'qrcode', text: 'QR Code Presensi'),
              right: LabTag.blue('Dinamis'),
            ),
            InnerShadowBox(
              radius: 12,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Transform(
                      key: ValueKey<int>(_generation),
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(
                          _generation.isOdd ? -1 : 1, 1, 1),
                      child: Image.asset('assets/aslab_qr.png',
                          width: 220, height: 220),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Diperbarui otomatis dalam',
                      style: labText(12, c: ItlgColors.textSubtle)),
                  const SizedBox(height: 2),
                  Text('$_left detik',
                      style: labText(22, w: kBold, c: ItlgColors.primary)),
                ],
              ),
            ),
            LabProgress(
              label: 'Auto-refresh setiap 15 detik',
              value: '$_left dtk',
              fraction: _left / 15,
              color: ItlgColors.primary,
            ),
            Row(
              children: [
                const LabIcon('shield_check_outline',
                    size: 14, color: ItlgColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kode lama langsung hangus sehingga tangkapan layar tidak '
                    'dapat dipakai untuk presensi.',
                    style: labText(12, c: ItlgColors.textMuted),
                  ),
                ),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabSectionTitle(
                  icon: 'people_group', text: 'Kehadiran Praktikan'),
              right: Text('18 / 24',
                  style: labText(16, w: kBold, c: ItlgColors.primary)),
            ),
            const LabProgress(
              label: 'Rasio Kehadiran',
              value: '75%',
              fraction: 254 / 338,
            ),
            LabColumn(
              gap: 8,
              children: [
                for (final (s, how) in const [
                  (kRina, 'QR • 08:02'),
                  (kDimas, 'Tombol • 08:03'),
                  (kMaya, 'QR • 08:05'),
                ])
                  LabListItem(
                    leading: LabAvatar(s.initials),
                    title: s.name,
                    subtitle: s.nim,
                    trailing: LabMeta(
                        icon: 'check', text: how, color: LabColors.green),
                    onTap: () => nav.buktiPresensi(context),
                  ),
              ],
            ),
          ],
        ),
        LabOutlineButton(
          icon: 'stop',
          label: 'Akhiri Sesi',
          large: true,
          onTap: _akhiri,
        ),
      ],
    );
  }
}
