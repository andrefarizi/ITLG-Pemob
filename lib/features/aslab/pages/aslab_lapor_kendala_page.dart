import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';
import '../../shared/lab_actions.dart';

/// Figma: "Lapor Kendala-Aslab".
class AslabLaporKendalaPage extends StatefulWidget {
  final AslabNav nav;
  const AslabLaporKendalaPage({super.key, required this.nav});

  @override
  State<AslabLaporKendalaPage> createState() => _AslabLaporKendalaPageState();
}

class _AslabLaporKendalaPageState extends State<AslabLaporKendalaPage> {
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

  final TextEditingController _pc = TextEditingController();
  final TextEditingController _deskripsi = TextEditingController();
  int _lab = 0;
  int _kat = 0;
  bool _foto = false;

  AslabStore get _s => widget.nav.store;

  @override
  void dispose() {
    _pc.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  Future<void> _pickLab() async {
    final i = await prakShowPicker(context,
        title: 'Pilih Laboratorium', options: _labs, selected: _lab);
    if (i != null && mounted) setState(() => _lab = i);
  }

  void _kirim() {
    final k = _kategori[_kat];
    final desc = _deskripsi.text.trim();
    final pc = _pc.text.trim();
    _s.reports.insert(
      0,
      AslabReport(
        k.$1,
        desc.isEmpty
            ? '${k.$2} bermasalah${pc.isEmpty ? '' : ' • $pc'}'
            : desc,
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
              title: 'Lapor Kendala Lab',
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
              child: PrakInput(controller: _pc, hint: 'Contoh : PC-12'),
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
