import 'package:flutter/material.dart';

import '../../../core/services/file_upload_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Edit Tugas-Praktikan".
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

    _files = existing != null && existing.files.isNotEmpty
        ? List<PrakFile>.from(existing.files)
        : List<PrakFile>.from(widget.nav.store.tugasFiles);
    _nama = TextEditingController(
      text: _files.isNotEmpty ? _files.first.name : 'Laporan Tugas $_meetingNumber',
    );
    _repo = TextEditingController(
      text: existing != null && existing.repoUrl.isNotEmpty
          ? existing.repoUrl
          : 'https://github.com/andrefarizi/praktikum-${_course.id}',
    );
    _catatan = TextEditingController(
      text: existing != null && existing.note.isNotEmpty
          ? existing.note
          : 'Tugas pertemuan $_meetingNumber sudah diuji dan siap dinilai asisten.',
    );
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
    setState(() {
      _files.add(PrakFile(picked.name, picked.metaLabel));
      if (_nama.text.trim().isEmpty) {
        _nama.text = picked.name;
      }
    });
    labToast(
      context,
      picked.uploadedToCloud
          ? '${picked.name} berhasil diunggah ke BE'
          : '${picked.name} dipilih dari perangkat',
    );
  }

  Future<void> _simpan() async {
    if (_saving) return;
    setState(() => _saving = true);
    final auth = AuthController.instance;
    await _sync.saveTugasSubmission(
      courseId: _course.id,
      meetingNumber: _meetingNumber,
      userIdentifier: auth.userIdentifier,
      userName: auth.userName,
      files: _files,
      repoUrl: _repo.text.trim(),
      note: _catatan.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).maybePop();
    labToast(context, 'Perubahan tugas disimpan');
  }

  Future<void> _batalkan() async {
    if (_saving) return;
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
            LabOverline(
              overline: 'Praktikum ${c.name}',
              title: tugasTitle,
            ),
            LabColumn(
              gap: 6,
              children: [
                const LabMeta(
                  icon: 'clock',
                  text: 'Deadline Pengumpulan',
                  color: ItlgColors.primary,
                ),
                Text(deadline,
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
              onTap: _simpan,
            ),
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
