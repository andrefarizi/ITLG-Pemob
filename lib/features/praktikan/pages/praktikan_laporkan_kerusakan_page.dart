import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';
import '../../shared/lab_actions.dart';

/// Figma: "Laporkan Kerusakan Meja-Praktikan".
class PraktikanLaporkanKerusakanPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanLaporkanKerusakanPage({super.key, required this.nav});

  @override
  State<PraktikanLaporkanKerusakanPage> createState() =>
      _PraktikanLaporkanKerusakanPageState();
}

class _PraktikanLaporkanKerusakanPageState
    extends State<PraktikanLaporkanKerusakanPage> {
  static const List<String> _labs = [
    'Lab Komputer 1',
    'Lab Komputer 2',
    'Lab Jaringan 2',
    'Lab Multimedia',
  ];

  static const List<(String, String)> _kategori = [
    ('desktop_device', 'PC'),
    ('projector', 'Proyektor'),
    ('air_conditioner', 'AC'),
    ('wifi', 'Jaringan'),
    ('code_tags', 'Software'),
  ];

  late final TextEditingController _meja;
  final TextEditingController _deskripsi = TextEditingController();
  int _lab = 0;
  int _kat = 0;
  bool _foto = false;

  PraktikanStore get _s => widget.nav.store;

  @override
  void initState() {
    super.initState();
    final n = _s.selectedDesk;
    _meja = TextEditingController(
        text: 'Meja $n • PC-${n.toString().padLeft(2, '0')}');
  }

  @override
  void dispose() {
    _meja.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  Future<void> _pickLab() async {
    final i = await prakShowPicker(
      context,
      title: 'Pilih Laboratorium',
      options: _labs,
      selected: _lab,
    );
    if (i != null && mounted) setState(() => _lab = i);
  }

  void _kirim() {
    final k = _kategori[_kat];
    final desc = _deskripsi.text.trim();
    _s.reports.insert(
      0,
      PrakReport(
        k.$1,
        desc.isEmpty ? '${k.$2} bermasalah • ${_meja.text}' : desc,
        '${_labs[_lab]} • 05 Okt',
        0,
      ),
    );
    Navigator.of(context).maybePop();
    labToast(context, 'Laporan diteruskan ke Laboran');
  }

  Widget _chip(int status) {
    switch (status) {
      case 0:
        return const LabChip.danger('Reported');
      case 1:
        return const LabChip.warn('In Progress');
      default:
        return const LabChip.live('Resolved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            const LabOverline(
              overline: 'Issue Ticketing',
              title: 'Laporkan Kerusakan Meja',
            ),
            Text('Laporan langsung diteruskan ke Laboran untuk ditangani.',
                style: labText(12, c: ItlgColors.textMuted)),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(
                  icon: 'triangle_alert', text: 'Detail Kendala'),
            ),
            PrakField(
              label: 'Laboratorium',
              child: PrakSelect(value: _labs[_lab], onTap: _pickLab),
            ),
            PrakField(
              label: 'Kategori Perangkat',
              child: PrakOptionChips(
                options: _kategori,
                index: _kat,
                onChanged: (i) => setState(() => _kat = i),
              ),
            ),
            PrakField(
              label: 'Nomor Meja / PC',
              child: PrakInput(controller: _meja),
            ),
            PrakField(
              label: 'Deskripsi Kendala :',
              child: PrakTextArea(
                controller: _deskripsi,
                hint: 'Jelaskan kendala yang ditemukan...',
              ),
            ),
            PrakField(
              label: 'Foto (Opsional)',
              child: PrakUploadBox(
                camera: true,
                title: _foto
                    ? 'foto_kendala.jpg terlampir'
                    : 'Ambil atau Pilih Foto Kendala',
                subtitle: 'Format didukung PNG, JPG',
                onTap: () => setState(() => _foto = !_foto),
              ),
            ),
          ],
        ),
        LabPrimaryButton(
          icon: 'send',
          label: 'Kirim Laporan',
          large: true,
          onTap: _kirim,
        ),
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabSectionTitle(
                  icon: 'wrench_outline', text: 'Laporan Saya'),
              right: PrakSideLink(
                'Lihat Semua',
                onTap: () => labPush(
                  context,
                  LabRiwayatLaporanPage(
                    reports: [
                      for (final r in _s.reports)
                        (r.icon, r.title, r.meta, r.status),
                    ],
                    onLogoTap: widget.nav.home,
                  ),
                ),
              ),
            ),
            LabColumn(
              gap: 8,
              children: [
                for (final r in _s.reports.take(3))
                  LabListItem(
                    leading: LabIconTile(r.icon),
                    title: r.title,
                    subtitle: r.meta,
                    titleSize: 12,
                    trailing: _chip(r.status),
                    onTap: () => labShowReportDetail(
                      context,
                      icon: r.icon,
                      title: r.title,
                      meta: r.meta,
                      status: r.status,
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
