import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/itlg_ui.dart';
import '../laboran/widgets/laboran_ui.dart';

/// Aksi tampilan yang dipakai bersama oleh semua peran (tanpa backend):
/// panel info, pratinjau berkas, QR, Pusat Bantuan, dan tautan.
///
/// Gaya panel mengikuti `prakShowPicker`: panel bawah #FDFEFE radius atas 24,
/// pegangan 40x4, latar gelap #0A0B0C 40%, fade 250 ms.

/// Satu baris "label : nilai" di panel info.
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
///
/// [primary] dijalankan setelah panel ditutup.
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

/// Pratinjau berkas lampiran: nama, jenis, ukuran, dan tombol Unduh.
Future<void> labShowFilePreview(
  BuildContext context, {
  required String name,
  String size = '—',
  String source = 'Lampiran praktikum',
}) {
  return labShowInfoSheet(
    context,
    title: 'Pratinjau Berkas',
    header: Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ItlgShadows.outline,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LabIcon('file', size: 40, color: ItlgColors.primary),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: labText(12, w: kBold)),
          ),
        ],
      ),
    ),
    rows: [
      ('file', 'Jenis', _fileKind(name)),
      ('download', 'Ukuran', size),
      ('book_open', 'Sumber', source),
    ],
    primary: (
      'download',
      'Unduh Berkas',
      () => labToast(context, '$name diunduh'),
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

/// QR besar untuk dipindai (gambar QR yang sama dengan sesi presensi).
Future<void> labShowQr(
  BuildContext context, {
  required String title,
  required String code,
  String caption = 'Tunjukkan QR ini untuk dipindai.',
}) {
  return _showSheet<void>(
    context,
    title: title,
    body: (sheet) => LabColumn(
      gap: 12,
      children: [
        InnerShadowBox(
          radius: 12,
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Image.asset('assets/aslab_qr.png', width: 220, height: 220),
              const SizedBox(height: 12),
              Text(code,
                  style: labText(22, w: kBold, c: ItlgColors.primary)),
            ],
          ),
        ),
        Text(caption,
            textAlign: TextAlign.center,
            style: labText(12, c: ItlgColors.textMuted)),
        LabOutlineButton(
          icon: 'cross',
          label: 'Tutup',
          large: true,
          onTap: () => Navigator.of(sheet).pop(),
        ),
      ],
    ),
  );
}

/// Pusat Bantuan Lab (sama untuk semua peran). Isinya sama dengan kartu
/// Pusat Bantuan di halaman Masuk.
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

/// Label status laporan kendala (0 Reported, 1 In Progress, 2 Resolved).
const List<String> kLabReportStatus = ['Reported', 'In Progress', 'Resolved'];

Widget labReportChip(int status) {
  switch (status) {
    case 0:
      return const LabChip.danger('Reported');
    case 1:
      return const LabChip.warn('In Progress');
    default:
      return const LabChip.live('Resolved');
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
    'Laporan diterima Laboran.',
    'Laboran sedang menangani kendala.',
    'Kendala selesai ditangani.',
  ];
  final hasPhoto = photoName != null &&
      photoName.trim().isNotEmpty &&
      photoName != 'tanpa_foto.jpg';
  final rows = <LabInfoRow>[
    if (ticketCode != null && ticketCode.isNotEmpty)
      ('ticket', 'Kode Tiket', ticketCode),
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

/// Halaman "Riwayat Laporan" (Lihat Semua) dengan tab status.
class LabRiwayatLaporanPage extends StatefulWidget {
  /// (icon, judul, meta, status)
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

  @override
  Widget build(BuildContext context) {
    final all = _resolveItems();
    final shown =
        _tab == 0 ? all : all.where((r) => r.status == _tab - 1).toList();
    int count(int s) => all.where((r) => r.status == s).length;
    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      children: [
        LabCard(
          children: [
            const LabOverline(
              overline: 'Issue Ticketing',
              title: 'Riwayat Laporan',
            ),
            Text('${all.length} laporan kendala yang pernah anda kirim.',
                style: labText(12, c: ItlgColors.textMuted)),
          ],
        ),
        LabTabs(
          labels: [
            'Semua (${all.length})',
            'Reported (${count(0)})',
            'In Progress (${count(1)})',
            'Resolved (${count(2)})',
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
            gap: 8,
            children: [
              for (final r in shown)
                LabListItem(
                  leading: LabIconTile(r.icon),
                  title: r.title,
                  subtitle: r.meta,
                  titleSize: 12,
                  trailing: labReportChip(r.status),
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
    );
  }
}
