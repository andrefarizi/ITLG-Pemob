import 'package:flutter/material.dart';

import '../../../core/services/file_upload_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';

/// Halaman Edit Modul Asisten Lab.
class AslabEditModulPage extends StatefulWidget {
  final AslabNav nav;
  final String courseId;
  final int meetingNumber;
  const AslabEditModulPage({
    super.key,
    required this.nav,
    this.courseId = 'pemob',
    this.meetingNumber = 4,
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
    final sync = PraktikumSyncService.instance;
    final c = sync.courseById(widget.courseId);
    final m = sync.meetingFor(widget.courseId, widget.meetingNumber);
    _nama = TextEditingController(
      text: (m != null && m.materiTitle.isNotEmpty)
          ? m.materiTitle
          : c.materiTitle,
    );
    _desk = TextEditingController(
      text: (m != null && m.description.isNotEmpty)
          ? m.description
          : c.modulDesc,
    );
    final primaryFile = (m != null && m.materiFile.isNotEmpty)
        ? m.materiFile
        : c.materiFile;
    _files = [
      if (primaryFile.isNotEmpty) (primaryFile, 'Berkas modul saat ini'),
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
    if (!picked.uploadedToCloud) {
      labToast(context,
          'Gagal mengunggah ${picked.name}. Periksa koneksi lalu coba lagi.');
      return;
    }
    setState(() => _files.insert(0, (picked.name, picked.metaLabel)));
    labToast(context, '${picked.name} berhasil diunggah');
  }

  bool _busy = false;

  Future<void> _save() async {
    if (_busy) return;
    final title = _nama.text.trim();
    if (title.length < 5) {
      labToast(context, 'Isi nama modul (minimal 5 karakter)');
      return;
    }
    if (_files.isEmpty) {
      labToast(context, 'Unggah berkas modul terlebih dahulu');
      return;
    }
    final sync = PraktikumSyncService.instance;
    final c = sync.courseById(widget.courseId);
    final m = sync.meetingFor(widget.courseId, widget.meetingNumber);
    setState(() => _busy = true);
    try {
      await sync.upsertMeetingContentFromAslab(
        courseId: c.id,
        meetingNumber: widget.meetingNumber,
        dateLabel: m?.date ?? 'Pertemuan ${widget.meetingNumber}',
        kind: 0,
        title: title,
        description: _desk.text.trim(),
        fileName: _files.first.$1,
      );
    } on StateError catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        labToast(context, e.message);
      }
      return;
    }
    if (!mounted) return;
    _close('Perubahan modul Pertemuan ${widget.meetingNumber} disimpan');
  }

  Future<void> _delete() async {
    if (_busy) return;
    final ok = await labShowConfirmDialog(
      context,
      icon: 'delete_filled',
      title: 'Hapus Modul ${widget.meetingNumber}?',
      message: 'Modul dan berkasnya tidak lagi tampil untuk praktikan.',
      confirmLabel: 'Hapus',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await PraktikumSyncService.instance.deleteMeetingContentFromAslab(
        courseId: widget.courseId,
        meetingNumber: widget.meetingNumber,
        kind: 0,
      );
    } on StateError catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        labToast(context, e.message);
      }
      return;
    }
    if (!mounted) return;
    _close('Modul ${widget.meetingNumber} dihapus');
  }

  void _close(String message) {
    Navigator.of(context).maybePop();
    labToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final sync = PraktikumSyncService.instance;
    final c = sync.courseById(widget.courseId);
    final m = sync.meetingFor(widget.courseId, widget.meetingNumber);
    final dateText = m != null
        ? 'Pertemuan ${widget.meetingNumber} • ${m.date.split(' • ').first}'
        : 'Pertemuan ${widget.meetingNumber} • Sen, 28 September 2026';

    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        AslabEditHeader(
          title: 'Edit Modul ${widget.meetingNumber}',
          courseName: c.name,
          dateLabel: dateText,
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
              onTap: _delete,
            ),
          ],
        ),
      ],
    );
  }
}

/// Kartu judul halaman edit: chip "Sudah Diterbitkan", nama praktikum
class AslabEditHeader extends StatelessWidget {
  final String title;
  final String courseName;
  final String dateLabel;
  const AslabEditHeader({
    super.key,
    required this.title,
    this.courseName = 'Pemrograman Mobile',
    this.dateLabel = 'Pertemuan 4 • Sen, 28 September 2026',
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
          overline: 'Praktikum $courseName • Kom C (C1 & C2)',
          title: title,
        ),
        LabMeta(
          icon: 'calendar',
          text: dateLabel,
        ),
      ],
    );
  }
}
