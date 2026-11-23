import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/services/file_download_service.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../core/services/lab_desk_sync_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../laboran_store.dart';
import '../widgets/laboran_ui.dart';

/// Figma: "Detail Tiket-Laboran".
class LaboranDetailTiketPage extends StatefulWidget {
  final LabTicket ticket;
  final VoidCallback? onLogoTap;

  const LaboranDetailTiketPage({super.key, required this.ticket, this.onLogoTap});

  @override
  State<LaboranDetailTiketPage> createState() => _LaboranDetailTiketPageState();
}

class _LaboranDetailTiketPageState extends State<LaboranDetailTiketPage> {
  static const List<String> _statuses = ['Baru', 'Ditangani', 'Selesai'];

  /// 0 Baru, 1 Ditangani, 2 Selesai.
  late int _status;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final live = LabDeskSyncService.instance.ticketByCode(widget.ticket.id);
    _status = live?.status ?? widget.ticket.status;
    _note = TextEditingController(
      text: live?.handlingNote ?? widget.ticket.handlingNote,
    );
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Widget _statusChip() {
    switch (_status) {
      case 0:
        return const LabChip.danger('Baru');
      case 2:
        return const LabChip.live('Selesai');
      default:
        return const LabChip.warn('Ditangani');
    }
  }

  String? _resolvePhotoUrl(String photoName) {
    final trimmed = photoName.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final remoteObj = FileUploadService.instance.remotePathForName(trimmed);
    final client = SupabaseService.instance.client;
    if (remoteObj != null && client != null) {
      return client.storage
          .from(FileUploadService.bucketName)
          .getPublicUrl(remoteObj);
    }
    return null;
  }

  Future<void> _downloadPhoto(String photoName, LabTicket ticket) async {
    final res = await FileDownloadService.instance.downloadFile(
      fileName: photoName,
      source: 'Laporan Kerusakan ${ticket.id} • ${ticket.lokasi}',
      contentLines: [
        'LAMPIRAN LAPORAN KERUSAKAN ITLG',
        'Kode Tiket : ${ticket.id.replaceFirst('#TK-', '#LK-')}',
        'Lokasi     : ${ticket.lokasi}',
        'Kategori   : ${ticket.kategori}',
        'Judul      : ${ticket.detailTitle}',
        'Pelapor    : ${ticket.reporter} (${ticket.reportedAt})',
        'Lampiran   : $photoName',
        'Deskripsi  : ${ticket.detail}',
      ],
    );
    if (!mounted) return;
    labToast(
      context,
      res.success
          ? '$photoName tersimpan di ${res.location}'
          : 'Gagal mengunduh $photoName',
    );
  }

  Widget _buildPhotoContent(String photoName) {
    final localPath = FileUploadService.instance.localPathForName(photoName);
    if (!kIsWeb && localPath != null && File(localPath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.file(
          File(localPath),
          fit: BoxFit.contain,
          width: double.infinity,
          height: 320,
        ),
      );
    }
    final remoteUrl = _resolvePhotoUrl(photoName);
    if (remoteUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          remoteUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          height: 320,
          errorBuilder: (_, __, ___) => _photoPlaceholder(photoName),
        ),
      );
    }
    return _photoPlaceholder(photoName);
  }

  Widget _photoPlaceholder(String photoName) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const LabIcon('desktop_device',
            size: 72, color: Color(0xFFBFC4CC)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$photoName • 1,2 MB',
            style: labText(11, w: kBold, c: ItlgColors.text),
          ),
        ),
      ],
    );
  }

  /// Figma: "Pratinjau Foto Kerusakan-Laboran" (5817:3148).
  void _showPhotoPreview(String photoName, LabTicket ticket) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Pratinjau Foto',
      barrierColor: const Color(0xFF0A0B0C),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) => FadeTransition(
        opacity: anim,
        child: Material(
          color: const Color(0xFF0A0B0C),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const LabIcon('cross',
                              size: 15, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  height: 320,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF333840), Color(0xFF565D67)],
                    ),
                  ),
                  child: _buildPhotoContent(photoName),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: LabOutlineButton(
                    icon: 'download',
                    label: 'Unduh Foto',
                    large: true,
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await _downloadPhoto(photoName, ticket);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    await LabDeskSyncService.instance.updateTicketStatus(
      ticketCode: widget.ticket.id,
      status: _status,
      handlingNote: _note.text.trim(),
    );
    if (!mounted) return;
    labToast(context, 'Status tiket ${widget.ticket.id} disimpan');
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final t =
        LabDeskSyncService.instance.ticketByCode(widget.ticket.id)?.toLabTicket() ??
            widget.ticket;
    final reporterRoleLabel =
        t.reporterRole == 'praktikan' ? 'Praktikan' : 'Asisten Lab';
    final hasPhoto = t.photo.trim().isNotEmpty && t.photo != 'tanpa_foto.jpg';
    final photoCaption = hasPhoto
        ? 'Lampiran dari ${reporterRoleLabel.toLowerCase()} • 1 foto'
        : 'Tidak ada foto yang dilampirkan';
    final liveNote = _note.text.trim();

    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      children: [
        LabCard(
          children: [
            Row(
              children: [
                LabTag.grey(t.id.replaceFirst('#TK-', '#LK-')),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_status),
                    child: _statusChip(),
                  ),
                ),
              ],
            ),
            LabOverline(overline: 'Laporan Kerusakan', title: t.detailTitle),
            LabStatRow(
              gap: 13,
              stats: [
                LabStat(icon: 'location', label: 'Lokasi', value: t.lokasi),
                LabStat(
                    icon: 'desktop_device',
                    label: 'Kategori',
                    value: t.kategori),
              ],
            ),
            LabPerson(
              initials: t.initials,
              name: t.reporter,
              caption: '$reporterRoleLabel • ${t.reportedAt}',
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(icon: 'file', text: 'Detail Kerusakan'),
            ),
            Text(t.detail, style: labText(12, c: Colors.black)),
            LabInsetBox(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const LabIconTile('camera'),
                  const SizedBox(height: 7),
                  Text(
                      hasPhoto
                          ? '${t.photo} • 1,2 MB'
                          : 'Tanpa lampiran foto',
                      style: labText(12, w: kBold)),
                  const SizedBox(height: 7),
                  Text(photoCaption,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                  if (hasPhoto) ...[
                    const SizedBox(height: 12),
                    LabButtonPair(
                      left: LabPrimaryButton(
                        icon: 'eye',
                        label: 'Lihat Foto Penuh',
                        onTap: () => _showPhotoPreview(t.photo, t),
                      ),
                      right: LabOutlineButton(
                        icon: 'download',
                        label: 'Unduh',
                        onTap: () => _downloadPhoto(t.photo, t),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(
                  icon: 'arrow_cycle', text: 'Status Penanganan'),
            ),
            LabColumn(
              gap: 14,
              children: [
                _Step(
                  state: _StepState.done,
                  title: 'Baru',
                  caption: t.reportedAt,
                ),
                _Step(
                  state: _status >= 2
                      ? _StepState.done
                      : (_status == 1 ? _StepState.active : _StepState.idle),
                  title: 'Ditangani',
                  caption: _status >= 1
                      ? (liveNote.isNotEmpty
                          ? liveNote
                          : 'Sedang ditangani teknisi laboratorium')
                      : 'Menunggu penanganan',
                ),
                _Step(
                  state: _status == 2 ? _StepState.done : _StepState.idle,
                  title: 'Selesai',
                  caption: _status == 2
                      ? 'Perbaikan selesai • perangkat siap digunakan'
                      : 'Menunggu penyelesaian',
                ),
              ],
            ),
            LabColumn(
              gap: 8,
              children: [
                Text('Perbarui Status', style: labText(14)),
                LabTabs(
                  labels: _statuses,
                  index: _status,
                  gap: 10,
                  hPadding: 12,
                  onChanged: (i) => setState(() => _status = i),
                ),
              ],
            ),
            LabColumn(
              gap: 8,
              children: [
                Text('Catatan Penanganan :', style: labText(14)),
                InnerShadowBox(
                  radius: 12,
                  height: 96,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: TextField(
                    controller: _note,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    cursorColor: ItlgColors.primary,
                    cursorWidth: 2.0,
                    cursorRadius: const Radius.circular(2),
                    style: labText(14),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: 'Tulis catatan penanganan...',
                      hintStyle: labText(14, c: ItlgColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        LabPrimaryButton(
          icon: 'check',
          label: 'Simpan Perubahan',
          large: true,
          onTap: _save,
        ),
      ],
    );
  }
}

enum _StepState { done, active, idle }

class _Step extends StatelessWidget {
  final _StepState state;
  final String title;
  final String caption;

  const _Step({
    required this.state,
    required this.title,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    Widget dot;
    switch (state) {
      case _StepState.done:
        dot = const LabStatusDot(
            size: 28, color: LabColors.green, icon: 'check');
        break;
      case _StepState.active:
        dot = const LabStatusDot(
            size: 28, color: ItlgColors.primary, icon: 'wrench_outline');
        break;
      case _StepState.idle:
        dot = const InnerShadowBox(
          width: 28,
          height: 28,
          radius: 14,
          color: LabColors.tile,
          shadows: LabShadows.track,
        );
        break;
    }
    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(key: ValueKey<_StepState>(state), child: dot),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LabColumn(
            gap: 2,
            children: [
              Text(
                title,
                style: labText(
                  12,
                  w: kBold,
                  c: state == _StepState.idle
                      ? ItlgColors.textSubtle
                      : ItlgColors.text,
                ),
              ),
              Text(caption,
                  style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
            ],
          ),
        ),
      ],
    );
  }
}
