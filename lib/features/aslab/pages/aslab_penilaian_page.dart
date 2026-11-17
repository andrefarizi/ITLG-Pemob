import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';

/// Figma: "Penilaian-Aslab".
class AslabPenilaianPage extends StatefulWidget {
  final AslabNav nav;
  const AslabPenilaianPage({super.key, required this.nav});

  @override
  State<AslabPenilaianPage> createState() => _AslabPenilaianPageState();
}

class _AslabPenilaianPageState extends State<AslabPenilaianPage> {
  /// 0 Perlu Dinilai, 1 Selesai.
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final nav = widget.nav;
    return LabTabBody(
      children: [
        const LabTitle(
          title: 'Penilaian',
          subtitle: 'Tugas praktikan yang perlu anda evaluasi',
        ),
        const LabStatRow(
          stats: [
            LabStat(icon: 'clipboard', label: 'Tugas Aktif', value: '3'),
            LabStat(icon: 'clock', label: 'Menunggu', value: '24'),
            LabStat(icon: 'circle_check', label: 'Dinilai', value: '40'),
          ],
        ),
        LabTabs(
          labels: const ['Perlu Dinilai (2)', 'Selesai'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        if (_tab == 0) ...[
          _TaskCard(
            tag: 'Tugas 4',
            title: 'Perancangan ERD & Query SQL',
            course: 'Praktikum Basis Data • Kelas C',
            done: '14 / 20',
            fraction: 237 / 338,
            onTap: () => nav.evaluasiTugas(context),
          ),
          _TaskCard(
            tag: 'Tugas 4',
            title: 'Aplikasi Counter',
            course: 'Praktikum Pemrograman Mobile • Kelas C',
            done: '2 / 20',
            fraction: 34 / 338,
            onTap: () => nav.evaluasiTugas(context),
          ),
        ] else
          _TaskCard(
            tag: 'Tugas 3',
            title: 'Halaman Login',
            course: 'Praktikum Pemrograman Mobile • Kelas C',
            done: '24 / 24',
            fraction: 1,
            finished: true,
            onTap: () => nav.evaluasiTugas(context),
          ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String tag;
  final String title;
  final String course;
  final String done;
  final double fraction;
  final bool finished;
  final VoidCallback onTap;

  const _TaskCard({
    required this.tag,
    required this.title,
    required this.course,
    required this.done,
    required this.fraction,
    required this.onTap,
    this.finished = false,
  });

  @override
  Widget build(BuildContext context) {
    return LabCard(
      children: [
        PrakSpaceRow(
          left: Align(
            alignment: Alignment.centerLeft,
            child: LabTag.red(tag),
          ),
          right: finished
              ? const LabChip.live('Selesai Dinilai')
              : const LabMeta(icon: 'clock', text: 'Deadline 29 Sep, 10:30'),
        ),
        Text(title, style: labText(16, w: kBold, c: Colors.black)),
        LabMeta(icon: 'book_open', text: course),
        LabProgress(
          label: 'Sudah dinilai',
          value: done,
          fraction: fraction,
          color: finished ? LabColors.green : ItlgColors.primary,
        ),
        finished
            ? LabOutlineButton(
                icon: 'clipboard', label: 'Lihat Evaluasi', onTap: onTap)
            : LabPrimaryButton(
                icon: 'clipboard', label: 'Evaluasi Tugas', onTap: onTap),
      ],
    );
  }
}
