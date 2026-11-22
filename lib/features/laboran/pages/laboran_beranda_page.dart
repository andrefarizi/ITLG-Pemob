import 'package:flutter/material.dart';

import '../../../core/services/lab_desk_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../praktikan/praktikan_store.dart';
import '../../shared/profil_data.dart';
import '../laboran_shell.dart';
import '../widgets/laboran_ui.dart';

/// Figma: "Page Beranda-Laboran".
class LaboranBerandaPage extends StatelessWidget {
  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenPresensi;
  final VoidCallback onOpenNotifikasi;
  final VoidCallback? onOpenDenahMeja;

  const LaboranBerandaPage({
    super.key,
    required this.onOpenTab,
    required this.onOpenPresensi,
    required this.onOpenNotifikasi,
    this.onOpenDenahMeja,
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
              ]),
              builder: (_, __) {
                final presensi = PresensiSyncService.instance;
                final praktikum = PraktikumSyncService.instance;
                final session = presensi.activeSession;
                final pemob = praktikum.courseById('pemob');
                final desain = praktikum.courseById('desain');
                final extraHadir = presensi
                    .recordsForMeeting(session.courseId, session.meetingNumber)
                    .where((r) => r.status == PrakAttend.hadir)
                    .length;
                final totalHadir = (18 + extraHadir).clamp(0, 24);
                return LabColumn(
                  gap: 12,
                  children: [
                    _LabCard(
                      name: pemob.room,
                      course: 'Praktikum ${pemob.name}',
                      initials: pemob.asistenInitials,
                      assistant: pemob.asisten,
                      verifiedAt: '07:52',
                      attendance: '$totalHadir / 24',
                      fraction: (totalHadir / 24).clamp(0.0, 1.0),
                      onTap: onOpenDenahMeja ?? onOpenPresensi,
                    ),
                    _LabCard(
                      name: desain.room,
                      course: 'Praktikum ${desain.name}',
                      initials: desain.asistenInitials,
                      assistant: desain.asisten,
                      verifiedAt: '07:58',
                      attendance: '19 / 22',
                      fraction: 292 / 338,
                      onTap: onOpenPresensi,
                    ),
                  ],
                );
              },
            ),
            const _EmptyLabCard(),
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
                  child: _MenuCard(
                    icon: 'key',
                    title: 'Presensi Asisten',
                    subtitle: '4 dari 6 sudah hadir',
                    onTap: onOpenPresensi,
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
                        title: 'Tiket Perbaikan',
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
                  child: _MenuCard(
                    icon: 'calendar',
                    badge: '2',
                    title: 'Approval Ruangan',
                    subtitle: '2 menunggu persetujuan',
                    onTap: () => onOpenTab(LaboranShell.tabRuangan),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _MenuCard(
                    icon: 'chip',
                    title: 'Data Inventaris',
                    subtitle: '5 lab • 142 PC',
                    onTap: () => onOpenTab(LaboranShell.tabInventaris),
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
          Image.asset('assets/avatar_laboran.png', width: 64, height: 65),
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBell,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: ItlgColors.primary,
                shape: BoxShape.circle,
                boxShadow: ItlgShadows.outline,
              ),
              child: Image.asset(
                'assets/icons/ic_bell_filled.png',
                width: 13.3,
                height: 16.7,
                color: Colors.white,
                filterQuality: FilterQuality.medium,
              ),
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
    return LabCard(
      children: [
        Row(
          children: const [
            LabChip.live('Live Monitoring'),
            Spacer(),
            LabPill(icon: 'clock', text: '08:24 WIB'),
          ],
        ),
        Text('Pantauan Laboratorium',
            style: labText(22, w: kBold, c: Colors.black)),
        const LabStatRow(
          stats: [
            LabStat(icon: 'desktop_device', label: 'Terpakai', value: '3 / 5 Lab'),
            LabStat(
                icon: 'shield_check_outline', label: 'On-Duty', value: '6 Aslab'),
            LabStat(icon: 'people_group', label: 'Hadir', value: '87%'),
          ],
        ),
      ],
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
  final VoidCallback onTap;

  const _LabCard({
    required this.name,
    required this.course,
    required this.initials,
    required this.assistant,
    required this.verifiedAt,
    required this.attendance,
    required this.fraction,
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
          chip: const LabChip.live('Digunakan'),
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
        ),
      ],
    );
  }
}

class _EmptyLabCard extends StatelessWidget {
  const _EmptyLabCard();

  @override
  Widget build(BuildContext context) {
    return const LabCard(
      children: [
        _LabHeader(
          name: 'Lab Multimedia',
          course: 'Tidak ada sesi berjalan',
          chip: LabChip.idle('Kosong'),
        ),
        LabMeta(
          icon: 'clock',
          text: 'Sesi berikutnya 13:00 • Praktikum Jaringan Komputer',
        ),
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
