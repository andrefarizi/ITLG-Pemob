import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';
import '../widgets/aslab_ui.dart';

/// Figma: "Detail Praktikum Saya-Aslab".
class AslabDetailPraktikumPage extends StatefulWidget {
  final AslabNav nav;
  final AslabCourse course;

  const AslabDetailPraktikumPage({
    super.key,
    required this.nav,
    required this.course,
  });

  @override
  State<AslabDetailPraktikumPage> createState() =>
      _AslabDetailPraktikumPageState();
}

class _AslabDetailPraktikumPageState extends State<AslabDetailPraktikumPage> {
  /// 0 Semua, 1 Modul, 2 Tugas, 3 Kuis.
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final nav = widget.nav;
    final sync = PraktikumSyncService.instance;
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final c = sync.aslabCourses.firstWhere(
          (x) => x.id == widget.course.id,
          orElse: () => widget.course,
        );
        return LabSubPage(
          onLogoTap: nav.home,
          children: [
            LabCard(
              children: [
                AslabClassTitle(kelas: c.kelas, name: c.name),
                LabStatRow(
                  gap: 13,
                  stats: [
                    const LabStat(
                        icon: 'people_group',
                        label: 'Praktikan',
                        value: '24 Orang'),
                    LabStat(icon: 'clock', label: 'Waktu', value: c.jadwal),
                  ],
                ),
                const LabProgress(
                  label: 'Pertemuan',
                  value: '4 / 12',
                  fraction: 113 / 338,
                  color: ItlgColors.primary,
                ),
              ],
            ),
            LabPrimaryButton(
              icon: 'plus',
              label: 'Tambah Materi Baru',
              large: true,
              onTap: () => nav.tambahMateri(context, courseId: c.id),
            ),
            LabTabs(
              labels: const ['Semua', 'Modul', 'Tugas', 'Kuis'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            for (final m in c.meetings)
              if (_tab == 0 || m.items.any((it) => it.kind == _tab - 1))
                _MeetingCard(
                  meeting: m,
                  tab: _tab,
                  nav: nav,
                  courseId: c.id,
                ),
          ],
        );
      },
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final AslabMeeting meeting;
  final int tab;
  final AslabNav nav;
  final String courseId;

  const _MeetingCard({
    required this.meeting,
    required this.tab,
    required this.nav,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    final items = meeting.items
        .where((it) => tab == 0 || it.kind == tab - 1)
        .toList();
    return LabCard(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => nav.detailPertemuan(context, meeting),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabMeta(icon: 'calendar', text: meeting.date),
              const SizedBox(height: 6),
              Row(
                children: [
                  PrakNumberTile('${meeting.number}'),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(meeting.title,
                        style: labText(16, w: kBold, c: Colors.black)),
                  ),
                  const LabIcon('arrow_right',
                      size: 16, color: LabColors.filterIcon),
                ],
              ),
            ],
          ),
        ),
        for (final it in items)
          _ItemBox(item: it, nav: nav, courseId: courseId),
      ],
    );
  }
}

/// Kotak Modul / Tugas / Kuis dengan dua tombol aksi.
class _ItemBox extends StatelessWidget {
  final AslabItem item;
  final AslabNav nav;
  final String courseId;
  const _ItemBox({
    required this.item,
    required this.nav,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, tag) = switch (item.kind) {
      0 => ('book_open', const LabTag.blue('Modul')),
      1 => ('clipboard', const LabTag.red('Tugas')),
      _ => ('question', const LabTag.grey('Kuis')),
    };
    final Widget left;
    final Widget right;
    switch (item.kind) {
      case 0:
        left = LabOutlineButton(
            icon: 'pencil',
            label: 'Edit Modul',
            onTap: () => nav.editModul(context, courseId: courseId));
        right = LabPrimaryButton(
            icon: 'eye',
            label: 'Detail Modul',
            onTap: () => nav.detailModul(context));
        break;
      case 1:
        left = LabOutlineButton(
            icon: 'pencil',
            label: 'Edit Tugas',
            onTap: () => nav.editTugas(context, courseId: courseId));
        right = LabPrimaryButton(
            icon: 'clipboard',
            label: 'Evaluasi Tugas',
            onTap: () => nav.evaluasiTugas(context, courseId: courseId));
        break;
      default:
        left = LabOutlineButton(
            icon: 'pencil',
            label: 'Edit Kuis',
            onTap: () =>
                nav.tambahMateri(context, kind: 2, courseId: courseId));
        right = LabPrimaryButton(
            icon: 'eye',
            label: 'Lihat Hasil',
            onTap: () => nav.hasilKuis(context, courseId: courseId));
    }
    return LabInsetBox(
      child: LabColumn(
        gap: 10,
        children: [
          Row(
            children: [
              LabIconTile(icon),
              const SizedBox(width: 8),
              Expanded(
                child: LabColumn(
                  gap: 4,
                  cross: CrossAxisAlignment.start,
                  children: [
                    tag,
                    Text(item.title, style: labText(12, w: kBold)),
                    Text(item.meta,
                        style: labText(11,
                            w: kMedium, c: ItlgColors.textSubtle)),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(flex: 154, child: left),
              const SizedBox(width: 10),
              Expanded(flex: 146, child: right),
            ],
          ),
        ],
      ),
    );
  }
}
