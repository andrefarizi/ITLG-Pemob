import 'package:flutter/material.dart';

import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';

/// Figma: "Edit Modul-Aslab".
class AslabEditModulPage extends StatefulWidget {
  final AslabNav nav;
  const AslabEditModulPage({super.key, required this.nav});

  @override
  State<AslabEditModulPage> createState() => _AslabEditModulPageState();
}

class _AslabEditModulPageState extends State<AslabEditModulPage> {
  final TextEditingController _nama =
      TextEditingController(text: 'Modul 4 : Flutter State Management');
  final TextEditingController _desk = TextEditingController(
      text: 'Pengenalan setState, InheritedWidget, dan Provider untuk '
          'mengelola state aplikasi Flutter.');
  final List<(String, String)> _files = [
    ('Modul_4_State_Management.pdf', 'PDF • 3,2 MB'),
    ('starter_project.zip', 'ZIP • 4,1 MB'),
  ];

  @override
  void dispose() {
    _nama.dispose();
    _desk.dispose();
    super.dispose();
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
        const AslabEditHeader(title: 'Edit Modul 4'),
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
              onTap: () => _close('Perubahan modul disimpan'),
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
  const AslabEditHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return LabCard(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: LabChip.live('Sudah Diterbitkan'),
        ),
        LabOverline(
          overline: 'Praktikum Pemrograman Mobile • Kelas C',
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
