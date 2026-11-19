import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../laboran_store.dart';
import '../../shared/lab_actions.dart';
import '../widgets/laboran_ui.dart';

/// Figma: "Presensi Asisten-Laboran".
class LaboranPresensiAsistenPage extends StatefulWidget {
  final LaboranStore store;
  final VoidCallback? onLogoTap;

  const LaboranPresensiAsistenPage({
    super.key,
    required this.store,
    this.onLogoTap,
  });

  @override
  State<LaboranPresensiAsistenPage> createState() =>
      _LaboranPresensiAsistenPageState();
}

class _LaboranPresensiAsistenPageState
    extends State<LaboranPresensiAsistenPage> {
  void _generate() {
    setState(() {
      widget.store.accessCode = 'ITLG-${1000 + Random().nextInt(9000)}';
    });
    labToast(context, 'Kode akses baru: ${widget.store.accessCode}');
  }

  @override
  Widget build(BuildContext context) {
    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      children: [
        LabCard(
          children: [
            const LabOverline(
              overline: 'Senin, 28 September 2026',
              title: 'Presensi Asisten',
            ),
            LabInsetBox(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Kode Akses Presensi Hari Ini',
                      style: labText(12, c: ItlgColors.textSubtle)),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      widget.store.accessCode,
                      key: ValueKey<String>(widget.store.accessCode),
                      style: labText(27, w: kBold, c: ItlgColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const LabMeta(
                      icon: 'clock', text: 'Berlaku sampai 17:00 WIB'),
                ],
              ),
            ),
            LabButtonPair(
              left: LabOutlineButton(
                icon: 'qrcode',
                label: 'Tampilkan QR',
                onTap: () => labShowQr(
                  context,
                  title: 'QR Presensi Asisten',
                  code: widget.store.accessCode,
                  caption: 'Asisten memindai QR ini untuk presensi shift. '
                      'Berlaku sampai 17:00 WIB.',
                ),
              ),
              right: LabPrimaryButton(
                icon: 'key',
                label: 'Generate Akses',
                onTap: _generate,
              ),
            ),
          ],
        ),
        LabCard(
          children: [
            Row(
              children: [
                const LabSectionTitle(
                    icon: 'people_group', text: 'Asisten Bertugas'),
                const Spacer(),
                Text('4 / 6 Hadir',
                    style: labText(16, w: kBold, c: ItlgColors.primary)),
              ],
            ),
            const LabColumn(
              gap: 8,
              children: [
                LabListItem(
                  leading: LabAvatar('AP'),
                  title: 'Andi Pratama',
                  subtitle: 'Shift Pagi • Lab Komputer 1',
                  trailing: LabChip.live('07:52'),
                ),
                LabListItem(
                  leading: LabAvatar('FG'),
                  title: 'Feri Gunawan',
                  subtitle: 'Shift Pagi • Lab Jaringan 2',
                  trailing: LabChip.live('07:58'),
                ),
                LabListItem(
                  leading: LabAvatar('SM'),
                  title: 'Sinta Marpaung',
                  subtitle: 'Shift Pagi • Lab Multimedia',
                  trailing: LabChip.warn('Terlambat'),
                ),
                LabListItem(
                  leading: LabAvatar('RH'),
                  title: 'Rizky Harahap',
                  subtitle: 'Shift Siang • Lab Komputer 1',
                  trailing: LabChip.idle('Belum'),
                ),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            Row(
              children: const [
                LabSectionTitle(icon: 'chart_bar', text: 'Rekap Kedisiplinan'),
                Spacer(),
                LabPill(icon: 'calendar', text: 'September'),
              ],
            ),
            const LabProgress(
                label: 'Andi Pratama', value: '96%', fraction: 324 / 338),
            const LabProgress(
                label: 'Feri Gunawan', value: '92%', fraction: 311 / 338),
            const LabProgress(
              label: 'Sinta Marpaung',
              value: '78%',
              fraction: 264 / 338,
              color: ItlgColors.primary,
            ),
            const LabProgress(
                label: 'Rizky Harahap', value: '85%', fraction: 287 / 338),
            Container(height: 1, color: const Color(0x80B5B9BC)),
            Row(
              children: [
                Expanded(
                  child: Text('Rata-rata Tepat Waktu',
                      style: labText(12, w: kBold)),
                ),
                Text('88%',
                    style: labText(16, w: kBold, c: ItlgColors.primary)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
