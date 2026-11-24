import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/services/file_download_service.dart';
import '../../core/widgets/itlg_ui.dart';
import '../laboran/widgets/laboran_ui.dart';

/// Fungsi dialog, pratinjau dokumen, dan aksi lintas peran.

/// Satu baris "label: nilai" di panel info.
typedef LabInfoRow = (String icon, String label, String value);

Future<T?> _showSheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext sheetContext) body,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: const Color(0x660A0B0C),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (sheetContext, anim, _, __) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: ItlgColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 32 + MediaQuery.of(sheetContext).padding.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(title, style: labText(16, w: kBold, c: Colors.black)),
                  const SizedBox(height: 12),
                  body(sheetContext),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _InfoRows extends StatelessWidget {
  final List<LabInfoRow> rows;
  const _InfoRows(this.rows);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ItlgShadows.outline,
      ),
      child: LabColumn(
        gap: 10,
        children: [
          for (final r in rows)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabIcon(r.$1, size: 14, color: ItlgColors.primary),
                const SizedBox(width: 8),
                SizedBox(
                  width: 96,
                  child: Text(r.$2,
                      style: labText(12, c: ItlgColors.textSubtle)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(r.$3,
                      textAlign: TextAlign.right,
                      style: labText(12, w: kBold)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Panel info umum: ikon + judul + baris data + catatan + tombol aksi.
Future<void> labShowInfoSheet(
  BuildContext context, {
  required String title,
  required List<LabInfoRow> rows,
  String? note,
  Widget? header,
  (String icon, String label, VoidCallback onTap)? primary,
  String closeLabel = 'Tutup',
}) {
  return _showSheet<void>(
    context,
    title: title,
    body: (sheet) => LabColumn(
      gap: 12,
      children: [
        if (header != null) header,
        _InfoRows(rows),
        if (note != null)
          Text(note, style: labText(12, c: ItlgColors.textMuted)),
        if (primary != null)
          LabPrimaryButton(
            icon: primary.$1,
            label: primary.$2,
            large: true,
            onTap: () {
              Navigator.of(sheet).pop();
              primary.$3();
            },
          ),
        LabOutlineButton(
          icon: 'cross',
          label: closeLabel,
          large: true,
          onTap: () => Navigator.of(sheet).pop(),
        ),
      ],
    ),
  );
}

/// Jenis berkas dari ekstensi nama (untuk pratinjau).
String _fileKind(String name) {
  final dot = name.lastIndexOf('.');
  final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  switch (ext) {
    case 'pdf':
      return 'Dokumen PDF';
    case 'zip':
      return 'Arsip ZIP';
    case 'sql':
      return 'Skrip SQL';
    case 'fig':
      return 'Berkas Figma';
    case 'mp4':
      return 'Video MP4';
    case 'jpg':
    case 'jpeg':
    case 'png':
      return 'Gambar';
    case 'doc':
    case 'docx':
      return 'Dokumen Word';
    default:
      return 'Berkas';
  }
}

/// Dialog Pratinjau Dokumen PDF.
Future<void> labShowFilePreview(
  BuildContext context, {
  required String name,
  String? size,
  String source = 'Lampiran praktikum',
  List<String> searchFolders = const [],
}) {
  final kind = _fileKind(name);
  final cleanTitle = name
      .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')
      .replaceAll('_', ' ');
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Pratinjau Dokumen',
    barrierColor: const Color(0xFF2B2D31),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (dialogCtx, anim, _, __) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: Material(
        color: const Color(0xFF2B2D31),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(dialogCtx).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: LabIcon('cross', size: 22, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: labText(14, w: kBold, c: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            size == null || size.isEmpty
                                ? kind
                                : '$kind • $size',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: labText(11,
                                w: kMedium, c: const Color(0xFFBFC4CC)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source,
                            style: labText(12,
                                w: kSemiBold, c: ItlgColors.primary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cleanTitle,
                            style: labText(18,
                                w: kBold, c: const Color(0xFF202124)),
                          ),
                          const SizedBox(height: 16),
                          for (final wFactor in const [
                            1.0,
                            0.92,
                            1.0,
                            0.8,
                            1.0,
                            0.86,
                            0.66,
                          ]) ...[
                            FractionallySizedBox(
                              widthFactor: wFactor,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5E8EB),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Dokumen siap diunduh ke perangkat Anda dalam format $kind.',
                            style: labText(12, c: ItlgColors.textSubtle),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                LabPrimaryButton(
                  icon: 'download',
                  label: 'Unduh Berkas',
                  large: true,
                  onTap: () async {
                    Navigator.of(dialogCtx).pop();
                    final res = await FileDownloadService.instance.downloadFile(
                      fileName: name,
                      source: source,
                      searchFolders: searchFolders,
                    );
                    if (!context.mounted) return;
                    if (res.success) {
                      await labShowResult(
                        context,
                        icon: 'download',
                        title: 'Berkas Diunduh',
                        message:
                            'Berkas tersimpan di folder Unduhan perangkat anda.',
                      );
                    } else {
                      labToast(
                        context,
                        'Gagal mengunduh $name: ${res.error ?? 'coba lagi'}',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Tautan luar: tampilkan alamatnya dan salin ke papan klip.
Future<void> labShowLink(
  BuildContext context, {
  required String url,
  String title = 'Tautan Repositori',
}) {
  return labShowInfoSheet(
    context,
    title: title,
    rows: [('link_chain', 'Alamat', url)],
    note: 'Tautan disalin ke papan klip agar bisa dibuka di peramban.',
    primary: (
      'link_chain',
      'Salin Tautan',
      () {
        Clipboard.setData(ClipboardData(text: url));
        labToast(context, 'Tautan disalin');
      },
    ),
  );
}

/// Dialog QR Presensi Asisten (Laboran).
Future<void> labShowQr(
  BuildContext context, {
  required String title,
  required String code,
  String caption = 'Tunjukkan QR ini untuk dipindai.',
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: const Color(0x660A0B0C),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (dialogCtx, anim, _, __) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 370),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 22, 17, 22),
                decoration: BoxDecoration(
                  color: ItlgColors.surfaceDark,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: ItlgShadows.outline,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: QrImageView(
                          data: code,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: labText(22, w: kBold, c: ItlgColors.text),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: labText(14, c: ItlgColors.textMuted),
                    ),
                    const SizedBox(height: 13),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(dialogCtx).pop(),
                      child: Container(
                        height: 39,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ItlgColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: ItlgShadows.outline,
                        ),
                        child: Text(
                          'Tutup',
                          style: labText(16,
                              w: kBold, c: ItlgColors.surfaceWhite),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Tampilkan bottom sheet informasi Pusat Bantuan Lab.
Future<void> labShowHelpCenter(BuildContext context) {
  const alamat = 'Gedung Teknologi Informasi USU (Jl. Alumni, Medan)';
  return labShowInfoSheet(
    context,
    title: 'Pusat Bantuan Lab',
    rows: const [
      ('location', 'Lokasi', alamat),
      ('door', 'Sekretariat', 'Lantai 3, Sekretariat ITLG'),
      ('clock', 'Jam Layanan', 'Senin–Jumat, 08:00–16:30 WIB'),
    ],
    note: 'Untuk kerusakan perangkat, gunakan menu Laporkan Kerusakan agar '
        'langsung diteruskan ke Laboran.',
    primary: (
      'location',
      'Salin Alamat',
      () {
        Clipboard.setData(const ClipboardData(text: alamat));
        labToast(context, 'Alamat Pusat Bantuan disalin');
      },
    ),
  );
}

/// Label status laporan kendala (0 Baru, 1 Ditangani, 2 Selesai).
const List<String> kLabReportStatus = ['Baru', 'Ditangani', 'Selesai'];

Widget labReportChip(int status) {
  switch (status) {
    case 0:
      return const LabChip.danger('Baru');
    case 1:
      return const LabChip.warn('Ditangani');
    default:
      return const LabChip.live('Selesai');
  }
}

/// Model ringkas satu baris laporan untuk Riwayat Laporan & Detail Laporan.
class LabReportDetailItem {
  final String icon;
  final String title;
  final String meta;
  final int status;
  final String? ticketCode;
  final String? description;
  final String? photoName;
  final String? handlingNote;

  const LabReportDetailItem({
    required this.icon,
    required this.title,
    required this.meta,
    required this.status,
    this.ticketCode,
    this.description,
    this.photoName,
    this.handlingNote,
  });
}

/// Detail satu laporan kendala.
Future<void> labShowReportDetail(
  BuildContext context, {
  required String icon,
  required String title,
  required String meta,
  required int status,
  String? ticketCode,
  String? description,
  String? photoName,
  String? handlingNote,
}) {
  const steps = [
    'Laporan diterima Laboran dan menunggu penanganan.',
    'Laboran sedang menangani kendala perangkat.',
    'Kendala selesai ditangani oleh Laboran.',
  ];
  final hasPhoto = photoName != null &&
      photoName.trim().isNotEmpty &&
      photoName != 'tanpa_foto.jpg';
  final displayCode = ticketCode?.replaceFirst('#TK-', '#LK-');
  final rows = <LabInfoRow>[
    if (displayCode != null && displayCode.isNotEmpty)
      ('ticket', 'Kode Laporan', displayCode),
    ('location', 'Lokasi & Tanggal', meta),
    ('wrench_outline', 'Status', kLabReportStatus[status.clamp(0, 2)]),
    if (hasPhoto) ('camera', 'Lampiran', photoName),
    if (handlingNote != null && handlingNote.trim().isNotEmpty)
      ('file', 'Catatan Laboran', handlingNote.trim()),
  ];
  final noteText = (description != null &&
          description.trim().isNotEmpty &&
          description.trim() != title.trim())
      ? '${description.trim()}\n\n${steps[status.clamp(0, 2)]}'
      : steps[status.clamp(0, 2)];

  return labShowInfoSheet(
    context,
    title: 'Detail Laporan',
    header: Row(
      children: [
        LabIconTile(icon),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: labText(14, w: kBold))),
        const SizedBox(width: 8),
        labReportChip(status),
      ],
    ),
    rows: rows,
    note: noteText,
  );
}

/// Halaman Riwayat Laporan Praktikan.
class LabRiwayatLaporanPage extends StatefulWidget {
  final List<(String, String, String, int)> reports;
  final Listenable? listenable;
  final List<LabReportDetailItem> Function()? liveItemsBuilder;
  final VoidCallback? onLogoTap;

  const LabRiwayatLaporanPage({
    super.key,
    this.reports = const [],
    this.listenable,
    this.liveItemsBuilder,
    this.onLogoTap,
  });

  @override
  State<LabRiwayatLaporanPage> createState() => _LabRiwayatLaporanPageState();
}

class _LabRiwayatLaporanPageState extends State<LabRiwayatLaporanPage> {
  /// 0 Semua, 1 Diproses (Baru + Ditangani), 2 Selesai.
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    widget.listenable?.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.listenable?.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<LabReportDetailItem> _resolveItems() {
    if (widget.liveItemsBuilder != null) {
      return widget.liveItemsBuilder!();
    }
    return [
      for (final r in widget.reports)
        LabReportDetailItem(icon: r.$1, title: r.$2, meta: r.$3, status: r.$4),
    ];
  }

  Widget _stepTimeline(int status) {
    const labels = ['Baru', 'Ditangani', 'Selesai'];
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= status
                        ? ItlgColors.primary
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  style: labText(
                    11,
                    w: i <= status ? kSemiBold : kMedium,
                    c: i <= status
                        ? ItlgColors.primary
                        : ItlgColors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _historyStatusChip(int status) {
    switch (status) {
      case 0:
        return const LabChip.info('Baru');
      case 1:
        return const LabChip.warn('Sedang Ditangani');
      default:
        return const LabChip.live('Selesai');
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _resolveItems();
    final shown = switch (_tab) {
      1 => all.where((r) => r.status < 2).toList(),
      2 => all.where((r) => r.status == 2).toList(),
      _ => all,
    };
    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      children: [
        LabCard(
          children: [
            const LabOverline(
              overline: 'Laporan Saya',
              title: 'Riwayat Laporan',
            ),
            Text(
              'Pantau status laporan kerusakan yang kamu kirim dan catatan penanganan dari Laboran.',
              style: labText(12, c: ItlgColors.textMuted),
            ),
          ],
        ),
        LabTabs(
          labels: [
            'Semua (${all.length})',
            'Diproses',
            'Selesai',
          ],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('Belum ada laporan dengan status ini.',
                textAlign: TextAlign.center,
                style: labText(12, c: ItlgColors.textSubtle)),
          )
        else
          LabColumn(
            gap: 12,
            children: [
              for (var idx = 0; idx < shown.length; idx++)
                () {
                  final r = shown[idx];
                  final code = (r.ticketCode ?? '#LK-09${21 - idx}')
                      .replaceFirst('#TK-', '#LK-');
                  return LabCard(
                    gap: 12,
                    onTap: () => labShowReportDetail(
                      context,
                      icon: r.icon,
                      title: r.title,
                      meta: r.meta,
                      status: r.status,
                      ticketCode: code,
                      description: r.description,
                      photoName: r.photoName,
                      handlingNote: r.handlingNote,
                    ),
                    children: [
                      Row(
                        children: [
                          LabTag.grey(code),
                          const Spacer(),
                          _historyStatusChip(r.status),
                        ],
                      ),
                      Text(r.title,
                          style: labText(16, w: kBold, c: Colors.black)),
                      LabColumn(
                        gap: 4,
                        children: [
                          LabMeta(icon: 'location', text: r.meta),
                          LabMeta(
                            icon: 'clock',
                            text: r.status == 2
                                ? 'Dikirim ${r.meta.split('•').last.trim()} • selesai ditangani'
                                : 'Dikirim ${r.meta.split('•').last.trim()}',
                          ),
                        ],
                      ),
                      _stepTimeline(r.status),
                      if (r.handlingNote != null &&
                          r.handlingNote!.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: LabColors.tagBlueBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: LabIcon('info',
                                    size: 18, color: LabColors.blueDark),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Catatan Laboran',
                                      style: labText(12,
                                          w: kBold, c: LabColors.blueDark),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r.handlingNote!.trim(),
                                      style: labText(12,
                                          w: kMedium, c: LabColors.blueDark),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }(),
            ],
          ),
      ],
    );
  }
}
