import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';

/// Figma: "Detail Modul-Aslab".
class AslabDetailModulPage extends StatelessWidget {
  final AslabNav nav;
  const AslabDetailModulPage({super.key, required this.nav});

  @override
  Widget build(BuildContext context) {
    return LabSubPage(
      onLogoTap: nav.home,
      children: [
        LabCard(
          children: [
            const PrakSpaceRow(
              left: LabTag.blue('Modul'),
              right: LabMeta(
                  icon: 'calendar', text: 'Pertemuan 4 • Sen, 28 Sep 2026'),
            ),
            const LabOverline(
              overline: 'Praktikum Pemrograman Mobile',
              title: 'Modul 4 : Flutter\nState Management',
            ),
            Text(
              'Pengenalan setState, InheritedWidget, dan Provider untuk '
              'mengelola state aplikasi Flutter.',
              style: labText(12, c: ItlgColors.textMuted),
            ),
            const LabStatRow(
              gap: 13,
              stats: [
                LabStat(icon: 'eye', label: 'Dilihat', value: '21 / 24'),
                LabStat(icon: 'download', label: 'Diunduh', value: '18 kali'),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(icon: 'book_open', text: 'Berkas Modul'),
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
                  Text('Modul_4_State_Management.pdf',
                      textAlign: TextAlign.center,
                      style: labText(12, w: kBold)),
                  const SizedBox(height: 8),
                  Text('PDF • 18 halaman • 3,2 MB',
                      textAlign: TextAlign.center,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                ],
              ),
            ),
            LabButtonPair(
              left: LabOutlineButton(
                icon: 'eye',
                label: 'Lihat Modul',
                onTap: () => labToast(
                    context, 'Membuka Modul_4_State_Management.pdf'),
              ),
              right: LabPrimaryButton(
                icon: 'download',
                label: 'Unduh Modul',
                onTap: () => labToast(
                    context, 'Modul_4_State_Management.pdf diunduh'),
              ),
            ),
          ],
        ),
        LabCard(
          children: [
            const PrakSpaceRow(
              left: LabSectionTitle(
                  icon: 'attach', text: 'Lampiran Pendukung'),
              right: PrakSideLink('1 Berkas'),
            ),
            PrakFileItem(
              name: 'starter_project.zip',
              meta: 'ZIP • 4,1 MB',
              action: 'download',
              onAction: () => labToast(context, 'starter_project.zip diunduh'),
            ),
          ],
        ),
        LabColumn(
          gap: 12,
          children: [
            LabPrimaryButton(
              icon: 'pencil',
              label: 'Edit Modul',
              large: true,
              onTap: () => nav.editModul(context),
            ),
            LabOutlineButton(
              icon: 'delete_filled',
              label: 'Hapus Modul',
              large: true,
              onTap: () {
                Navigator.of(context).maybePop();
                labToast(context, 'Modul 4 dihapus');
              },
            ),
          ],
        ),
      ],
    );
  }
}
