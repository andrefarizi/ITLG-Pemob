import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../../shared/lab_actions.dart';
import '../aslab_nav.dart';

/// Figma: "Detail Modul-Aslab".
class AslabDetailModulPage extends StatelessWidget {
  final AslabNav nav;
  final String courseId;
  final int meetingNumber;

  const AslabDetailModulPage({
    super.key,
    required this.nav,
    this.courseId = 'pemob',
    this.meetingNumber = 4,
  });

  @override
  Widget build(BuildContext context) {
    final sync = PraktikumSyncService.instance;
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final course = sync.courseById(courseId);
        final meeting = sync.meetingFor(courseId, meetingNumber);
        final dateText = meeting != null
            ? 'Pertemuan $meetingNumber • ${meeting.date.split(' • ').first}'
            : 'Pertemuan $meetingNumber • Sen, 28 Sep 2026';
        final title = (meeting != null && meeting.materiTitle.isNotEmpty)
            ? meeting.materiTitle
            : course.materiTitle;
        final desc = (meeting != null && meeting.description.isNotEmpty)
            ? meeting.description
            : course.modulDesc;
        final fileName = (meeting != null && meeting.materiFile.isNotEmpty)
            ? meeting.materiFile
            : (course.materiFile.isNotEmpty
                ? course.materiFile
                : 'Modul_${meetingNumber}_Praktikum.pdf');

        return LabSubPage(
          onLogoTap: nav.home,
          children: [
            LabCard(
              children: [
                PrakSpaceRow(
                  left: const LabTag.blue('Modul'),
                  right: LabMeta(icon: 'calendar', text: dateText),
                ),
                LabOverline(
                  overline: 'Praktikum ${course.name}',
                  title: title,
                ),
                Text(
                  desc,
                  style: labText(12, c: ItlgColors.textMuted),
                ),
                const LabStatRow(
                  gap: 13,
                  stats: [
                    LabStat(icon: 'eye', label: 'Dilihat', value: '21 / 24'),
                    LabStat(
                        icon: 'download', label: 'Diunduh', value: '18 kali'),
                  ],
                ),
              ],
            ),
            LabCard(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child:
                      LabSectionTitle(icon: 'book_open', text: 'Berkas Modul'),
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
                      Text(fileName,
                          textAlign: TextAlign.center,
                          style: labText(12, w: kBold)),
                      const SizedBox(height: 8),
                      Text('Berkas Modul Pertemuan $meetingNumber • Siap diunduh',
                          textAlign: TextAlign.center,
                          style: labText(11,
                              w: kMedium, c: ItlgColors.textSubtle)),
                    ],
                  ),
                ),
                LabButtonPair(
                  left: LabOutlineButton(
                    icon: 'eye',
                    label: 'Lihat Modul',
                    onTap: () => labShowFilePreview(
                      context,
                      name: fileName,
                      size: '3,2 MB',
                      source: 'Modul Pertemuan $meetingNumber • ${course.name}',
                    ),
                  ),
                  right: LabPrimaryButton(
                    icon: 'download',
                    label: 'Unduh Modul',
                    onTap: () => labToast(context, '$fileName diunduh'),
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
                  onAction: () =>
                      labToast(context, 'starter_project.zip diunduh'),
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
                  onTap: () => nav.editModul(context,
                      courseId: courseId, meetingNumber: meetingNumber),
                ),
                LabOutlineButton(
                  icon: 'delete_filled',
                  label: 'Hapus Modul',
                  large: true,
                  onTap: () async {
                    await sync.deleteMeetingContentFromAslab(
                      courseId: courseId,
                      meetingNumber: meetingNumber,
                      kind: 0,
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).maybePop();
                    labToast(context, 'Modul $meetingNumber dihapus dari BE');
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
