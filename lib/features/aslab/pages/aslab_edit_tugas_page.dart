import 'package:flutter/material.dart';

import '../../../core/services/file_upload_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import 'aslab_edit_modul_page.dart';

/// Halaman Edit Tugas Asisten Lab.
class AslabEditTugasPage extends StatefulWidget {
  final AslabNav nav;
  final String courseId;
  final int meetingNumber;
  const AslabEditTugasPage({
    super.key,
    required this.nav,
    this.courseId = 'pemob',
    this.meetingNumber = 4,
  });

  @override
  State<AslabEditTugasPage> createState() => _AslabEditTugasPageState();
}

class _AslabEditTugasPageState extends State<AslabEditTugasPage> {
  late final TextEditingController _nama;
  late final TextEditingController _desk;
  /// Deadline yang sudah tersimpan; tidak ditimpa kecuali Aslab memilih baru.
  String _savedDeadline = '';
  String? _customDeadline;
  bool _busy = false;
  late final List<(String, String)> _files;

  @override
  void initState() {
    super.initState();
    final sync = PraktikumSyncService.instance;
    final c = sync.courseById(widget.courseId);
    final m = sync.meetingFor(widget.courseId, widget.meetingNumber);
    _nama = TextEditingController(
      text: (m != null && m.tugasTitle.isNotEmpty)
          ? m.tugasTitle
          : c.tugasTitle,
    );
    _desk = TextEditingController(
      text: (m != null && m.description.isNotEmpty)
          ? m.description
          : c.modulDesc,
    );
    _savedDeadline = (m != null && m.tugasDeadline.isNotEmpty)
        ? m.tugasDeadline
        : '';
    _files = [];
  }

  @override
  void dispose() {
    _nama.dispose();
    _desk.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await labShowDateTimePicker(
      context,
      title: 'Pilih Tanggal & Jam',
    );
    if (picked == null || !mounted) return;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final dd = picked.day.toString().padLeft(2, '0');
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    // Format sama dengan yang dibaca Praktikan: "Batas 10:30 WIB, 12 Okt 2026".
    setState(() {
      _customDeadline =
          'Batas $hh:$mm WIB, $dd ${months[picked.month - 1]} ${picked.year}';
    });
  }

  Future<void> _addFile() async {
    final picked = await FileUploadService.instance.pickAndUpload(
      folder: 'materi/${widget.courseId}/tugas',
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

  Future<void> _save() async {
    if (_busy) return;
    final title = _nama.text.trim();
    final deadline = _customDeadline ?? _savedDeadline;
    if (title.length < 5) {
      labToast(context, 'Isi nama tugas (minimal 5 karakter)');
      return;
    }
    if (_desk.text.trim().length < 10) {
      labToast(context, 'Tulis deskripsi/instruksi tugas (minimal 10 karakter)');
      return;
    }
    if (deadline.isEmpty) {
      labToast(context, 'Pilih deadline pengumpulan');
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
        kind: 1,
        title: title,
        description: _desk.text.trim(),
        fileName: _files.isNotEmpty ? _files.first.$1 : null,
        deadline: deadline,
      );
    } on StateError catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        labToast(context, e.message);
      }
      return;
    }
    if (!mounted) return;
    _close('Perubahan tugas Pertemuan ${widget.meetingNumber} disimpan');
  }

  Future<void> _delete() async {
    if (_busy) return;
    final ok = await labShowConfirmDialog(
      context,
      icon: 'delete_filled',
      title: 'Hapus Tugas ${widget.meetingNumber}?',
      message: 'Tugas tidak lagi tampil untuk praktikan. Pengumpulan yang '
          'sudah masuk tetap tersimpan.',
      confirmLabel: 'Hapus',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await PraktikumSyncService.instance.deleteMeetingContentFromAslab(
        courseId: widget.courseId,
        meetingNumber: widget.meetingNumber,
        kind: 1,
      );
    } on StateError catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        labToast(context, e.message);
      }
      return;
    }
    if (!mounted) return;
    _close('Tugas ${widget.meetingNumber} dihapus');
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
        : 'Pertemuan ${widget.meetingNumber}';
    final subsCount =
        sync.submissionsForCourse(c.id, widget.meetingNumber).length;

    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        AslabEditHeader(
          title: 'Edit Tugas ${widget.meetingNumber}',
          courseName: c.name,
          dateLabel: dateText,
        ),
        PrakNotice.warn(
          icon: 'info',
          text: subsCount == 0
              ? 'Belum ada pengumpulan. Perubahan tugas dikirim sebagai notifikasi ke praktikan'
              : '$subsCount praktikan sudah mengumpulkan. Perubahan deadline atau '
                  'berkas akan dikirim sebagai notifikasi',
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
              child: PrakSelect(
                value: _customDeadline ??
                    (_savedDeadline.isNotEmpty
                        ? _savedDeadline
                        : 'Pilih tanggal & jam'),
                onTap: _pickDeadline,
              ),
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
              onTap: _delete,
            ),
          ],
        ),
      ],
    );
  }
}
