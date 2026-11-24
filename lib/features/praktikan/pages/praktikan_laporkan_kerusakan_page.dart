import 'package:flutter/material.dart';

import '../../../core/services/file_upload_service.dart';
import '../../../core/services/lab_desk_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../shared/lab_actions.dart';
import '../praktikan_nav.dart';
import '../widgets/praktikan_ui.dart';

/// Halaman Laporkan Kerusakan Meja Praktikan.
class PraktikanLaporkanKerusakanPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanLaporkanKerusakanPage({super.key, required this.nav});

  @override
  State<PraktikanLaporkanKerusakanPage> createState() =>
      _PraktikanLaporkanKerusakanPageState();
}

class _PraktikanLaporkanKerusakanPageState
    extends State<PraktikanLaporkanKerusakanPage> {
  static const List<(String, String)> _kategori = [
    ('desktop_device', 'PC / Monitor'),
    ('chip', 'Keyboard & Mouse'),
    ('wifi', 'Jaringan'),
    ('code_tags', 'Software'),
  ];

  final LabDeskSyncService _sync = LabDeskSyncService.instance;
  final PresensiSyncService _presensi = PresensiSyncService.instance;
  final TextEditingController _deskripsi = TextEditingController();
  int _kat = 0;
  String? _photoName;
  bool _submitting = false;

  static const List<String> _labs = [
    'Lab Jaringan 1',
    'Lab Jaringan 2',
    'Lab Jaringan 3',
    'Lab Jaringan 4',
  ];
  final TextEditingController _mejaCtrl = TextEditingController();
  int _labIdx = 0;

  /// Meja yang sedang dipesan pada sesi aktif (terkunci). Null bila dibuka
  /// dari Profil / tanpa sesi: lab & nomor meja dipilih sendiri.
  int? get _bookedDesk {
    final session = _presensi.activeSession;
    if (!session.isActive) return null;
    return _sync.bookedDeskForUser(
      AuthController.instance.userIdentifier,
      labName: session.labName,
    );
  }

  bool get _locked => _bookedDesk != null;

  String get _lab =>
      _locked ? _presensi.activeSession.labName : _labs[_labIdx];

  Future<void> _pickPhoto() async {
    final picked = await FileUploadService.instance.pickAndUpload(
      folder: 'tiket/praktikan',
      imagesOnly: true,
    );
    if (picked == null || !mounted) return;
    if (!picked.uploadedToCloud) {
      labToast(context,
          'Gagal mengunggah ${picked.name}. Periksa koneksi lalu coba lagi.');
      return;
    }
    setState(() => _photoName = picked.name);
    labToast(context, '${picked.name} berhasil diunggah');
  }

  int? get _meja => _locked ? _bookedDesk : int.tryParse(_mejaCtrl.text.trim());

  String get _pcCode => 'PC-${(_meja ?? 0).toString().padLeft(2, '0')}';

  String get _mejaLabel => 'Meja $_meja • $_pcCode';

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onSyncChanged);
    _presensi.addListener(_onSyncChanged);
    _sync.refreshFromBackend();
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncChanged);
    _presensi.removeListener(_onSyncChanged);
    _deskripsi.dispose();
    _mejaCtrl.dispose();
    super.dispose();
  }

  void _onSyncChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _kirim() async {
    if (_submitting) return;
    final meja = _meja;
    if (meja == null || meja < 1 || meja > 30) {
      labToast(context, 'Isi nomor meja 1–30', error: true);
      return;
    }
    if (_deskripsi.text.trim().length < 10) {
      labToast(context, 'Jelaskan kendala minimal 10 karakter');
      return;
    }
    setState(() => _submitting = true);

    final k = _kategori[_kat];
    final desc = _deskripsi.text.trim();
    final auth = AuthController.instance;
    final title = desc.isEmpty ? '${k.$2} bermasalah • $_mejaLabel' : desc;
    final detail = desc.isEmpty
        ? '${k.$2} mengalami kendala pada $_mejaLabel di $_lab.'
        : desc;

    final LabTicketRecord ticket;
    try {
      ticket = await _sync.createTicket(
      labName: _lab,
      deskNumber: meja,
      pcCode: _pcCode,
      icon: k.$1,
      category: '${k.$2} • Meja $meja',
      title: title,
      description: detail,
      reporterId: auth.userIdentifier,
      reporterName: auth.userName,
      reporterRole: 'praktikan',
      photoName: _photoName ?? 'tanpa_foto.jpg',
      photoPath: _photoName == null
          ? null
          : FileUploadService.instance.remotePathForName(_photoName!),
    );
    } on StateError catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        labToast(context, e.message);
      }
      return;
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).maybePop();
    labToast(context, 'Laporan ${ticket.ticketCode} diteruskan ke Laboran & Aslab');
  }

  Widget _chip(int status) {
    switch (status) {
      case 0:
        return const LabChip.danger('Baru');
      case 1:
        return const LabChip.warn('Ditangani');
      default:
        return const LabChip.live('Selesai');
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
            if (_locked)
              PrakField(
                label: 'Meja Kamu',
                child: InnerShadowBox(
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
              )
            else ...[
              PrakField(
                label: 'Laboratorium',
                child: PrakSelect(
                  value: _labs[_labIdx],
                  onTap: () async {
                    final i = await prakShowPicker(context,
                        title: 'Pilih Laboratorium',
                        options: _labs,
                        selected: _labIdx);
                    if (i != null && mounted) setState(() => _labIdx = i);
                  },
                ),
              ),
              PrakField(
                label: 'Nomor Meja (1–30)',
                child: PrakInput(
                  controller: _mejaCtrl,
                  hint: 'Contoh: 12',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
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
                    listenable: _sync,
                    liveItemsBuilder: () => _sync
                        .reportsForPraktikan(
                          reporterId: AuthController.instance.userIdentifier,
                        )
                        .map(
                          (r) => LabReportDetailItem(
                            icon: r.icon,
                            title: r.title,
                            meta: r.meta,
                            status: r.status,
                            ticketCode: r.ticketCode,
                            description: r.description,
                            photoName: r.photoName,
                            handlingNote: r.handlingNote,
                          ),
                        )
                        .toList(),
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
                      ticketCode: r.ticketCode,
                      description: r.description,
                      photoName: r.photoName,
                      handlingNote: r.handlingNote,
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
