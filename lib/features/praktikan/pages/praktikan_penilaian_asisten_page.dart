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
  final TextEditingController _saran = TextEditingController();

  static const List<String> _criteria = [
    'Penguasaan Materi',
    'Kejelasan Penjelasan',
    'Ketepatan Waktu',
    'Kesigapan Membantu',
  ];

  late final List<int> _ratings = List<int>.from(
    PraktikumSyncService.instance.ratingsForCourse(widget.course.id),
  );

  @override
  void dispose() {
    _saran.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    await PraktikumSyncService.instance.submitAsistenRating(
      courseId: widget.course.id,
      asistenName: widget.course.asisten,
      userIdentifier: AuthController.instance.userIdentifier,
      ratings: _ratings,
      comment: _saran.text.trim(),
    );
    if (!mounted) return;
    Navigator.of(context).maybePop();
    labToast(context, 'Penilaian asisten terkirim');
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final open = widget.open;
    final person = LabPerson(
      initials: c.asistenInitials,
      name: c.asisten,
      caption: 'Asisten Lab • ${c.name} Kelas C',
    );

    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        if (!open)
          const PrakNotice.warn(
            icon: 'triangle_alert',
            text: 'Penilaian baru bisa diisi ketika masa praktikum sudah '
                'selesai. Saat ini baru pertemuan 4 dari 12.',
          ),
        LabCard(
          children: [
            const LabOverline(
              overline: 'Evaluasi Kinerja Asisten',
              title: 'Beri Penilaian\nAsisten',
            ),
            person,
            if (open)
              const LabMeta(
                  icon: 'lock_on', text: 'Penilaian bersifat anonim')
            else
              // Prototipe: ketuk progress untuk melihat versi yang sudah
              // dibuka (masa praktikum selesai).
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.nav.penilaianAsisten(context, c,
                    open: true, replace: true),
                child: const LabProgress(
                  label: 'Masa praktikum',
                  value: '4 / 12 pertemuan',
                  fraction: 113 / 338,
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
            label: 'Kirim Penilaian',
            large: true,
            onTap: _kirim,
          )
        else
          const PrakDisabledButton('Kirim Penilaian'),
      ],
    );
  }
}
