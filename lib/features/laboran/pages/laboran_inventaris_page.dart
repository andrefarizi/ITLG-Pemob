import 'package:flutter/material.dart';

import '../../../core/services/lab_desk_sync_service.dart';
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

/// Halaman Data Inventaris Laboran.
class LaboranInventarisPage extends StatefulWidget {
  final LaboranStore store;
  final VoidCallback? onLogoTap;

  const LaboranInventarisPage({super.key, required this.store, this.onLogoTap});

  @override
  State<LaboranInventarisPage> createState() => _LaboranInventarisPageState();
}

class _LaboranInventarisPageState extends State<LaboranInventarisPage> {
  static const List<_Lab> _labs = [
    _Lab('Jaringan 1', 'Lab Jaringan 1', 'Gedung C • Lantai 2'),
    _Lab('Jaringan 2', 'Lab Jaringan 2', 'Gedung C • Lantai 2'),
    _Lab('Jaringan 3', 'Lab Jaringan 3', 'Gedung D • Lantai 2'),
    _Lab('Jaringan 4', 'Lab Jaringan 4', 'Gedung D • Lantai 3'),
  ];

  static const List<String> _statusFilter = [
    'Semua Status',
    'Siap',
    'Rusak',
  ];

  final LabDeskSyncService _sync = LabDeskSyncService.instance;
  final TextEditingController _search = TextEditingController();
  int _tab = 0;
  String _query = '';

  /// 0 Semua, 1 Siap, 2 Rusak.
  int _status = 0;

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onSyncChanged);
    _sync.refreshFromBackend();
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncChanged);
    _search.dispose();
    super.dispose();
  }

  void _onSyncChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openFilter() async {
    final i = await prakShowPicker(
      context,
      title: 'Filter Status Perangkat',
      options: _statusFilter,
      selected: _status,
    );
    if (i != null && mounted) setState(() => _status = i);
  }

  Future<void> _changeStatus(LabDeskRecord d) async {
    final i = await prakShowPicker(
      context,
      title: 'Kelola ${d.displayName}',
      options: const [
        'Tandai Siap digunakan',
        'Tandai Rusak / perlu perbaikan',
        'Edit Spesifikasi & Kode PC',
        'Hapus dari Inventaris',
      ],
      selected: d.isReady ? 0 : 1,
    );
    if (i == null || !mounted) return;
    if (i == 2) {
      await labPush<bool>(
        context,
        LaboranTambahPerangkatPage(
          store: widget.store,
          initialLab: _tab,
          editRecord: d,
          onLogoTap: widget.onLogoTap,
        ),
      );
      if (mounted) setState(() {});
      return;
    }
    if (i == 3) {
      final ok = await labShowConfirmDialog(
        context,
        icon: 'delete_filled',
        title: 'Hapus ${d.displayName}?',
        message: 'Perangkat dihapus dari inventaris dan denah meja lab.',
        confirmLabel: 'Hapus',
      );
      if (!ok || !mounted) return;
      try {
        await _sync.deleteDeskDevice(
          labName: d.labName,
          deskNumber: d.deskNumber,
        );
    } on StateError catch (e) {
      if (mounted) labToast(context, e.message);
      return;
    }
      if (!mounted) return;
      labToast(context, '${d.displayName} dihapus dari inventaris');
      return;
    }
    final ready = i == 0;
    if (ready == d.isReady) return;
    await _sync.setDeskReadiness(
      labName: d.labName,
      deskNumber: d.deskNumber,
      ready: ready,
    );
    if (!mounted) return;
    labToast(context, '${d.displayName} ditandai ${ready ? 'siap' : 'rusak'}');
  }

  Future<void> _toggleSoftware(LabSoftwareRecord sw) async {
    final choice = await prakShowPicker(
      context,
      title: 'Kelola ${sw.name}',
      options: [
        sw.installed
            ? 'Tandai Perlu Instalasi'
            : 'Tandai Sudah Terpasang',
        'Hapus Software dari Lab',
      ],
      selected: 0,
    );
    if (choice == null || !mounted) return;
    if (choice == 1) {
      final ok = await labShowConfirmDialog(
        context,
        icon: 'delete_filled',
        title: 'Hapus ${sw.name}?',
        message: 'Software dihapus dari inventaris ${sw.labName}.',
        confirmLabel: 'Hapus',
      );
      if (!ok || !mounted) return;
      try {
        await _sync.deleteSoftware(
          labName: sw.labName,
          softwareName: sw.name,
        );
    } on StateError catch (e) {
      if (mounted) labToast(context, e.message);
      return;
    }
      if (!mounted) return;
      labToast(context, '${sw.name} dihapus dari inventaris');
      return;
    }
    try {
      await _sync.toggleSoftwareInstalled(
        labName: sw.labName,
        softwareName: sw.name,
      );
    } on StateError catch (e) {
      if (mounted) labToast(context, e.message);
      return;
    }
    if (!mounted) return;
    labToast(
      context,
      '${sw.name}: ${sw.installed ? 'Terpasang' : 'Perlu instalasi'}',
    );
  }

  /// Bottom sheet Tambah Software (Laboran).
  Future<void> _openAddSoftwareSheet(_Lab lab) async {
    final nameCtrl = TextEditingController();
    final verCtrl = TextEditingController();
    var installed = false;
    final added = await labShowCustomSheet<bool>(
      context,
      title: 'Tambah Software Baru',
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return LabColumn(
            gap: 14,
            children: [
              PrakField(
                label: 'Nama Software',
                child: PrakInput(
                    controller: nameCtrl, hint: 'Contoh: Docker Desktop'),
              ),
              PrakField(
                label: 'Versi',
                child: PrakInput(controller: verCtrl, hint: 'Contoh: 4.35'),
              ),
              PrakField(
                label: 'Status Instalasi',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    for (final opt in const [
                      (false, 'download', 'Perlu Instalasi'),
                      (true, 'circle_check', 'Sudah Terpasang'),
                    ])
                      GestureDetector(
                        onTap: () => setSheetState(() => installed = opt.$1),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: installed == opt.$1
                                ? ItlgColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: installed == opt.$1
                                ? ItlgShadows.primary
                                : ItlgShadows.outline,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LabIcon(
                                opt.$2,
                                size: 15,
                                color: installed == opt.$1
                                    ? Colors.white
                                    : ItlgColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                opt.$3,
                                style: labText(
                                  12,
                                  w: kBold,
                                  c: installed == opt.$1
                                      ? Colors.white
                                      : ItlgColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PrakField(
                label: 'Terapkan ke',
                child: InnerShadowBox(
                  radius: 12,
                  height: 48,
                  color: ItlgColors.field,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Semua PC • Lab ${lab.tab} (30 PC)',
                          style: labText(12, w: kBold),
                        ),
                      ),
                      const LabIcon('chevron_down',
                          size: 14, color: ItlgColors.textSubtle),
                    ],
                  ),
                ),
              ),
              LabPrimaryButton(
                icon: 'plus',
                label: 'Simpan Software',
                large: true,
                onTap: () async {
                  final nm = nameCtrl.text.trim();
                  if (nm.isEmpty) {
                    labToast(ctx, 'Nama software wajib diisi');
                    return;
                  }
                  final full = verCtrl.text.trim().isNotEmpty
                      ? '$nm ${verCtrl.text.trim()}'
                      : nm;
                  try {
                    await _sync.addSoftware(
                      labName: lab.name,
                      softwareName: full,
                      installed: installed,
                    );
                  } on StateError catch (e) {
                    if (ctx.mounted) labToast(ctx, e.message);
                    return;
                  }
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop(true);
                },
              ),
            ],
          );
        },
      ),
    );
    // Lepas controller setelah animasi tutup sheet selesai; melepasnya
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      nameCtrl.dispose();
      verCtrl.dispose();
    });
    if (added == true && mounted) {
      labToast(context, 'Software baru ditambahkan ke Lab ${lab.tab}');
    }
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
  Widget build(BuildContext context) {
    final lab = _labs[_tab];
    final q = _query.trim().toLowerCase();
    final allLabDesks = _sync.inventoryDesks(lab.name);
    final totalDesks = allLabDesks.length;
    final brokenCount = allLabDesks.where((d) => !d.isReady).length;
    final readyCount = totalDesks - brokenCount;

    final allSoftware = _sync.softwareForLab(lab.name);
    final softwarePct = _sync.softwareReadinessPct(lab.name);
    final shownSoftware = allSoftware
        .where((s) =>
            (_status == 0 || s.installed == (_status == 1)) &&
            (q.isEmpty || s.name.toLowerCase().contains(q)))
        .toList();

    final desks = allLabDesks
        .where((d) =>
            (_status == 0 || d.isReady == (_status == 1)) &&
            (q.isEmpty ||
                d.displayName.toLowerCase().contains(q) ||
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
                        cursorWidth: 2.0,
                        cursorRadius: const Radius.circular(2),
                        style: labText(14),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          hintText: 'Cari meja, PC, atau software...',
                          hintStyle: labText(14, c: ItlgColors.textSubtle),
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
            LabStatRow(
              stats: [
                LabStat(icon: 'grid', label: 'Meja', value: '$totalDesks'),
                LabStat(
                    icon: 'desktop_device',
                    label: 'PC Siap',
                    value: '$readyCount'),
                LabStat(
                    icon: 'triangle_alert',
                    label: 'Perlu Cek',
                    value: '$brokenCount'),
              ],
            ),
            LabProgress(
              label: 'Kesiapan Software',
              value: '$softwarePct%',
              fraction: (softwarePct / 100).clamp(0.0, 1.0),
            ),
          ],
        ),
        LabCard(
          children: [
            Row(
              children: [
                const LabSectionTitle(
                    icon: 'database_outline', text: 'Kelengkapan Software'),
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openAddSoftwareSheet(lab),
                  child: Text('+ Tambah Software',
                      style: labText(12, w: kBold, c: ItlgColors.primary)),
                ),
              ],
            ),
            if (shownSoftware.isEmpty)
              Text('Tidak ada software yang cocok dengan pencarian / filter.',
                  style: labText(12, c: ItlgColors.textSubtle))
            else
              for (final sw in shownSoftware)
                _SoftwareRow(
                  icon: sw.icon,
                  name: sw.name,
                  ok: sw.installed,
                  onTap: () => _toggleSoftware(sw),
                ),
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
                      title: d.displayName,
                      subtitle: d.spec,
                      titleSize: 12,
                      trailing: d.isReady
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
  final VoidCallback onTap;

  const _SoftwareRow({
    required this.icon,
    required this.name,
    required this.ok,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
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
      ),
    );
  }
}
