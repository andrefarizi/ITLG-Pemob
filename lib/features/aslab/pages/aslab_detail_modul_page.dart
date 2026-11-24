import 'package:flutter/material.dart';

import '../../../core/services/file_download_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../../shared/lab_actions.dart';
import '../aslab_nav.dart';

/// Halaman Detail Modul Asisten Lab.
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
                      source: 'Modul Pertemuan $meetingNumber • ${course.name}',
                      searchFolders: ['materi/${course.id}/modul'],
                    ),
                  ),
                  right: LabPrimaryButton(
                    icon: 'download',
                    label: 'Unduh Modul',
                    onTap: () async {
                      final res =
                          await FileDownloadService.instance.downloadFile(
                        fileName: fileName,
                        source:
                            'Modul Pertemuan $meetingNumber • ${course.name}',
                        searchFolders: ['materi/${course.id}/modul'],
                        contentLines: [
                          'ITLG MOBILE - MODUL ASISTEN LAB',
                          'Praktikum : ${course.name} (${course.kelas})',
                          'Pertemuan : $meetingNumber',
                          'Judul     : $title',
                          'Berkas    : $fileName',
                          '------------------------------------------------------------',
                          desc,
                        ],
                      );
                      if (!context.mounted) return;
                      if (res.success) {
                        await labShowResult(
                          context,
                          icon: 'download',
                          title: 'Berkas Diunduh',
                          message:
                              'Berkas tersimpan di folder Unduhan perangkat anda.',
                        );
                      } else {
                        labToast(context, 'Gagal mengunduh $fileName');
                      }
                    },
                  ),
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
                    final ok = await labShowConfirmDialog(
                      context,
                      icon: 'delete_filled',
                      title: 'Hapus Modul $meetingNumber?',
                      message:
                          'Modul dan berkasnya tidak lagi tampil untuk praktikan.',
                      confirmLabel: 'Hapus',
                    );
                    if (!ok || !context.mounted) return;
                    try {
                      await sync.deleteMeetingContentFromAslab(
                        courseId: courseId,
                        meetingNumber: meetingNumber,
                        kind: 0,
                      );
                    } on StateError catch (e) {
                      if (context.mounted) labToast(context, e.message);
                      return;
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).maybePop();
                    labToast(context, 'Modul $meetingNumber dihapus');
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
