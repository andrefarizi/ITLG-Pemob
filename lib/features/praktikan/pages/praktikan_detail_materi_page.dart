import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../widgets/praktikan_ui.dart';
import '../../shared/lab_actions.dart';

/// Figma: "Detail Materi-Praktikan".
class PraktikanDetailMateriPage extends StatelessWidget {
  final PraktikanNav nav;
  const PraktikanDetailMateriPage({super.key, required this.nav});

  @override
  Widget build(BuildContext context) {
    return LabSubPage(
      onLogoTap: nav.home,
      children: [
        LabCard(
          children: [
            const PrakSpaceRow(
              left: LabTag.blue('Materi'),
              right:
                  LabMeta(icon: 'calendar', text: 'Sen, 28 September 2026'),
            ),
            const LabOverline(
              overline: 'Praktikum Desain Interaksi',
              title: 'Modul 4 :\nFigma Management',
            ),
            Text(
              'Pembahasan pengelolaan file Figma: struktur page, komponen, '
              'variant, auto layout, serta style warna dan tipografi.',
              style: labText(12, c: ItlgColors.textMuted),
            ),
            const LabPerson(
              initials: 'FG',
              name: 'Feri Gunawan',
              caption: 'Asisten Lab • Diunggah 27 Sep 2026, 19:40',
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(icon: 'book_open', text: 'Berkas Materi'),
            ),
            InnerShadowBox(
              radius: 12,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ItlgColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ItlgShadows.outline,
                    ),
                    child: const LabIcon('file',
                        size: 32, color: ItlgColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text('Panduan Penggunaan Figma.pdf',
                      textAlign: TextAlign.center,
                      style: labText(12, w: kBold)),
                  const SizedBox(height: 8),
                  Text('PDF • 24 halaman • 3,2 MB',
                      textAlign: TextAlign.center,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                ],
              ),
            ),
            LabButtonPair(
              left: LabOutlineButton(
                icon: 'eye',
                label: 'Lihat Materi',
                onTap: () => labShowFilePreview(
                  context,
                  name: 'Panduan Penggunaan Figma.pdf',
                  size: '3,1 MB',
                  source: 'Materi Pertemuan 4',
                ),
              ),
              right: LabPrimaryButton(
                icon: 'download',
                label: 'Unduh Materi',
                // Figma: Unduh Materi → "Pop up Materi Diunduh".
                onTap: () => labShowResult(
                  context,
                  icon: 'download',
                  title: 'Materi Diunduh',
                  message: 'Berkas materi tersimpan di folder Unduhan '
                      'perangkat anda.',
                ),
              ),
            ),
          ],
        ),
        LabCard(
          children: [
            const PrakSpaceRow(
              left: LabSectionTitle(
                  icon: 'attach', text: 'Lampiran Pendukung'),
              right: PrakSideLink('2 Berkas'),
            ),
            LabColumn(
              gap: 8,
              children: [
                PrakFileItem(
                  name: 'Starter_File_Modul4.fig',
                  meta: 'Figma • 1,8 MB',
                  action: 'download',
                  onAction: () =>
                      labToast(context, 'Starter_File_Modul4.fig diunduh'),
                ),
                PrakFileItem(
                  name: 'Contoh_Prototype.mp4',
                  meta: 'Video • 12 MB',
                  action: 'download',
                  onAction: () =>
                      labToast(context, 'Contoh_Prototype.mp4 diunduh'),
                ),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(icon: 'clipboard', text: 'Tugas Terkait'),
            ),
            LabListItem(
              leading: const LabIconTile('clipboard'),
              title: 'Tugas 4 : Pembuatan Prototype Figma',
              subtitle: 'Deadline 29 Sep 2026, 10:30 WIB',
              titleSize: 12,
              trailing: const LabIcon('chevron_right',
                  size: 16, color: ItlgColors.primary),
              onTap: () => nav.editTugas(context),
            ),
          ],
        ),
      ],
    );
  }
}
