import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Page Beranda-Praktikan (Navbar)".
class PraktikanBerandaPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanBerandaPage({super.key, required this.nav});

  @override
  State<PraktikanBerandaPage> createState() => _PraktikanBerandaPageState();
}

class _PraktikanBerandaPageState extends State<PraktikanBerandaPage> {
  static const List<(String, String, String)> _days = [
    ('Sen', '28', 'Sep'),
    ('Sel', '29', 'Sep'),
    ('Rab', '30', 'Sep'),
    ('Kam', '01', 'Okt'),
    ('Jum', '02', 'Okt'),
    ('Sab', '03', 'Okt'),
  ];

  int _day = 0;

  PraktikanNav get _nav => widget.nav;
  PraktikanStore get _store => widget.nav.store;

  void _refresh(void _) {
    if (mounted) setState(() {});
  }

  void _openPengumuman() {
    _store.announcementUnread = false;
    _nav.pengumuman(context).then(_refresh);
  }

  @override
  Widget build(BuildContext context) {
    return PrakTabBody(
      left: 13,
      children: [
        _greeting(),
        _presensiCard(),
        _pengumuman(),
        _jadwalHeader(),
        if (_day == 0) ...[
          _ScheduleCard(
            course: _store.mobile,
            module: 'Flutter State Management...',
            onTap: () => _nav.detailPraktikum(context, _store.mobile),
            onMateri: () => _nav.detailMateri(context),
          ),
          _ScheduleCard(
            course: _store.desain,
            module: 'Figma Management...',
            onTap: () => _nav.detailPraktikum(context, _store.desain),
            onMateri: () => _nav.detailMateri(context),
          ),
        ] else
          _emptyDay(),
      ],
    );
  }

  // Kartu sapaan (373 x 92).
  Widget _greeting() {
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(16, 12, 26, 15),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ItlgShadows.outline,
      ),
      child: Row(
        children: [
          Image.asset('assets/avatar_laboran.png', width: 64, height: 65),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat Datang',
                    style: labText(14, c: Colors.black)),
                const SizedBox(height: 2),
                Text('Nama Praktikan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labText(16, w: kBold, c: Colors.black)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const LabIcon('m_school',
                        size: 12.8, color: ItlgColors.textSubtle),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'NIM 231402033 • Ganjil 2026',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labText(12, c: ItlgColors.textSubtle),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _nav.notifikasi(context).then(_refresh),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: ItlgColors.primary,
                shape: BoxShape.circle,
                boxShadow: ItlgShadows.outline,
              ),
              child: const LabIcon('m_bell', size: 16.7, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Kartu presensi berlangsung (373 x 258).
  Widget _presensiCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 24),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ItlgShadows.outline,
      ),
      child: LabColumn(
        gap: 16,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: PrakLiveChip24('Presensi Berlangsung'),
          ),
          Text('Praktikum \nPemrograman Mobile',
              style: labText(22, w: kBold, c: Colors.black)),
          const PrakScheduleMeta(
            jadwal: 'Senin • 08:00–09:40 WIB',
            room: 'Lab Komputer 1',
            asisten: 'Andi Pratama',
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _nav.presensi(context),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: ItlgColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: ItlgShadows.outline,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LabIcon('m_qr', size: 22, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('Presensi Sekarang',
                      style:
                          labText(16, w: kBold, c: ItlgColors.surfaceWhite)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pengumuman() {
    final a = _store.announcements.first;
    return LabColumn(
      gap: 12,
      children: [
        PrakSpaceRow(
          left: const LabHeading(
              icon: 'bullhorn_outline', text: 'Pengumuman Terbaru'),
          right: PrakSideLink('Lihat Semua', onTap: _openPengumuman),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openPengumuman,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: ItlgShadows.outline,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LabIconTile('bullhorn_outline'),
                const SizedBox(width: 10),
                Expanded(
                  child: LabColumn(
                    gap: 4,
                    children: [
                      Text(a.title, style: labText(12, w: kBold)),
                      Text(
                        'Praktikum Basis Data Kelas B pindah ke '
                        'Kam, 01 Okt • 13:00',
                        style: labText(11,
                            w: kMedium, c: ItlgColors.textSubtle),
                      ),
                      Text(a.time,
                          style: labText(11,
                              w: kMedium,
                              c: _store.announcementUnread
                                  ? ItlgColors.primary
                                  : ItlgColors.textSubtle)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _store.announcementUnread ? 1 : 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: ItlgColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _jadwalHeader() {
    return LabColumn(
      gap: 8,
      children: [
        PrakSpaceRow(
          left: const LabHeading(
              icon: 'calendar_date_range_20_solid', text: 'Jadwal Praktikum'),
          right: Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: ItlgColors.surfaceDark,
              borderRadius: BorderRadius.circular(11),
              boxShadow: PrakShadows.neu5,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LabIcon('m_calendar_small',
                    size: 11.7, color: ItlgColors.textSubtle),
                const SizedBox(width: 4),
                Text('Minggu ke-4',
                    style: labText(12, c: ItlgColors.textSubtle)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < _days.length; i++)
                _DayButton(
                  day: _days[i],
                  selected: i == _day,
                  onTap: () => setState(() => _day = i),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyDay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ItlgShadows.outline,
      ),
      child: Text(
        'Tidak ada jadwal praktikum pada hari ini.',
        textAlign: TextAlign.center,
        style: labText(12, c: ItlgColors.textSubtle),
      ),
    );
  }
}

/// Tombol hari 52 x 64 (radius 12).
class _DayButton extends StatelessWidget {
  final (String, String, String) day;
  final bool selected;
  final VoidCallback onTap;

  const _DayButton({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fgTop = selected ? Colors.white : ItlgColors.textSubtle;
    final fgMid = selected ? Colors.white : PrakColors.ink;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 52,
        height: 64,
        decoration: BoxDecoration(
          color: selected ? ItlgColors.primary : LabColors.tile,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? PrakShadows.daySelected : PrakShadows.neu5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(day.$1,
                style: labText(12, w: selected ? kSemiBold : kMedium, c: fgTop)),
            Text(day.$2, style: labText(18, w: kBold, c: fgMid)),
            Text(day.$3, style: labText(11, w: kMedium, c: fgTop)),
          ],
        ),
      ),
    );
  }
}

/// Kartu jadwal praktikum (373 x 208).
class _ScheduleCard extends StatelessWidget {
  final PrakCourse course;
  final String module;
  final VoidCallback onTap;
  final VoidCallback onMateri;

  const _ScheduleCard({
    required this.course,
    required this.module,
    required this.onTap,
    required this.onMateri,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 22, bottom: 15),
        decoration: BoxDecoration(
          color: ItlgColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: ItlgShadows.outline,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const PrakBookTile(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Praktikum \n${course.name}',
                        style: labText(16, w: kBold, c: Colors.black)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 19),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PrakScheduleMeta(
                jadwal: 'Senin • 08:00–09:40 WIB',
                room: course.room,
                asisten: course.asisten,
              ),
            ),
            const SizedBox(height: 17),
            Padding(
              padding: const EdgeInsets.only(left: 18, right: 21),
              child: InnerShadowBox(
                radius: 12,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 12.5, 20, 12.5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Modul 4\n',
                              style: labText(12,
                                  w: kBold, c: ItlgColors.textMuted),
                            ),
                            TextSpan(
                              text: module,
                              style: labText(12,
                                      w: kBold, c: PrakColors.faded)
                                  .copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onMateri,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('Lihat Materi',
                            style: labText(12, c: ItlgColors.primary)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
