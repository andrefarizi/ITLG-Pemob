import 'package:flutter/material.dart';

import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../widgets/aslab_ui.dart';
import 'aslab_praktikum_saya_page.dart';

/// Figma: "Absensi-Aslab".
class AslabAbsensiPage extends StatelessWidget {
  final AslabNav nav;
  const AslabAbsensiPage({super.key, required this.nav});

  @override
  Widget build(BuildContext context) {
    final store = nav.store;
    return LabTabBody(
      children: [
        const LabTitle(
          title: 'Absensi',
          subtitle: 'Presensi praktikan di setiap praktikum yang anda ampu',
        ),
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabChip.live('Sesi Berlangsung'),
              right: AslabElapsedPill(start: store.sessionStart),
            ),
            Text('Praktikum Pemrograman Mobile • Pertemuan 5',
                style: labText(16, w: kBold, c: Colors.black)),
            const LabProgress(
              label: 'Kehadiran sementara',
              value: '18 / 24',
              fraction: 254 / 338,
            ),
            LabPrimaryButton(
              icon: 'qrcode',
              label: 'Lihat Sesi & QR Presensi',
              large: true,
              onTap: () => nav.sesiAktif(context),
            ),
          ],
        ),
        LabColumn(
          gap: 12,
          children: [
            const PrakSpaceRow(
              left: LabHeading(
                  icon: 'book_open', text: 'Absensi per Praktikum'),
              right: PrakSideLink('2 Praktikum'),
            ),
            AslabCourseGrid(
              courses: store.courses,
              thirdMeta: (c) =>
                  ('statistic_up', 'Rata-rata hadir ${c.rataHadir}'),
              onTap: (c) => nav.detailAbsensi(context, c),
            ),
          ],
        ),
      ],
    );
  }
}
