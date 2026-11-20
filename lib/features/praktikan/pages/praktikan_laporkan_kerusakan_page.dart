import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';
import '../../shared/lab_actions.dart';

/// Figma: "Laporkan Kerusakan Meja-Praktikan".
///
/// Dibuka dari halaman Meja Kamu. Meja terkunci sesuai meja yang dibooking,
/// jadi laporan hanya bisa dibuat untuk alat/software di meja tersebut.
class PraktikanLaporkanKerusakanPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanLaporkanKerusakanPage({super.key, required this.nav});

  @override
  State<PraktikanLaporkanKerusakanPage> createState() =>
      _PraktikanLaporkanKerusakanPageState();
}

class _PraktikanLaporkanKerusakanPageState
    extends State<PraktikanLaporkanKerusakanPage> {
  static const String _lab = 'Lab Komputer 1';

  static const List<(String, String)> _kategori = [
    ('desktop_device', 'PC / Monitor'),
    ('chip', 'Keyboard & Mouse'),
    ('wifi', 'Jaringan'),
    ('code_tags', 'Software'),
  ];

  final TextEditingController _deskripsi = TextEditingController();
  int _kat = 0;
  bool _foto = false;

  PraktikanStore get _s => widget.nav.store;

  int get _meja => _s.bookedDesk ?? _s.selectedDesk;

  String get _mejaLabel =>
      'Meja $_meja • PC-${_meja.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _deskripsi.dispose();
    super.dispose();
  }

  void _kirim() {
    final k = _kategori[_kat];
    final desc = _deskripsi.text.trim();
    _s.reports.insert(
      0,
      PrakReport(
        k.$1,
        desc.isEmpty ? '${k.$2} bermasalah • $_mejaLabel' : desc,
        '$_lab • 05 Okt',
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
              label: 'Meja yang Kamu Booking',
              child: LabColumn(
                gap: 8,
                children: [
                  InnerShadowBox(
                    radius: 12,
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$_lab • $_mejaLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: labText(12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const LabIcon('lock_on',
                            size: 16, color: ItlgColors.textSubtle),
                      ],
                    ),
                  ),
                  Text(
                    'Terkunci sesuai meja yang kamu booking. Laporan hanya '
                    'bisa dibuat untuk meja ini.',
                    style: labText(12, c: LabColors.textGrey),
                  ),
                ],
              ),
            ),
            PrakField(
              label: 'Jenis Kendala (Alat / Software)',
              child: PrakOptionChips(
                options: _kategori,
                index: _kat,
                onChanged: (i) => setState(() => _kat = i),
              ),
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
