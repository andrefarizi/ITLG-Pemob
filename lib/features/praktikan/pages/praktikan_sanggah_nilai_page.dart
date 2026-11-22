import 'package:flutter/material.dart';

import '../../../core/services/file_upload_service.dart';
import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Sanggah Nilai-Praktikan".
class PraktikanSanggahNilaiPage extends StatefulWidget {
  final PraktikanNav nav;
  final PrakCourse course;
  final PrakGrade grade;

  const PraktikanSanggahNilaiPage({
    super.key,
    required this.nav,
    required this.course,
    required this.grade,
  });

  @override
  State<PraktikanSanggahNilaiPage> createState() =>
      _PraktikanSanggahNilaiPageState();
}

class _PraktikanSanggahNilaiPageState extends State<PraktikanSanggahNilaiPage> {
  final TextEditingController _alasan = TextEditingController();

  /// Komponen terpilih (terisi otomatis dari sanggahan BE jika sudah pernah diajukan).
  final Set<int> _checked = {1};
  String? _buktiName;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    NilaiSyncService.instance.refreshFromBackend();
    final existing = NilaiSyncService.instance.appealFor(
      widget.course.id,
      widget.grade.modul,
      AuthController.instance.userIdentifier,
    );
    if (existing != null) {
      _alasan.text = existing.reason;
      _buktiName = existing.attachmentName;
      if (existing.components.isNotEmpty) {
        _checked.clear();
        for (var i = 0; i < widget.grade.components.length; i++) {
          if (existing.components.contains(widget.grade.components[i].$1)) {
            _checked.add(i);
          }
        }
        if (_checked.isEmpty && widget.grade.components.isNotEmpty) {
          _checked.add(0);
        }
      }
    }
  }

  @override
  void dispose() {
    _alasan.dispose();
    super.dispose();
  }

  Future<void> _pickBukti() async {
    final picked = await FileUploadService.instance.pickAndUpload(
      folder: 'sanggah/${widget.course.id}/m${widget.grade.modul}',
    );
    if (picked == null || !mounted) return;
    setState(() => _buktiName = picked.name);
    labToast(
      context,
      picked.uploadedToCloud
          ? '${picked.name} berhasil diunggah ke BE'
          : '${picked.name} dipilih dari perangkat',
    );
  }

  Future<void> _kirim() async {
    if (_sending) return;
    if (NilaiSyncService.instance.isCourseValidated(widget.course.id)) {
      labToast(
        context,
        'Nilai sudah divalidasi dosen dan tidak dapat disanggah lagi',
      );
      return;
    }
    if (_checked.isEmpty) {
      labToast(context, 'Pilih minimal satu komponen yang disanggah');
      return;
    }
    setState(() => _sending = true);
    final auth = AuthController.instance;
    final selectedComps = [
      for (final i in _checked)
        if (i < widget.grade.components.length) widget.grade.components[i].$1,
    ];
    await NilaiSyncService.instance.submitGradeAppeal(
      courseId: widget.course.id,
      modul: widget.grade.modul,
      userIdentifier: auth.userIdentifier,
      userName: auth.userName,
      components: selectedComps.isEmpty ? ['Nilai Modul'] : selectedComps,
      reason: _alasan.text.trim().isEmpty
          ? 'Mohon peninjauan ulang nilai komponen terpilih.'
          : _alasan.text.trim(),
      attachmentName: _buktiName,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    Navigator.of(context).maybePop();
    labToast(context, 'Sanggahan terkirim ke asisten & dosen');
  }

  @override
  Widget build(BuildContext context) {
    final nilaiSync = NilaiSyncService.instance;
    final praktikumSync = PraktikumSyncService.instance;
    final userId = AuthController.instance.userIdentifier;
    return ListenableBuilder(
      listenable: Listenable.merge([nilaiSync, praktikumSync]),
      builder: (context, _) {
        final course = praktikumSync.courseById(widget.course.id);
        final liveGrades =
            praktikumSync.effectiveGradesForCourse(course, userId);
        final g = liveGrades.firstWhere(
          (x) => x.modul == widget.grade.modul,
          orElse: () => widget.grade,
        );
        final validated = nilaiSync.isCourseValidated(course.id);
        final existing = nilaiSync.appealFor(course.id, g.modul, userId);

        return LabSubPage(
          onLogoTap: widget.nav.home,
          children: [
            LabCard(
              children: [
                LabOverline(
                  overline: 'Praktikum ${course.name}',
                  title: 'Sanggah Nilai\nModul ${g.modul}',
                ),
                LabStatRow(
                  gap: 13,
                  stats: [
                    LabStat(
                        icon: 'trophy',
                        label: 'Nilai Saat Ini',
                        value: '${g.score ?? '–'} / 100'),
                    LabStat(
                        icon: 'clock',
                        label: 'Status Sanggah',
                        value: validated
                            ? 'Terkunci'
                            : (existing == null
                                ? 'Terbuka'
                                : (existing.status == 'resolved'
                                    ? 'Selesai'
                                    : 'Diajukan'))),
                  ],
                ),
              ],
            ),
            LabCard(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: LabSectionTitle(
                      icon: 'clipboard', text: 'Komponen yang Disanggah'),
                ),
                LabColumn(
                  gap: 8,
                  children: [
                    for (var i = 0; i < g.components.length; i++)
                      PrakCheckOption(
                        title: g.components[i].$1,
                        subtitle:
                            'Nilai ${g.components[i].$2} / ${g.components[i].$3}',
                        checked: _checked.contains(i),
                        onTap: () => setState(() => _checked.contains(i)
                            ? _checked.remove(i)
                            : _checked.add(i)),
                      ),
                  ],
                ),
              ],
            ),
            LabCard(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: LabSectionTitle(
                      icon: 'chat_bubble', text: 'Alasan Sanggahan'),
                ),
                PrakField(
                  label: 'Penjelasan :',
                  child: PrakTextArea(
                    controller: _alasan,
                    hint: 'Jelaskan bagian yang menurut anda perlu ditinjau '
                        'ulang...',
                  ),
                ),
                LabOutlineButton(
                  icon: _buktiName != null ? 'check' : 'attach',
                  label: _buktiName != null
                      ? '$_buktiName terlampir'
                      : 'Lampirkan Bukti',
                  onTap: _pickBukti,
                ),
              ],
            ),
            PrakNotice.info(
              icon: 'info',
              text: validated
                  ? 'Nilai akhir kelas ini sudah divalidasi dosen sehingga '
                      'sanggahan tidak lagi dapat diubah.'
                  : (existing != null
                      ? (existing.status == 'resolved'
                          ? 'Sanggahan anda sudah ditinjau dan nilai telah '
                              'diperbarui oleh asisten.'
                          : 'Sanggahan anda sedang diperiksa asisten. Anda '
                              'masih dapat memperbarui keterangan atau bukti.')
                      : 'Sanggahan hanya dapat diajukan sebelum nilai '
                          'divalidasi dosen dan disinkronkan ke portal akademik.'),
            ),
            LabPrimaryButton(
              icon: 'send',
              label: existing != null && existing.status == 'pending'
                  ? 'Perbarui Sanggahan'
                  : 'Kirim Sanggahan',
              large: true,
              onTap: _kirim,
            ),
          ],
        );
      },
    );
  }
}
