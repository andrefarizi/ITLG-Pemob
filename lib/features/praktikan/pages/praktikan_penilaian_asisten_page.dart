import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Penilaian Asisten-Praktikan" ([open] = true) dan
/// "Penilaian Asisten-Praktikan (Belum Dibuka)" ([open] = false).
class PraktikanPenilaianAsistenPage extends StatefulWidget {
  final PraktikanNav nav;
  final PrakCourse course;
  final bool open;

  const PraktikanPenilaianAsistenPage({
    super.key,
    required this.nav,
    required this.course,
    required this.open,
  });

  @override
  State<PraktikanPenilaianAsistenPage> createState() =>
      _PraktikanPenilaianAsistenPageState();
}

class _PraktikanPenilaianAsistenPageState
    extends State<PraktikanPenilaianAsistenPage> {
  final PraktikumSyncService _sync = PraktikumSyncService.instance;
  late final TextEditingController _saran;
  late final List<int> _ratings;
  bool _submitting = false;

  static const List<String> _criteria = [
    'Penguasaan Materi',
    'Kejelasan Penjelasan',
    'Ketepatan Waktu',
    'Kesigapan Membantu',
  ];

  @override
  void initState() {
    super.initState();
    final existing = _sync.ratingFor(
      widget.course.id,
      AuthController.instance.userIdentifier,
    );
    _ratings = List<int>.from(
      existing?.ratings ?? _sync.ratingsForCourse(widget.course.id),
    );
    _saran = TextEditingController(text: existing?.comment ?? '');
    _sync.refreshFromBackend();
  }

  @override
  void dispose() {
    _saran.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final rec = await _sync.submitAsistenRating(
      courseId: widget.course.id,
      asistenName: widget.course.asisten,
      userIdentifier: AuthController.instance.userIdentifier,
      ratings: _ratings,
      comment: _saran.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).maybePop();
    labToast(
      context,
      'Penilaian untuk ${widget.course.asisten} (${rec.averageLabel}/5 ★) tersimpan ke BE',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sync,
      builder: (context, _) {
        final c = widget.course.id.isNotEmpty
            ? _sync.courseById(widget.course.id)
            : widget.course;
        final open = widget.open;
        final existing = _sync.ratingFor(
          c.id,
          AuthController.instance.userIdentifier,
        );
        final avgLabel = _sync.averageRatingLabelForCourse(c.id);
        final count = _sync.ratingCountForCourse(c.id);
        final doneCount = c.meetings.where((m) => m.number <= 4).length;

        final person = LabPerson(
          initials: c.asistenInitials,
          name: c.asisten,
          caption: 'Asisten Lab • ${c.name} (${c.kelas})',
        );

        return LabSubPage(
          onLogoTap: widget.nav.home,
          children: [
            if (!open)
              PrakNotice.warn(
                icon: 'triangle_alert',
                text: 'Penilaian baru bisa diisi ketika masa praktikum sudah '
                    'selesai. Saat ini baru pertemuan $doneCount dari 12.',
              ),
            LabCard(
              children: [
                const LabOverline(
                  overline: 'Evaluasi Kinerja Asisten',
                  title: 'Beri Penilaian\nAsisten',
                ),
                person,
                if (open)
                  LabMeta(
                    icon: 'lock_on',
                    text: count > 0
                        ? 'Penilaian bersifat anonim • Rata-rata $avgLabel ★ ($count ulasan)'
                        : 'Penilaian bersifat anonim',
                  )
                else
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.nav.penilaianAsisten(context, c,
                        open: true, replace: true),
                    child: LabProgress(
                      label: 'Masa praktikum',
                      value: '$doneCount / 12 pertemuan',
                      fraction: (doneCount / 12).clamp(0.0, 1.0),
                      color: ItlgColors.primary,
                    ),
                  ),
              ],
            ),
            LabCard(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: LabSectionTitle(icon: 'star', text: 'Penilaian'),
                ),
                for (var i = 0; i < _criteria.length; i++)
                  PrakRatingRow(
                    label: _criteria[i],
                    value: open ? _ratings[i] : 0,
                    onChanged:
                        open ? (v) => setState(() => _ratings[i] = v) : null,
                  ),
              ],
            ),
            LabCard(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: LabSectionTitle(
                      icon: 'chat_bubble', text: 'Saran untuk Asisten'),
                ),
                PrakField(
                  label: 'Komentar (Opsional) :',
                  child: PrakTextArea(
                    controller: _saran,
                    height: 96,
                    enabled: open,
                    hint: open
                        ? 'Tulis saran atau apresiasi anda...'
                        : 'Dapat diisi setelah masa praktikum selesai',
                  ),
                ),
              ],
            ),
            if (open)
              LabPrimaryButton(
                icon: 'send',
                label: existing != null
                    ? 'Perbarui Penilaian'
                    : 'Kirim Penilaian',
                large: true,
                onTap: _kirim,
              )
            else
              const PrakDisabledButton('Kirim Penilaian'),
          ],
        );
      },
    );
  }
}
