import 'package:flutter/material.dart';

import '../../../core/services/file_upload_service.dart';
import '../../../core/services/lab_desk_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../../shared/lab_actions.dart';
import '../aslab_nav.dart';

/// Figma: "Lapor Kendala-Aslab".
class AslabLaporKendalaPage extends StatefulWidget {
  final AslabNav nav;
  const AslabLaporKendalaPage({super.key, required this.nav});

  @override
  State<AslabLaporKendalaPage> createState() => _AslabLaporKendalaPageState();
}

class _AslabLaporKendalaPageState extends State<AslabLaporKendalaPage> {
  static const List<String> _labs = [
    'Lab Jaringan 1',
    'Lab Jaringan 2',
    'Lab Jaringan 3',
    'Lab Jaringan 4',
  ];

  static const List<(String, String)> _kategori = [
    ('desktop_device', 'PC'),
    ('projector', 'Proyektor'),
    ('air_conditioner', 'AC'),
    ('wifi', 'Jaringan'),
    ('code_tags', 'Software'),
  ];

  final LabDeskSyncService _sync = LabDeskSyncService.instance;
  final TextEditingController _pc = TextEditingController();
  final TextEditingController _deskripsi = TextEditingController();
  int _lab = 0;
  int _kat = 0;
  String? _photoName;
  bool _submitting = false;

  Future<void> _pickPhoto() async {
    final picked = await FileUploadService.instance.pickAndUpload(
      folder: 'tiket/aslab',
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

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onSyncChanged);
    _sync.refreshFromBackend();
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncChanged);
    _pc.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  void _onSyncChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickLab() async {
    final i = await prakShowPicker(context,
        title: 'Pilih Laboratorium', options: _labs, selected: _lab);
    if (i != null && mounted) setState(() => _lab = i);
  }

  int? _extractDeskNumber(String raw) {
    final m = RegExp(r'(\d+)').firstMatch(raw);
    if (m == null) return null;
    final v = int.tryParse(m.group(1)!);
    if (v == null || v < 1 || v > 30) return null;
    return v;
  }

  Future<void> _kirim() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final k = _kategori[_kat];
    final desc = _deskripsi.text.trim();
    final pc = _pc.text.trim();
    final deskNum = _extractDeskNumber(pc);
    final auth = AuthController.instance;
    final labName = _labs[_lab];
    final title = desc.isEmpty
        ? '${k.$2} bermasalah${pc.isEmpty ? '' : ' • $pc'}'
        : desc;

    await _sync.createTicket(
      labName: labName,
      deskNumber: deskNum,
      pcCode: deskNum != null
          ? 'PC-${deskNum.toString().padLeft(2, '0')}'
          : (pc.isNotEmpty ? pc.toUpperCase() : null),
      icon: k.$1,
      category: deskNum != null ? '${k.$2} • Meja $deskNum' : k.$2,
      title: title,
      description: desc.isEmpty ? title : desc,
      reporterId: auth.userIdentifier,
      reporterName: auth.userName,
      reporterRole: 'aslab',
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
        return const LabChip.danger('Baru');
      case 1:
        return const LabChip.warn('Ditangani');
      default:
        return const LabChip.live('Selesai');
    }
  }

  List<LabReportDetailItem> _buildLiveItems() {
    final live = _sync.allTickets
        .map(
          (t) => LabReportDetailItem(
            icon: t.icon,
            title: t.title,
            meta: '${t.labName} • ${t.formattedDateShort}',
            status: t.status,
            ticketCode: t.ticketCode,
            description: t.description,
            photoName: t.photoName,
            handlingNote: t.handlingNote,
          ),
        )
        .toList();
    if (live.isNotEmpty) return live;
    return [
      for (final r in _sync.reportsForAslab())
        LabReportDetailItem(
          icon: r.icon,
          title: r.title,
          meta: r.meta,
          status: r.status,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final reports = _buildLiveItems();
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            const LabOverline(
              overline: 'Pelaporan Kendala',
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
              label: _kat == 0 ? 'Nomor Meja / PC' : 'Detail Unit / Posisi',
              child: PrakInput(
                controller: _pc,
                hint: _kat == 0
                    ? 'Contoh : PC-12'
                    : 'Contoh : Proyektor depan / AC tengah / Wi-Fi lab',
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
                    liveItemsBuilder: _buildLiveItems,
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
