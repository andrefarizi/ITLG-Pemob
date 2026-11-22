import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../shared/profil_data.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../dosen_shell.dart';

/// Figma: "Page Beranda-Dosen".
class DosenBerandaPage extends StatelessWidget {
  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenNotifikasi;

  const DosenBerandaPage({
    super.key,
    required this.onOpenTab,
    required this.onOpenNotifikasi,
  });

  @override
  Widget build(BuildContext context) {
    void toValidasi() => onOpenTab(DosenShell.tabValidasi);
    void toPeringatan() => onOpenTab(DosenShell.tabPeringatan);

    return LabTabBody(
      children: [
        _Greeting(onBell: onOpenNotifikasi),
        _EqualRow(
          children: [
            _MetricCard(
              icon: 'people_group',
              label: 'Tingkat Kehadiran',
              value: '91%',
              valueColor: ItlgColors.primary,
              trend: '+2% dari minggu lalu',
              onTap: toPeringatan,
            ),
            _MetricCard(
              icon: 'trophy',
              label: 'Rata-rata Nilai',
              value: '84,2',
              valueColor: ItlgColors.secondary,
              trend: '+1,4 dari modul 3',
              onTap: toPeringatan,
            ),
          ],
        ),
        const _PerformaCard(),
        ListenableBuilder(
          listenable: PraktikumSyncService.instance,
          builder: (context, _) {
            final courses = PraktikumSyncService.instance.courses;
            return LabColumn(
              gap: 12,
              children: [
                Row(
                  children: [
                    const LabHeading(
                        icon: 'people_group', text: 'Grup Praktikum Diampu'),
                    const Spacer(),
                    Text('${courses.length} Grup',
                        style: labText(12, c: ItlgColors.primary)),
                  ],
                ),
                for (final c in courses)
                  _GroupItem(
                    title: '${c.name} • Kelas C',
                    assistant: c.asisten,
                    attendance:
                        '${((c.hadir / (c.hadir + c.izin + c.alpa == 0 ? 4 : c.hadir + c.izin + c.alpa)) * 100).round()}%',
                    score: c.nilaiRata.split(',').first,
                    onTap: toValidasi,
                  ),
              ],
            );
          },
        ),
        LabColumn(
          gap: 12,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabHeading(icon: 'grid', text: 'Menu Dosen'),
            ),
            _EqualRow(
              children: [
                _MenuCard(
                  icon: 'clipboard',
                  badge: '2',
                  title: 'Validasi Nilai Akhir',
                  subtitle: '2 kelas menunggu',
                  onTap: toValidasi,
                ),
                _MenuCard(
                  icon: 'download',
                  title: 'Generate Laporan',
                  subtitle: 'Spreadsheet atau PDF',
                  onTap: () => onOpenTab(DosenShell.tabLaporan),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Dua kartu sejajar (jarak 14) dengan tinggi yang sama.
class _EqualRow extends StatelessWidget {
  final List<Widget> children;
  const _EqualRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: children[0]),
          const SizedBox(width: 14),
          Expanded(child: children[1]),
        ],
      ),
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
          // Avatar yang sama dengan di Figma (dipakai juga oleh Laboran).
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
                  listenable: ProfilData.dosen,
                  builder: (_, __) => Text(
                      ProfilData.dosen.name,
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
                    Flexible(
                      child: Text('Dosen Pengampu • Ganjil 2026',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: labText(12, c: ItlgColors.textSubtle)),
                    ),
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

/// Kartu metrik 148 px: ikon, label, angka Bold 27, tren hijau.
class _MetricCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color valueColor;
  final String trend;
  final VoidCallback onTap;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.trend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 148),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ItlgColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: ItlgShadows.outline,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabIconTile(icon),
            const SizedBox(height: 10),
            Text(label,
                style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
            const SizedBox(height: 2),
            Text(value, style: labText(27, w: kBold, c: valueColor)),
            const SizedBox(height: 10),
            LabMeta(icon: 'statistic_up', text: trend, color: LabColors.green),
          ],
        ),
      ),
    );
  }
}

class _PerformaCard extends StatelessWidget {
  const _PerformaCard();

  // Tinggi batang di Figma (area grafik 110 px).
  static const List<String> _labels = ['Kelas A', 'Kelas B', 'Kelas C', 'Kelas D'];
  static const List<double> _kehadiran = [101, 97, 105, 98];
  static const List<double> _nilai = [95, 89, 97, 90];

  @override
  Widget build(BuildContext context) {
    return LabCard(
      children: [
        Row(
          children: const [
            LabSectionTitle(icon: 'chart_bar', text: 'Performa per Grup'),
            Spacer(),
            LabPill(icon: 'calendar', text: 'Minggu ke-4'),
          ],
        ),
        LabInsetBox(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            children: [
              SizedBox(
                height: 129,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < _labels.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _BarGroup(
                          label: _labels[i],
                          kehadiran: _kehadiran[i],
                          nilai: _nilai[i],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _Legend(color: ItlgColors.primary, text: 'Kehadiran (%)'),
                  SizedBox(width: 16),
                  _Legend(color: ItlgColors.secondary, text: 'Rata-rata Nilai'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarGroup extends StatelessWidget {
  final String label;
  final double kehadiran;
  final double nilai;

  const _BarGroup({
    required this.label,
    required this.kehadiran,
    required this.nilai,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 110,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Bar(height: kehadiran, color: ItlgColors.primary),
              const SizedBox(width: 4),
              _Bar(height: nilai, color: ItlgColors.secondary),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            maxLines: 1,
            style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
      ],
    );
  }
}

/// Batang 14 px yang tumbuh dari bawah saat halaman dibuka: jeda 100 ms lalu
/// 600 ms ease-out, sama dengan frame "Page Beranda-Dosen (Animasi Grafik)"
/// di prototipe Figma.
class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: height),
      duration: const Duration(milliseconds: 700),
      curve: const Interval(1 / 7, 1, curve: Curves.easeOut),
      builder: (context, h, _) => Container(
        width: 14,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
      ],
    );
  }
}

class _GroupItem extends StatelessWidget {
  final String title;
  final String assistant;
  final String attendance;
  final String score;
  final VoidCallback onTap;

  const _GroupItem({
    required this.title,
    required this.assistant,
    required this.attendance,
    required this.score,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LabListItem(
      leading: const LabIconTile('people_group'),
      title: title,
      subtitle: 'Asisten: $assistant',
      titleSize: 12,
      onTap: onTap,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(attendance,
              style: labText(12, w: kBold, c: ItlgColors.primary)),
          const SizedBox(height: 2),
          Text(score, style: labText(12, w: kBold, c: ItlgColors.secondary)),
        ],
      ),
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
        constraints: const BoxConstraints(minHeight: 152),
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
