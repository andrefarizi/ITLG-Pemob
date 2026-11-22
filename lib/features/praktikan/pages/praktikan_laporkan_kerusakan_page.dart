import 'package:flutter/material.dart';

import '../../../core/services/file_upload_service.dart';
import '../../../core/services/lab_desk_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../shared/lab_actions.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

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

  final LabDeskSyncService _sync = LabDeskSyncService.instance;
  final TextEditingController _deskripsi = TextEditingController();
  int _kat = 0;
  String? _photoName;
  bool _submitting = false;

  Future<void> _pickPhoto() async {
    final picked = await FileUploadService.instance.pickAndUpload(
      folder: 'tiket/praktikan',
      imagesOnly: true,
    );
    if (picked == null || !mounted) return;
    setState(() => _photoName = picked.name);
    labToast(
      context,
      picked.uploadedToCloud
          ? '${picked.name} berhasil diunggah ke BE'
          : '${picked.name} dipilih dari perangkat',
    );
  }

  PraktikanStore get _s => widget.nav.store;

  int get _meja =>
      _sync.bookedDeskForUser(AuthController.instance.userIdentifier) ??
      _s.bookedDesk ??
      _s.selectedDesk;

  String get _pcCode => 'PC-${_meja.toString().padLeft(2, '0')}';

  String get _mejaLabel => 'Meja $_meja • $_pcCode';

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onSyncChanged);
    _sync.refreshFromBackend();
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncChanged);
    _deskripsi.dispose();
    super.dispose();
  }

  void _onSyncChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _kirim() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final k = _kategori[_kat];
    final desc = _deskripsi.text.trim();
    final auth = AuthController.instance;
    final title = desc.isEmpty ? '${k.$2} bermasalah • $_mejaLabel' : desc;
    final detail = desc.isEmpty
        ? '${k.$2} mengalami kendala pada $_mejaLabel di $_lab.'
        : desc;

    await _sync.createTicket(
      labName: _lab,
      deskNumber: _meja,
      pcCode: _pcCode,
      icon: k.$1,
      category: '${k.$2} • Meja $_meja',
      title: title,
      description: detail,
      reporterId: auth.userIdentifier,
      reporterName: auth.userName,
      reporterRole: 'praktikan',
      photoName: _photoName ?? 'tanpa_foto.jpg',
    );

    if (!mounted) return;
    setState(() => _submitting = false);
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
    final reports = _sync.reportsForPraktikan(
      reporterId: AuthController.instance.userIdentifier,
    );
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
                title: _photoName != null
                    ? '$_photoName terlampir'
                    : 'Ambil atau Pilih Foto Kendala',
                subtitle: 'Format didukung PNG, JPG',
                onTap: _pickPhoto,
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
                      for (final r in reports)
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
                for (final r in reports.take(3))
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
