import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../shared/lab_actions.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Detail Materi-Praktikan".
class PraktikanDetailMateriPage extends StatelessWidget {
  final PraktikanNav nav;
  final PrakCourse? course;
  final PrakMeeting? meeting;

  const PraktikanDetailMateriPage({
    super.key,
    required this.nav,
    this.course,
    this.meeting,
  });

  @override
  Widget build(BuildContext context) {
    final c = course ?? PraktikumSyncService.instance.courses.first;
    final m = meeting ??
        c.meetings.firstWhere(
          (e) => e.number == 4,
          orElse: () => c.meetings.first,
        );
    final modTitle = m.module.replaceFirst(' • ', ' :\n');
    final dateText = m.date.split(' • ').first;
    final desc = m.description.isNotEmpty ? m.description : c.modulDesc;
    final pdfName = m.materiFile.isNotEmpty
        ? m.materiFile
        : (c.materiFile.isNotEmpty
            ? c.materiFile
            : '${c.materiTitle}.pdf');
    final tugasTitle = m.tugasTitle.isNotEmpty ? m.tugasTitle : c.tugasTitle;
    final deadline =
        m.tugasDeadline.isNotEmpty ? m.tugasDeadline : c.tugasDeadline;

    return LabSubPage(
      onLogoTap: nav.home,
      children: [
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabTag.blue('Materi'),
              right: LabMeta(icon: 'calendar', text: dateText),
            ),
            LabOverline(
              overline: 'Praktikum ${c.name}',
              title: modTitle,
            ),
            Text(
              desc,
              style: labText(12, c: ItlgColors.textMuted),
            ),
            LabPerson(
              initials: c.asistenInitials,
              name: c.asisten,
              caption: 'Asisten Lab • Diunggah sebelum pertemuan',
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
                  Text(pdfName,
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
                  name: pdfName,
                  size: '3,2 MB',
                  source: 'Materi Pertemuan ${m.number}',
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
                  name: 'Starter_Modul_${m.number}_${c.id}.zip',
                  meta: 'ZIP • 1,8 MB',
                  action: 'download',
                  onAction: () => labToast(
                      context, 'Starter_Modul_${m.number}_${c.id}.zip diunduh'),
                ),
                PrakFileItem(
                  name: 'Contoh_Praktikum_M${m.number}.mp4',
                  meta: 'Video • 12 MB',
                  action: 'download',
                  onAction: () => labToast(
                      context, 'Contoh_Praktikum_M${m.number}.mp4 diunduh'),
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
              title: tugasTitle,
              subtitle: deadline,
              titleSize: 12,
              trailing: const LabIcon('chevron_right',
                  size: 16, color: ItlgColors.primary),
              onTap: () => nav.editTugas(context, course: c, meeting: m),
            ),
          ],
        ),
      ],
    );
  }
}
