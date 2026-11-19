import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../laboran_store.dart';
import '../widgets/laboran_ui.dart';
import 'laboran_tambah_perangkat_page.dart';

class _Lab {
  final String tab;
  final String name;
  final String place;
  const _Lab(this.tab, this.name, this.place);
}

/// Figma: "Data Inventaris-Laboran".
class LaboranInventarisPage extends StatefulWidget {
  final LaboranStore store;
  final VoidCallback? onLogoTap;

  const LaboranInventarisPage({super.key, required this.store, this.onLogoTap});

  @override
  State<LaboranInventarisPage> createState() => _LaboranInventarisPageState();
}

class _LaboranInventarisPageState extends State<LaboranInventarisPage> {
  static const List<_Lab> _labs = [
    _Lab('Komputer 1', 'Lab Komputer 1', 'Gedung C • Lantai 2'),
    _Lab('Jaringan 2', 'Lab Jaringan 2', 'Gedung C • Lantai 2'),
    _Lab('Multimedia', 'Lab Multimedia', 'Gedung D • Lantai 2'),
  ];

  static const List<String> _statusFilter = [
    'Semua Status',
    'Siap',
    'Rusak',
  ];

  final TextEditingController _search = TextEditingController();
  int _tab = 0;
  String _query = '';

  /// 0 Semua, 1 Siap, 2 Rusak.
  int _status = 0;

  Future<void> _openFilter() async {
    final i = await prakShowPicker(
      context,
      title: 'Filter Status Perangkat',
      options: _statusFilter,
      selected: _status,
    );
    if (i != null && mounted) setState(() => _status = i);
  }

  Future<void> _changeStatus(LabDesk d) async {
    final i = await prakShowPicker(
      context,
      title: 'Status ${d.name}',
      options: const ['Siap digunakan', 'Rusak / perlu perbaikan'],
      selected: d.ready ? 0 : 1,
    );
    if (i == null || !mounted) return;
    final ready = i == 0;
    if (ready == d.ready) return;
    setState(() => d.ready = ready);
    labToast(context,
        '${d.name} ditandai ${ready ? 'siap' : 'rusak'}');
  }

  Future<void> _tambah() async {
    await labPush<bool>(
      context,
      LaboranTambahPerangkatPage(
        store: widget.store,
        initialLab: _tab,
        onLogoTap: widget.onLogoTap,
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lab = _labs[_tab];
    final q = _query.trim().toLowerCase();
    final desks = widget.store.desks[_tab]
        .where((d) =>
            (_status == 0 || d.ready == (_status == 1)) &&
            (q.isEmpty ||
                d.name.toLowerCase().contains(q) ||
                d.spec.toLowerCase().contains(q)))
        .toList();

    return LabTabBody(
      children: [
        const LabTitle(
          title: 'Data Inventaris',
          subtitle: 'Kelola meja, spesifikasi PC, dan kesiapan software '
              'tiap lab',
        ),
        Row(
          children: [
            Expanded(
              child: InnerShadowBox(
                radius: 12,
                height: 48,
                color: LabColors.tile,
                shadows: LabShadows.search,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const LabIcon('search',
                        size: 15, color: ItlgColors.textSubtle),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (v) => setState(() => _query = v),
                        cursorColor: ItlgColors.primary,
                        style: labText(12),
                        decoration: InputDecoration.collapsed(
                          hintText: 'Cari meja, PC, atau software...',
                          hintStyle: labText(12, c: ItlgColors.textSubtle),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openFilter,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: LabColors.tile,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: LabShadows.neu,
                ),
                child: LabIcon('settings_horizontal',
                    size: 15,
                    color: _status != 0
                        ? ItlgColors.primary
                        : LabColors.filterIcon),
              ),
            ),
          ],
        ),
        LabTabs(
          labels: [for (final l in _labs) l.tab],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        LabCard(
          children: [
            LabOverline(overline: lab.place, title: lab.name),
            const LabStatRow(
              stats: [
                LabStat(icon: 'grid', label: 'Meja', value: '30'),
                LabStat(icon: 'desktop_device', label: 'PC Siap', value: '28'),
                LabStat(
                    icon: 'triangle_alert', label: 'Perlu Cek', value: '2'),
              ],
            ),
            const LabProgress(
              label: 'Kesiapan Software',
              value: '93%',
              fraction: 314 / 338,
            ),
          ],
        ),
        const LabCard(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(
                  icon: 'database_outline', text: 'Kelengkapan Software'),
            ),
            _SoftwareRow(icon: 'database_outline', name: 'MySQL 8.0', ok: true),
            _SoftwareRow(
                icon: 'database_outline', name: 'PostgreSQL 16', ok: true),
            _SoftwareRow(icon: 'code_tags', name: 'Android Studio', ok: false),
            _SoftwareRow(
                icon: 'code_tags', name: 'Visual Studio Code', ok: true),
            _SoftwareRow(icon: 'pencil', name: 'Figma Desktop', ok: true),
          ],
        ),
        LabCard(
          children: [
            Row(
              children: [
                const LabSectionTitle(icon: 'chip', text: 'Daftar Meja & PC'),
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _search.clear();
                    setState(() {
                      _query = '';
                      _status = 0;
                    });
                  },
                  child: Text('Lihat Semua',
                      style: labText(12, c: ItlgColors.primary)),
                ),
              ],
            ),
            if (desks.isEmpty)
              Text('Tidak ada meja yang cocok dengan pencarian / filter.',
                  style: labText(12, c: ItlgColors.textSubtle))
            else
              LabColumn(
                gap: 8,
                children: [
                  for (final d in desks)
                    LabListItem(
                      leading: const LabIconTile('chip'),
                      title: d.name,
                      subtitle: d.spec,
                      titleSize: 12,
                      trailing: d.ready
                          ? const LabChip.live('Siap')
                          : const LabChip.danger('Rusak'),
                      onTap: () => _changeStatus(d),
                    ),
                ],
              ),
          ],
        ),
        LabPrimaryButton(
          icon: 'plus',
          label: 'Tambah Perangkat',
          large: true,
          onTap: _tambah,
        ),
      ],
    );
  }
}

class _SoftwareRow extends StatelessWidget {
  final String icon;
  final String name;
  final bool ok;

  const _SoftwareRow({
    required this.icon,
    required this.name,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LabIcon(icon, size: 14, color: ItlgColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(name, style: labText(12, w: kBold))),
        LabStatusDot(
          size: 26,
          color: ok ? LabColors.green : ItlgColors.primary,
          icon: ok ? 'check' : 'cross',
        ),
      ],
    );
  }
}
