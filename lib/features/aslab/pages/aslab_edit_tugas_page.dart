import 'package:flutter/material.dart';

import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import 'aslab_edit_modul_page.dart';

/// Figma: "Edit Tugas-Aslab".
class AslabEditTugasPage extends StatefulWidget {
  final AslabNav nav;
  const AslabEditTugasPage({super.key, required this.nav});

  @override
  State<AslabEditTugasPage> createState() => _AslabEditTugasPageState();
}

class _AslabEditTugasPageState extends State<AslabEditTugasPage> {
  static const List<String> _deadline = [
    'Sel, 29 Sep 2026 • 10:30 WIB',
    'Sel, 29 Sep 2026 • 23:59 WIB',
    'Rab, 30 Sep 2026 • 10:30 WIB',
  ];

  final TextEditingController _nama =
      TextEditingController(text: 'Tugas 4 : Aplikasi Counter');
  final TextEditingController _desk = TextEditingController(
      text: 'Buat aplikasi counter dengan Provider, sertakan laporan PDF dan '
          'tautan repositori.');
  int _dl = 0;
  final List<(String, String)> _files = [
    ('Tugas_4_Aplikasi_Counter.pdf', 'PDF • 640 KB'),
  ];

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

  void _close(String message) {
    Navigator.of(context).maybePop();
    labToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        const AslabEditHeader(title: 'Edit Tugas 4'),
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
              onTap: () => _close('Perubahan tugas disimpan'),
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
