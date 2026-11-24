import 'package:flutter/material.dart';

import '../../../core/services/jadwal_sync_service.dart';
import '../../../core/services/lab_desk_sync_service.dart';
import '../../../core/services/notification_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/services/shift_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../praktikan/praktikan_store.dart';
import '../../shared/profil_data.dart';
import '../laboran_shell.dart';
import '../widgets/laboran_ui.dart';

/// Halaman Beranda Laboran.
class LaboranBerandaPage extends StatelessWidget {
  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenPresensi;
  final VoidCallback onOpenNotifikasi;
  final VoidCallback? onOpenDenahMeja;

  /// Buka Denah Meja untuk lab tertentu.
  final ValueChanged<String>? onOpenDenahLab;

  const LaboranBerandaPage({
    super.key,
    required this.onOpenTab,
    required this.onOpenPresensi,
    required this.onOpenNotifikasi,
    this.onOpenDenahMeja,
    this.onOpenDenahLab,
  });

  @override
  Widget build(BuildContext context) {
    return LabTabBody(
      children: [
        _Greeting(onBell: onOpenNotifikasi),
        const _MonitoringCard(),
        LabColumn(
          gap: 12,
          children: [
            Row(
              children: const [
                LabHeading(icon: 'desktop_device', text: 'Status Laboratorium'),
                Spacer(),
                LabPill(icon: 'arrow_cycle', text: 'Real-time'),
              ],
            ),
            ListenableBuilder(
              listenable: Listenable.merge([
                PresensiSyncService.instance,
                PraktikumSyncService.instance,
                LabDeskSyncService.instance,
              ]),
              builder: (_, __) {
                final presensi = PresensiSyncService.instance;
                final praktikum = PraktikumSyncService.instance;
                final deskSync = LabDeskSyncService.instance;
                final session = presensi.activeSession;
                final jadwal = JadwalSyncService.instance;
                String wib(DateTime t) {
                  final w = t.toUtc().add(const Duration(hours: 7));
                  return '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
                }

                // Jadwal rutin berikutnya di lab ini
                String nextSchedule(String lab) {
                  const hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                  final now = DateTime.now().toUtc().add(const Duration(hours: 7));
                  final today = now.weekday - 1;
                  final nowHm =
                      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                  final inLab = jadwal.schedules
                      .where((x) =>
                          x.room.trim().toLowerCase() == lab.toLowerCase())
                      .toList();
                  if (inLab.isEmpty) return 'Tidak ada jadwal rutin di lab ini';
                  int rank(dynamic x) {
                    var d = (x.dayIndex as int) - today;
                    if (d < 0 || (d == 0 && (x.startTime as String).compareTo(nowHm) <= 0)) {
                      d += 7;
                    }
                    return d * 10000 +
                        int.parse((x.startTime as String).replaceAll(':', ''));
                  }
                  inLab.sort((x, y) => rank(x).compareTo(rank(y)));
                  final n = inLab.first;
                  return 'Berikutnya ${hari[n.dayIndex.clamp(0, 6)]} ${n.startTime} • ${n.courseName}';
                }

                final labs = <String>[
                  'Lab Jaringan 1',
                  'Lab Jaringan 2',
                  'Lab Jaringan 3',
                  'Lab Jaringan 4',
                ];
                if (session.isActive && !labs.contains(session.labName)) {
                  labs.insert(0, session.labName);
                }
                final recs = presensi.recordsForMeeting(
                    session.courseId, session.meetingNumber);
                final hadir =
                    recs.where((r) => r.status == PrakAttend.hadir).length;
                return LabColumn(
                  gap: 12,
                  children: [
                    for (final lab in labs)
                      if (session.isActive && session.labName == lab)
                        _LabCard(
                          name: lab,
                          course:
                              'Praktikum ${praktikum.courseById(session.courseId).name}',
                          initials: _initials(session.startedBy),
                          assistant: session.startedBy,
                          verifiedAt: wib(session.startedAt),
                          attendance: '$hadir hadir',
                          fraction:
                              recs.isEmpty ? 0 : (hadir / recs.length).clamp(0.0, 1.0),
                          active: true,
                          onTap: onOpenDenahLab != null
                              ? () => onOpenDenahLab!(lab)
                              : (onOpenDenahMeja ?? onOpenPresensi),
                        )
                      else
                        () {
                          final broken = deskSync
                              .inventoryDesks(lab)
                              .where((d) => !d.isReady)
                              .length;
                          return _SimpleLabCard(
                            name: lab,
                            subtitle: broken > 0
                                ? '$broken PC perlu perawatan • tidak ada sesi aktif'
                                : 'Siap digunakan • tidak ada sesi aktif',
                            chip: broken > 0
                                ? const LabChip.warn('Perawatan')
                                : const LabChip.info('Siap'),
                            meta: nextSchedule(lab),
                            onTap: onOpenDenahLab != null
                                ? () => onOpenDenahLab!(lab)
                                : (onOpenDenahMeja ?? onOpenPresensi),
                          );
                        }(),
                  ],
                );
              },
            ),
          ],
        ),
        LabColumn(
          gap: 12,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabHeading(icon: 'grid', text: 'Menu Laboran'),
            ),
            _MenuRow(
              children: [
                Expanded(
                  child: ListenableBuilder(
                    listenable: ShiftSyncService.instance,
                    builder: (_, __) {
                      final shift = ShiftSyncService.instance;
                      return _MenuCard(
                        icon: 'key',
                        title: 'Presensi Asisten',
                        subtitle:
                            shift.todayShifts.isEmpty
                                ? 'Tidak ada shift hari ini'
                                : '${shift.todayAttendedCount} dari ${shift.todayShifts.length} sudah hadir',
                        onTap: onOpenPresensi,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ListenableBuilder(
                    listenable: LabDeskSyncService.instance,
                    builder: (_, __) {
                      final count =
                          LabDeskSyncService.instance.ticketCountByStatus(0);
                      return _MenuCard(
                        icon: 'wrench_outline',
                        badge: count > 0 ? '$count' : null,
                        title: 'Laporan Kerusakan',
                        subtitle: '$count laporan baru',
                        onTap: () => onOpenTab(LaboranShell.tabTiket),
                      );
                    },
                  ),
                ),
              ],
            ),
            _MenuRow(
              children: [
                Expanded(
                  child: ListenableBuilder(
                    listenable: JadwalSyncService.instance,
                    builder: (_, __) {
                      final waiting =
                          JadwalSyncService.instance.pendingRoomRequestCount;
                      return _MenuCard(
                        icon: 'calendar',
                        badge: waiting > 0 ? '$waiting' : null,
                        title: 'Approval Ruangan',
                        subtitle: waiting > 0
                            ? '$waiting menunggu persetujuan'
                            : 'Semua ruangan diproses',
                        onTap: () => onOpenTab(LaboranShell.tabRuangan),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ListenableBuilder(
                    listenable: LabDeskSyncService.instance,
                    builder: (_, __) {
                      final inv = LabDeskSyncService.instance;
                      return _MenuCard(
                        icon: 'chip',
                        title: 'Data Inventaris',
                        subtitle:
                            '${inv.totalLabCount} lab • ${inv.totalDeviceCount} PC',
                        onTap: () => onOpenTab(LaboranShell.tabInventaris),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  final VoidCallback onBell;
  const _Greeting({required this.onBell});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 89,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ItlgShadows.outline,
      ),
      child: Row(
        children: [
          ListenableBuilder(
            listenable: ProfilData.laboran,
            builder: (_, __) => LabInitialAvatar(
              initials: ProfilData.laboran.initials,
              size: 64,
              hasPhotoBadge: ProfilData.laboran.photoSource != null,
              photoSource: ProfilData.laboran.photoSource,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat Datang', style: labText(14, c: Colors.black)),
                const SizedBox(height: 2),
                ListenableBuilder(
                  listenable: ProfilData.laboran,
                  builder: (_, __) => Text(
                      ProfilData.laboran.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labText(16, w: kBold, c: Colors.black)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const LabIcon('shield_check_outline',
                        size: 12, color: ItlgColors.textSubtle),
                    const SizedBox(width: 4),
                    Text('Laboran • Ganjil 2026',
                        style: labText(12, c: ItlgColors.textSubtle)),
                  ],
                ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: NotificationSyncService.instance,
            builder: (_, __) => LabBellButton(
              unreadCount: NotificationSyncService.instance
                  .unreadCountForRole('laboran'),
              onTap: onBell,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitoringCard extends StatelessWidget {
  const _MonitoringCard();

  @override
  Widget build(BuildContext context) {
    final presensi = PresensiSyncService.instance;
    final shift = ShiftSyncService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([presensi, shift]),
      builder: (_, __) {
        final session = presensi.activeSession;
        final recs =
            presensi.recordsForMeeting(session.courseId, session.meetingNumber);
        final hadir = recs.where((r) => r.status == PrakAttend.hadir).length;
        final pct = recs.isEmpty ? 0 : ((hadir * 100) / recs.length).round();
        // Jam WIB (UTC+7), tidak bergantung zona waktu perangkat.
        final now = DateTime.now().toUtc().add(const Duration(hours: 7));
        final clock =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';
        return LabCard(
          children: [
            Row(
              children: [
                session.isActive
                    ? const LabChip.live('Live Monitoring')
                    : const LabChip.idle('Monitoring Standby'),
                const Spacer(),
                LabPill(icon: 'clock', text: clock),
              ],
            ),
            Text('Pantauan Laboratorium',
                style: labText(22, w: kBold, c: Colors.black)),
            LabStatRow(
              stats: [
                LabStat(
                  icon: 'desktop_device',
                  label: 'Terpakai',
                  value: session.isActive ? '1 / 4 Lab' : '0 / 4 Lab',
                ),
                LabStat(
                  icon: 'shield_check_outline',
                  label: 'On-Duty',
                  value: '${shift.attendedShiftCount} Aslab',
                ),
                LabStat(
                  icon: 'people_group',
                  label: 'Hadir',
                  value: session.isActive ? '$pct%' : '-',
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Baris kepala kartu lab: ikon kotak + nama + mata kuliah + chip status.
class _LabHeader extends StatelessWidget {
  final String name;
  final String course;
  final Widget chip;

  const _LabHeader({
    required this.name,
    required this.course,
    required this.chip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const LabIconTile('desktop_device'),
        const SizedBox(width: 10),
        Expanded(
          child: LabColumn(
            gap: 2,
            children: [
              Text(name, style: labText(16, w: kBold, c: Colors.black)),
              Text(course,
                  style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
            ],
          ),
        ),
        chip,
      ],
    );
  }
}

class _LabCard extends StatelessWidget {
  final String name;
  final String course;
  final String initials;
  final String assistant;
  final String verifiedAt;
  final String attendance;
  final double fraction;
  final bool active;
  final VoidCallback onTap;

  const _LabCard({
    required this.name,
    required this.course,
    required this.initials,
    required this.assistant,
    required this.verifiedAt,
    required this.attendance,
    required this.fraction,
    this.active = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LabCard(
      onTap: onTap,
      children: [
        _LabHeader(
          name: name,
          course: course,
          chip: active
              ? const LabChip.live('Digunakan')
              : const LabChip.idle('Sesi Selesai'),
        ),
        LabInsetBox(
          child: Row(
            children: [
              LabAvatar(initials),
              const SizedBox(width: 10),
              Expanded(
                child: LabColumn(
                  gap: 2,
                  children: [
                    Text(assistant, style: labText(14, w: kBold)),
                    LabMeta(
                      icon: 'shield_check_outline',
                      text: 'Identitas terverifikasi • $verifiedAt',
                      color: ItlgColors.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const LabTag.blue('On-Duty'),
            ],
          ),
        ),
        LabProgress(
          label: 'Kehadiran Mahasiswa',
          value: attendance,
          fraction: fraction,
          color: LabColors.green,
        ),
      ],
    );
  }
}

class _SimpleLabCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final Widget chip;
  final String meta;
  final VoidCallback onTap;

  const _SimpleLabCard({
    required this.name,
    required this.subtitle,
    required this.chip,
    required this.meta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LabCard(
      onTap: onTap,
      children: [
        _LabHeader(name: name, course: subtitle, chip: chip),
        LabMeta(icon: 'clock', text: meta),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String icon;
  final String? badge;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 140),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ItlgColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: ItlgShadows.outline,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                LabIconTile(icon),
                const Spacer(),
                if (badge != null) LabTag.red(badge!),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: labText(16, w: kBold, c: Colors.black)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
          ],
        ),
      ),
    );
  }
}

/// Dua kartu menu sejajar dengan tinggi yang sama.
class _MenuRow extends StatelessWidget {
  final List<Widget> children;
  const _MenuRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'AS';
}
