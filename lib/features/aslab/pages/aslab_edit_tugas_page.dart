import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import 'aslab_edit_modul_page.dart';

/// Figma: "Edit Tugas-Aslab".
class AslabEditTugasPage extends StatefulWidget {
  final AslabNav nav;
  final String courseId;
  const AslabEditTugasPage({
    super.key,
    required this.nav,
    this.courseId = 'pemob',
  });

  @override
  State<AslabEditTugasPage> createState() => _AslabEditTugasPageState();
}

class _AslabEditTugasPageState extends State<AslabEditTugasPage> {
  static const List<String> _deadline = [
    'Sel, 29 Sep 2026 • 10:30 WIB',
    'Sel, 29 Sep 2026 • 23:59 WIB',
    'Rab, 30 Sep 2026 • 10:30 WIB',
  ];

  late final TextEditingController _nama;
  late final TextEditingController _desk;
  int _dl = 0;
  final List<(String, String)> _files = [
    ('Tugas_4_Praktikum.pdf', 'PDF • 640 KB'),
  ];

  @override
  void initState() {
    super.initState();
    final c = PraktikumSyncService.instance.courseById(widget.courseId);
    _nama = TextEditingController(text: c.tugasTitle);
    _desk = TextEditingController(text: c.modulDesc);
  }

  @override
  void dispose() {
    _nama.dispose();
    _desk.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final i = await prakShowPicker(context,
        title: 'Deadline Pengumpulan', options: _deadline, selected: _dl);
    if (i != null && mounted) setState(() => _dl = i);
  }

  void _addFile() {
    setState(() => _files.add(
        ('Berkas_Pengganti_${_files.length + 1}.pdf', 'Diunggah baru saja')));
  }

  Future<void> _save() async {
    final c = PraktikumSyncService.instance.courseById(widget.courseId);
    await PraktikumSyncService.instance.upsertMeetingContentFromAslab(
      courseId: c.id,
      meetingNumber: 4,
      dateLabel: 'Sen, 28 Sep 2026 • ${c.jam}',
      kind: 1,
      title: _nama.text.trim().isEmpty ? c.tugasTitle : _nama.text.trim(),
      description: _desk.text.trim(),
      fileName: _files.isNotEmpty ? _files.first.$1 : null,
      deadline: _deadline[_dl],
    );
    if (!mounted) return;
    _close('Perubahan tugas disimpan');
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
        AslabEditHeader(title: 'Edit Tugas 4', courseName: c.name),
        const PrakNotice.warn(
          icon: 'info',
          text: '20 praktikan sudah mengumpulkan. Perubahan deadline atau '
              'berkas akan dikirim sebagai notif',
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(icon: 'clipboard', text: 'Ubah Tugas'),
            ),
            PrakField(label: 'Nama Tugas', child: PrakInput(controller: _nama)),
            PrakField(
              label: 'Deskripsi Tugas :',
              child: PrakTextArea(controller: _desk, height: 96),
            ),
            PrakField(
              label: 'Deadline Pengumpulan',
              child: PrakSelect(value: _deadline[_dl], onTap: _pickDeadline),
            ),
            PrakField(
              label: 'Berkas Tugas',
              child: PrakUploadBox(
                title: 'Tarik atau Pilih Berkas Pengganti',
                subtitle: 'Format didukung PDF, DOCX, ZIP',
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
              label: 'Hapus Tugas',
              large: true,
              onTap: () => _close('Tugas 4 dihapus'),
            ),
          ],
        ),
      ],
    );
  }
}
