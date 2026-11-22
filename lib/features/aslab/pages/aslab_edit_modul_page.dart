import 'package:flutter/material.dart';

import '../../../core/services/file_upload_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';

/// Figma: "Edit Modul-Aslab".
class AslabEditModulPage extends StatefulWidget {
  final AslabNav nav;
  final String courseId;
  const AslabEditModulPage({
    super.key,
    required this.nav,
    this.courseId = 'pemob',
  });

  @override
  State<AslabEditModulPage> createState() => _AslabEditModulPageState();
}

class _AslabEditModulPageState extends State<AslabEditModulPage> {
  late final TextEditingController _nama;
  late final TextEditingController _desk;
  late final List<(String, String)> _files;

  @override
  void initState() {
    super.initState();
    final c = PraktikumSyncService.instance.courseById(widget.courseId);
    _nama = TextEditingController(text: c.materiTitle);
    _desk = TextEditingController(text: c.modulDesc);
    _files = [
      (c.materiFile, 'PDF • 3,2 MB'),
      ('starter_project.zip', 'ZIP • 4,1 MB'),
    ];
  }

  @override
  void dispose() {
    _nama.dispose();
    _desk.dispose();
    super.dispose();
  }

  Future<void> _addFile() async {
    final picked = await FileUploadService.instance.pickAndUpload(
      folder: 'materi/${widget.courseId}/modul',
    );
    if (picked == null || !mounted) return;
    setState(() => _files.add((picked.name, picked.metaLabel)));
    labToast(
      context,
      picked.uploadedToCloud
          ? '${picked.name} berhasil diunggah ke BE'
          : '${picked.name} dipilih dari perangkat',
    );
  }

  Future<void> _save() async {
    final c = PraktikumSyncService.instance.courseById(widget.courseId);
    await PraktikumSyncService.instance.upsertMeetingContentFromAslab(
      courseId: c.id,
      meetingNumber: 4,
      dateLabel: 'Sen, 28 Sep 2026 • ${c.jam}',
      kind: 0,
      title: _nama.text.trim().isEmpty ? c.materiTitle : _nama.text.trim(),
      description: _desk.text.trim(),
      fileName: _files.isNotEmpty ? _files.first.$1 : c.materiFile,
    );
    if (!mounted) return;
    _close('Perubahan modul disimpan');
  }

  void _close(String message) {
    Navigator.of(context).maybePop();
    labToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final c = PraktikumSyncService.instance.courseById(widget.courseId);
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        AslabEditHeader(
          title: 'Edit Modul 4',
          courseName: c.name,
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(icon: 'book_open', text: 'Ubah Modul'),
            ),
            PrakField(label: 'Nama Modul', child: PrakInput(controller: _nama)),
            PrakField(
              label: 'Deskripsi Modul :',
              child: PrakTextArea(controller: _desk, height: 96),
            ),
            PrakField(
              label: 'Berkas Modul',
              child: PrakUploadBox(
                title: 'Tarik atau Pilih Berkas Pengganti',
                subtitle: 'Format didukung PDF, PPTX, DOCX',
                onTap: _addFile,
              ),
            ),
            LabOutlineButton(
              icon: 'add_outline',
              label: 'Unggah Berkas',
              large: true,
              onTap: _addFile,
            ),
            if (_files.isNotEmpty)
              PrakField(
                label: 'Berkas Terunggah',
                child: LabColumn(
                  gap: 8,
                  children: [
                    for (final f in _files)
                      PrakFileItem(
                        name: f.$1,
                        meta: f.$2,
                        action: 'delete_filled',
                        onAction: () => setState(() => _files.remove(f)),
                      ),
                  ],
                ),
              ),
          ],
        ),
        LabColumn(
          gap: 12,
          children: [
            LabPrimaryButton(
              icon: 'check',
              label: 'Simpan Perubahan',
              large: true,
              onTap: _save,
            ),
            LabOutlineButton(
              icon: 'delete_filled',
              label: 'Hapus Modul',
              large: true,
              onTap: () => _close('Modul 4 dihapus'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Kartu judul halaman edit: chip "Sudah Diterbitkan", nama praktikum,
/// judul, dan tanggal pertemuan.
class AslabEditHeader extends StatelessWidget {
  final String title;
  final String courseName;
  const AslabEditHeader({
    super.key,
    required this.title,
    this.courseName = 'Pemrograman Mobile',
  });

  @override
  Widget build(BuildContext context) {
    return LabCard(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: LabChip.live('Sudah Diterbitkan'),
        ),
        LabOverline(
          overline: 'Praktikum $courseName • Kelas C',
          title: title,
        ),
        const LabMeta(
          icon: 'calendar',
          text: 'Pertemuan 4 • Sen, 28 September 2026',
        ),
      ],
    );
  }
}
