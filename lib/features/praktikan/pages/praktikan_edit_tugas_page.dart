import 'package:flutter/material.dart';

import '../../../core/services/file_upload_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Halaman Edit Tugas Praktikan.
class PraktikanEditTugasPage extends StatefulWidget {
  final PraktikanNav nav;
  final PrakCourse? course;
  final PrakMeeting? meeting;

  const PraktikanEditTugasPage({
    super.key,
    required this.nav,
    this.course,
    this.meeting,
  });

  @override
  State<PraktikanEditTugasPage> createState() => _PraktikanEditTugasPageState();
}

class _PraktikanEditTugasPageState extends State<PraktikanEditTugasPage> {
  final PraktikumSyncService _sync = PraktikumSyncService.instance;
  late final TextEditingController _nama;
  late final TextEditingController _repo;
  late final TextEditingController _catatan;
  late final List<PrakFile> _files;
  bool _saving = false;

  PrakCourse get _course => widget.course ?? _sync.courses.first;
  int get _meetingNumber => widget.meeting?.number ?? 4;

  @override
  void initState() {
    super.initState();
    final userId = AuthController.instance.userIdentifier;
    final existing = _sync.submissionFor(_course.id, _meetingNumber, userId);
    final isSubmitted = existing != null && existing.isSubmitted;

    _files = isSubmitted ? List<PrakFile>.from(existing.files) : <PrakFile>[];
    _nama = TextEditingController(
      text: isSubmitted && _files.isNotEmpty ? _files.first.name : '',
    );
    _repo = TextEditingController(text: isSubmitted ? existing.repoUrl : '');
    _catatan = TextEditingController(text: isSubmitted ? existing.note : '');
  }

  @override
  void dispose() {
    _nama.dispose();
    _repo.dispose();
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _addFile() async {
    final picked = await FileUploadService.instance.pickAndUpload(
      folder: 'tugas/${_course.id}/m$_meetingNumber',
    );
    if (picked == null || !mounted) return;
    if (!picked.uploadedToCloud) {
      labToast(
        context,
        '${picked.name} gagal diunggah ke server. Periksa koneksi lalu coba lagi.',
      );
      return;
    }
    setState(() {
      _files.add(
        PrakFile(
          picked.name,
          picked.metaLabel,
          path: FileUploadService.instance.remotePathForName(picked.name),
        ),
      );
      if (_nama.text.trim().isEmpty) {
        _nama.text = picked.name;
      }
    });
    labToast(context, '${picked.name} berhasil diunggah');
  }

  Future<void> _simpan() async {
    if (_saving) return;
    if (_files.isEmpty && _repo.text.trim().isEmpty) {
      labToast(
        context,
        'Unggah minimal satu berkas atau isi tautan repositori',
      );
      return;
    }
    setState(() => _saving = true);
    final auth = AuthController.instance;
    try {
      await _sync.saveTugasSubmission(
        courseId: _course.id,
        meetingNumber: _meetingNumber,
        userIdentifier: auth.userIdentifier,
        userName: auth.userName,
        files: _files,
        repoUrl: _repo.text.trim(),
        note: _catatan.text.trim(),
      );
    } on StateError catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        labToast(context, e.message);
      }
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).maybePop();
    labToast(context, 'Perubahan tugas disimpan');
  }

  Future<void> _batalkan() async {
    if (_saving) return;
    final ok = await labShowConfirmDialog(
      context,
      icon: 'delete_filled',
      title: 'Batalkan Pengumpulan?',
      message: 'Semua berkas yang sudah diunggah untuk tugas ini akan dihapus. Kamu masih bisa mengumpulkan ulang sebelum deadline.',
      cancelLabel: 'Batal',
      confirmLabel: 'Ya, Hapus Pengumpulan',
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    await _sync.cancelTugasSubmission(
      courseId: _course.id,
      meetingNumber: _meetingNumber,
      userIdentifier: AuthController.instance.userIdentifier,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).maybePop();
    labToast(context, 'Pengumpulan tugas dibatalkan');
  }

  @override
  Widget build(BuildContext context) {
    final c = _course;
    final userId = AuthController.instance.userIdentifier;
    final existing = _sync.submissionFor(c.id, _meetingNumber, userId);
    final submitted = existing != null && existing.isSubmitted;
    final tugasTitle = (widget.meeting?.tugasTitle.isNotEmpty ?? false)
        ? widget.meeting!.tugasTitle
        : c.tugasTitle;
    final deadline = (widget.meeting?.tugasDeadline.isNotEmpty ?? false)
        ? widget.meeting!.tugasDeadline
        : c.tugasDeadline;

    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: submitted
                  ? const LabChip.live('Sudah Dikumpulkan')
                  : const LabChip.warn('Belum Dikumpulkan'),
            ),
            LabOverline(overline: 'Praktikum ${c.name}', title: tugasTitle),
            LabColumn(
              gap: 6,
              children: [
                const LabMeta(
                  icon: 'clock',
                  text: 'Deadline Pengumpulan',
                  color: ItlgColors.primary,
                ),
                Text(
                  deadline,
                  style: labText(11, w: kMedium, c: ItlgColors.textSubtle),
                ),
              ],
            ),
          ],
        ),
        PrakNotice.warn(
          icon: 'clock',
          text: _deadlineNotice(deadline, submitted),
        ),
        LabCard(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(
                icon: 'outline_assignment',
                text: submitted ? 'Ubah Berkas Tugas' : 'Unggah Berkas Tugas',
              ),
            ),
            PrakField(
              label: 'Nama Berkas',
              child: PrakInput(
                controller: _nama,
                hint: 'Contoh: Tugas $_meetingNumber - ${c.name}',
              ),
            ),
            PrakField(
              label: 'Berkas',
              child: PrakUploadBox(
                title: submitted
                    ? 'Tarik atau Pilih Berkas Pengganti'
                    : 'Tarik atau Pilih Berkas Tugas',
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
            PrakField(
              label: 'Berkas Terunggah',
              child: _files.isEmpty
                  ? Text(
                      'Belum ada berkas yang diunggah.',
                      style: labText(12, c: LabColors.textGrey),
                    )
                  : LabColumn(
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
                hint: 'https://github.com/... (opsional)',
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
                icon: 'note',
                text: 'Catatan Untuk Asisten Lab',
              ),
            ),
            PrakField(
              label: 'Catatan :',
              child: PrakTextArea(
                controller: _catatan,
                hint: 'Tulis catatan untuk asisten (opsional)',
              ),
            ),
          ],
        ),
        LabColumn(
          gap: 12,
          children: [
            LabPrimaryButton(
              icon: 'check',
              label: submitted
                  ? 'Simpan Perubahan'
                  : 'Kumpulkan Tugas Sekarang',
              large: true,
              onTap: _simpan,
            ),
            if (submitted)
              LabOutlineButton(
                icon: 'cross',
                label: 'Batalkan Pengumpulan',
                large: true,
                onTap: _batalkan,
              ),
          ],
        ),
      ],
    );
  }
}

/// Ubah label "Batas 10:30 WIB, 12 Okt 2026" menjadi waktu (WIB = UTC+7).
DateTime? _parseDeadline(String label) {
  const bulan = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'mei': 5,
    'jun': 6,
    'jul': 7,
    'agu': 8,
    'agt': 8,
    'sep': 9,
    'okt': 10,
    'nov': 11,
    'des': 12,
  };
  final m = RegExp(
    r'(\d{1,2})[:.](\d{2}).*?(\d{1,2})\s+([A-Za-z]{3})[A-Za-z]*\s+(\d{4})',
  ).firstMatch(label);
  if (m == null) return null;
  final month = bulan[m.group(4)!.toLowerCase()];
  if (month == null) return null;
  return DateTime.utc(
    int.parse(m.group(5)!),
    month,
    int.parse(m.group(3)!),
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
  ).subtract(const Duration(hours: 7));
}

String _deadlineNotice(String deadlineLabel, bool submitted) {
  final due = _parseDeadline(deadlineLabel);
  if (due == null) {
    return submitted
        ? 'Pengumpulan masih dapat diubah sampai deadline.'
        : 'Tugas belum dikumpulkan. Unggah berkas lalu tekan Kumpulkan sebelum deadline.';
  }
  final left = due.difference(DateTime.now().toUtc());
  if (left.isNegative) {
    return submitted
        ? 'Deadline sudah lewat. Pengumpulan ini tercatat terlambat bila diubah.'
        : 'Deadline sudah lewat. Pengumpulan sekarang tercatat terlambat.';
  }
  final days = left.inDays;
  final hours = left.inHours % 24;
  final mins = left.inMinutes % 60;
  final sisa = days > 0
      ? '$days hari $hours jam'
      : (hours > 0 ? '$hours jam $mins menit' : '$mins menit');
  return submitted
      ? 'Pengumpulan masih dapat diubah sampai deadline. Sisa waktu $sisa.'
      : 'Tugas belum dikumpulkan. Sisa waktu $sisa sebelum deadline.';
}
