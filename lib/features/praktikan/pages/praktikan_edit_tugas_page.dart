import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Edit Tugas-Praktikan".
class PraktikanEditTugasPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanEditTugasPage({super.key, required this.nav});

  @override
  State<PraktikanEditTugasPage> createState() => _PraktikanEditTugasPageState();
}

class _PraktikanEditTugasPageState extends State<PraktikanEditTugasPage> {
  final TextEditingController _nama =
      TextEditingController(text: 'MidFidelity Tugas');
  final TextEditingController _repo =
      TextEditingController(text: 'https://github.com/nama/prototype-figma');
  final TextEditingController _catatan = TextEditingController(
      text: 'Revisi warna tombol pada halaman beranda sesuai masukan '
          'asisten.');

  List<PrakFile> get _files => widget.nav.store.tugasFiles;

  @override
  void dispose() {
    _nama.dispose();
    _repo.dispose();
    _catatan.dispose();
    super.dispose();
  }

  void _addFile() {
    final name = _nama.text.trim().isEmpty ? 'Berkas Tugas' : _nama.text.trim();
    setState(() => _files.add(PrakFile(name, 'Diunggah baru saja')));
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
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabChip.live('Sudah Dikumpulkan'),
            ),
            const LabOverline(
              overline: 'Praktikum Desain Interaksi',
              title: 'Tugas 4 : Pembuatan\nPrototype Figma',
            ),
            LabColumn(
              gap: 6,
              children: [
                const LabMeta(
                  icon: 'clock',
                  text: 'Deadline Pengumpulan',
                  color: ItlgColors.primary,
                ),
                Text('Senin 10:30 WIB, 29 September 2026',
                    style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
              ],
            ),
          ],
        ),
        const PrakNotice.warn(
          icon: 'clock',
          text: 'Pengumpulan masih dapat diubah sampai deadline. Sisa waktu '
              '1 hari 14 jam.',
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(
                  icon: 'outline_assignment', text: 'Ubah Berkas Tugas'),
            ),
            PrakField(
              label: 'Nama Berkas',
              child: PrakInput(controller: _nama),
            ),
            PrakField(
              label: 'Berkas',
              child: PrakUploadBox(
                title: 'Tarik atau Pilih Berkas Pengganti',
                subtitle: 'Format didukung PNG, JPG, PDF, PPTX',
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
                        name: f.name,
                        meta: f.meta,
                        action: 'delete_filled',
                        onAction: () => setState(() => _files.remove(f)),
                      ),
                  ],
                ),
              ),
            PrakField(
              label: 'Tautan Repositori (Opsional)',
              child: PrakInput(
                controller: _repo,
                leadingIcon: 'link_chain',
                textColor: ItlgColors.textMuted,
              ),
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(
                  icon: 'note', text: 'Catatan Untuk Asisten Lab'),
            ),
            PrakField(
              label: 'Catatan :',
              child: PrakTextArea(controller: _catatan),
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
              icon: 'cross',
              label: 'Batalkan Pengumpulan',
              large: true,
              onTap: () => _close('Pengumpulan tugas dibatalkan'),
            ),
          ],
        ),
      ],
    );
  }
}
