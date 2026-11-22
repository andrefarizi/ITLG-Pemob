import 'package:flutter/material.dart';

import '../../../core/services/device_calendar_service.dart';
import '../../../core/services/jadwal_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../shared/profil_data.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSyncDeviceCalendar();
    });
  }

  Future<void> _autoSyncDeviceCalendar() async {
    final res = await DeviceCalendarService.instance
        .ensurePermissionAndSyncOnce(JadwalSyncService.instance.schedules);
    if (!mounted) return;
    if (res.synced && res.count > 0) {
      labToast(
        context,
        '${res.count} jadwal praktikum tersinkron ke ${res.calendarName}',
      );
    }
  }

  Future<void> _manualSyncDeviceCalendar() async {
    final res = await DeviceCalendarService.instance.syncSchedules(
      JadwalSyncService.instance.schedules,
      askPermission: true,
    );
    if (!mounted) return;
    if (!res.permissionGranted) {
      labToast(
        context,
        'Izinkan akses Kalender di pengaturan perangkat untuk sinkron jadwal',
      );
    } else if (res.synced && res.count > 0) {
      labToast(
        context,
        '${res.count} jadwal praktikum diperbarui di ${res.calendarName}',
      );
    } else {
      labToast(context, 'Tidak dapat menulis ke kalender perangkat');
    }
  }

  void _refresh(void _) {
    if (mounted) setState(() {});
  }

  void _openPengumuman() {
    _store.announcementUnread = false;
    _nav.pengumuman(context).then(_refresh);
  }

  @override
  Widget build(BuildContext context) {
    final jadwalSync = JadwalSyncService.instance;
    final praktikumSync = PraktikumSyncService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([jadwalSync, praktikumSync]),
      builder: (context, _) {
        final daySchedules = jadwalSync.schedulesForDay(_day);
        return PrakTabBody(
          left: 13,
          children: [
            _greeting(),
            _presensiCard(),
            _pengumuman(),
            _jadwalHeader(),
            if (daySchedules.isNotEmpty)
              _TodayCard(
                items: [
                  for (final s in daySchedules)
                    _TodayItem(
                      start: s.startTime,
                      end: s.endTime,
                      roomOverride: s.room,
                      asistenOverride: s.asisten,
                      course: praktikumSync.courseById(s.courseId),
                      onTap: () => _nav.detailPraktikum(
                        context,
                        praktikumSync.courseById(s.courseId),
                      ),
                    ),
                ],
              )
            else
              _emptyDay(),
          ],
        );
      },
    );
  }

  // Kartu sapaan (373 x 92).
  Widget _greeting() {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
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
                ListenableBuilder(
                  listenable: ProfilData.praktikan,
                  builder: (_, __) => Text(
                      ProfilData.praktikan.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labText(16, w: kBold, c: Colors.black)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const LabIcon('m_school',
                        size: 12.8, color: ItlgColors.textSubtle),
                    const SizedBox(width: 4),
                    Flexible(
                      child: ListenableBuilder(
                        listenable: ProfilData.praktikan,
                        builder: (_, __) => Text(
                          '${ProfilData.praktikan.idLabel} ${ProfilData.praktikan.idValue} • Ganjil 2026',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: labText(12, c: ItlgColors.textSubtle),
                        ),
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
              // Lonceng datar (tanpa bayangan) sesuai Figma.
              decoration: const BoxDecoration(
                color: ItlgColors.primary,
                shape: BoxShape.circle,
              ),
              child: const LabIcon('m_bell', size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Kartu presensi berlangsung (373 x 258).
  Widget _presensiCard() {
    final presensiSync = PresensiSyncService.instance;
    final praktikumSync = PraktikumSyncService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([presensiSync, praktikumSync]),
      builder: (context, _) {
        final session = presensiSync.activeSession;
        final course = praktikumSync.courseById(session.courseId);
        final userId = AuthController.instance.userIdentifier;
        final myRec = presensiSync.recordFor(
            session.courseId, session.meetingNumber, userId);
        final alreadyPresent =
            myRec != null && myRec.status == PrakAttend.hadir;

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
              Align(
                alignment: Alignment.centerLeft,
                child: alreadyPresent
                    ? const PrakLiveChip24('Sudah Presensi')
                    : (session.isActive
                        ? const PrakLiveChip24('Presensi Berlangsung')
                        : const LabChip.idle('Sesi Ditutup')),
              ),
              Text('Praktikum \n${course.name}',
                  style: labText(22, w: kBold, c: Colors.black)),
              PrakScheduleMeta(
                jadwal: course.jadwalAbsensi,
                room: session.labName,
                asisten: session.startedBy,
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (alreadyPresent) {
                    _nav.pilihMejaFromPresensi();
                  } else if (!session.isActive) {
                    labToast(
                        context, 'Sesi presensi sedang ditutup oleh asisten');
                  } else {
                    _nav.presensi(context);
                  }
                },
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
                      Text(
                          alreadyPresent
                              ? 'Lihat / Pilih Meja'
                              : (session.isActive
                                  ? 'Presensi Sekarang'
                                  : 'Sesi Ditutup'),
                          style: labText(16,
                              w: kBold, c: ItlgColors.surfaceWhite)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pengumuman() {
    final anns = JadwalSyncService.instance.announcements;
    final latest = anns.isNotEmpty ? anns.first : null;
    final title = latest?.title ?? _store.announcements.first.title;
    final subtitle = latest?.body ??
        'Praktikum Machine Learning Kelas C pindah ke Kam, 01 Okt • 13:00';
    final timeText = latest?.relativeTime ?? _store.announcements.first.time;
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
                      Text(title, style: labText(12, w: kBold)),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: labText(11,
                            w: kMedium, c: ItlgColors.textSubtle),
                      ),
                      Text(timeText,
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
          right: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _manualSyncDeviceCalendar,
            child: Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: ItlgColors.surfaceDark,
                borderRadius: BorderRadius.circular(11),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: LayoutBuilder(
            builder: (context, box) {
              final w = ((box.maxWidth - 5 * 6) / _days.length)
                  .clamp(40.0, 52.0)
                  .toDouble();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < _days.length; i++)
                    _DayButton(
                      day: _days[i],
                      width: w,
                      selected: i == _day,
                      onTap: () => setState(() => _day = i),
                    ),
                ],
              );
            },
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
  final double width;
  final bool selected;
  final VoidCallback onTap;

  const _DayButton({
    required this.day,
    required this.width,
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
        width: width,
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

class _TodayItem {
  final String start;
  final String end;
  final String? roomOverride;
  final String? asistenOverride;
  final PrakCourse course;
  final VoidCallback onTap;
  const _TodayItem({
    required this.start,
    required this.end,
    this.roomOverride,
    this.asistenOverride,
    required this.course,
    required this.onTap,
  });
}

/// Figma: "Kartu Jadwal Hari Ini" — satu kartu abu-abu (padding 4/16) berisi
/// baris jadwal dengan garis pemisah. Ketuk baris → Detail Praktikum.
class _TodayCard extends StatelessWidget {
  final List<_TodayItem> items;
  const _TodayCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ItlgShadows.outline,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i < items.length - 1
                    ? const Border(bottom: BorderSide(color: LabColors.line))
                    : null,
              ),
              child: _TodayRow(item: items[i]),
            ),
        ],
      ),
    );
  }
}

class _TodayRow extends StatelessWidget {
  final _TodayItem item;
  const _TodayRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: LabColumn(
                gap: 2,
                children: [
                  Text(item.start,
                      style: labText(14, w: kBold, c: ItlgColors.primary)),
                  Text(item.end, style: labText(12, c: LabColors.textGrey)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(width: 1, height: 36, color: LabColors.line),
            const SizedBox(width: 14),
            Expanded(
              child: LabColumn(
                gap: 4,
                children: [
                  Text(item.course.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labText(14, w: kBold)),
                  Text(
                      '${item.roomOverride ?? item.course.room} • ${item.asistenOverride ?? item.course.asisten}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labText(12, c: LabColors.textGrey)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const LabIcon('chevron_right', size: 16, color: LabColors.divider),
          ],
        ),
      ),
    );
  }
}
