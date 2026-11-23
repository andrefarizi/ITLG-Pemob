import 'package:flutter/material.dart';

import '../../../core/services/file_upload_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import 'aslab_edit_modul_page.dart';

/// Figma: "Edit Tugas-Aslab".
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
  static const List<String> _deadline = [
    'Sel, 29 Sep 2026 • 10:30 WIB',
    'Sel, 29 Sep 2026 • 23:59 WIB',
    'Rab, 30 Sep 2026 • 10:30 WIB',
    'Sen, 12 Okt 2026 • 10:30 WIB',
  ];

  late final TextEditingController _nama;
  late final TextEditingController _desk;
  final int _dl = 0;
  String? _customDeadline;
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
    _files = [
      ('Tugas_${widget.meetingNumber}_Praktikum.pdf', 'PDF • 640 KB'),
    ];
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
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final dName = days[picked.weekday - 1];
    final dd = picked.day.toString().padLeft(2, '0');
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    setState(() {
      _customDeadline =
          '$dName, $dd ${months[picked.month - 1]} ${picked.year} • $hh:$mm WIB';
    });
  }

  Future<void> _addFile() async {
    final picked = await FileUploadService.instance.pickAndUpload(
      folder: 'materi/${widget.courseId}/tugas',
    );
    if (picked == null || !mounted) return;
    setState(() => _files.insert(0, (picked.name, picked.metaLabel)));
    labToast(
      context,
      picked.uploadedToCloud
          ? '${picked.name} berhasil diunggah ke BE'
          : '${picked.name} dipilih dari perangkat',
    );
  }

  Future<void> _save() async {
    final sync = PraktikumSyncService.instance;
    final c = sync.courseById(widget.courseId);
    final m = sync.meetingFor(widget.courseId, widget.meetingNumber);
    await sync.upsertMeetingContentFromAslab(
      courseId: c.id,
      meetingNumber: widget.meetingNumber,
      dateLabel: m?.date ?? 'Sen, 28 Sep 2026 • ${c.jam}',
      kind: 1,
      title: _nama.text.trim().isEmpty ? c.tugasTitle : _nama.text.trim(),
      description: _desk.text.trim(),
      fileName: _files.isNotEmpty ? _files.first.$1 : null,
      deadline: _customDeadline ?? _deadline[_dl],
    );
    if (!mounted) return;
    _close('Perubahan tugas Pertemuan ${widget.meetingNumber} disimpan ke BE');
  }

  Future<void> _delete() async {
    await PraktikumSyncService.instance.deleteMeetingContentFromAslab(
      courseId: widget.courseId,
      meetingNumber: widget.meetingNumber,
      kind: 1,
    );
    if (!mounted) return;
    _close('Tugas ${widget.meetingNumber} dihapus dari BE');
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
    final subsCount =
        (20 + sync.submissionsForCourse(c.id, widget.meetingNumber).length)
            .clamp(0, 24);

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
          text: '$subsCount praktikan sudah mengumpulkan. Perubahan deadline atau '
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
              child: PrakSelect(
                value: _customDeadline ?? _deadline[_dl],
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
