import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/praktikan_store.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../../shared/lab_actions.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';
import '../widgets/aslab_ui.dart';

/// Halaman Detail Presensi Pertemuan Asisten Lab.
class AslabDetailPresensiPage extends StatefulWidget {
  final AslabNav nav;
  final String courseId;
  final int meetingNumber;
  const AslabDetailPresensiPage({
    super.key,
    required this.nav,
    this.courseId = 'pemob',
    this.meetingNumber = 4,
  });

  @override
  State<AslabDetailPresensiPage> createState() =>
      _AslabDetailPresensiPageState();
}

class _AslabDetailPresensiPageState extends State<AslabDetailPresensiPage> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  /// Filter status: 0 Semua, lalu 1 + indeks [AslabAttend].
  int _status = 0;

  Future<void> _openFilter() async {
    final i = await prakShowPicker(
      context,
      title: 'Filter Status Kehadiran',
      options: const ['Semua', 'Hadir', 'Izin', 'Alpa'],
      selected: _status,
    );
    if (i != null && mounted) setState(() => _status = i);
  }

  /// Status awal (untuk tanda "Diubah dari..." dan tombol Simpan).
  final List<AslabAttend> _initial = [];
  final List<AslabPresence> _list = [];

  @override
  void initState() {
    super.initState();
    _syncLiveRecordsIntoList();
    PresensiSyncService.instance.addListener(_onPresensiSync);
  }

  void _onPresensiSync() {
    _syncLiveRecordsIntoList();
    if (mounted) setState(() {});
  }

  void _syncLiveRecordsIntoList() {
    final records = PresensiSyncService.instance.recordsForMeeting(
      widget.courseId,
      widget.meetingNumber,
    );
    for (final r in records) {
      final idx = _list.indexWhere((p) => p.student.nim == r.userIdentifier);
      final mappedStatus = switch (r.status) {
        PrakAttend.izin || PrakAttend.pending => AslabAttend.izin,
        PrakAttend.alpa => AslabAttend.alpa,
        _ => AslabAttend.hadir,
      };
      final clock =
          '${r.recordedAt.toLocal().hour.toString().padLeft(2, '0')}:${r.recordedAt.toLocal().minute.toString().padLeft(2, '0')}';
      final methodLabel = r.method == 'qr'
          ? 'Pindai QR • $clock'
          : (r.method == 'manual'
              ? 'Diubah manual oleh asisten'
              : 'Tombol + Lokasi • $clock');
      final proofList = <(String, String)>[
        (r.method == 'qr' ? 'qrcode' : 'location', methodLabel),
        if (r.hasSignature) ('signature_freehand', 'Bertanda tangan'),
      ];
      if (idx != -1) {
        // Jangan timpa perubahan yang sedang dibuat asisten.
        if (_list[idx].status == _initial[idx]) {
          _list[idx].status = mappedStatus;
        }
        _initial[idx] = mappedStatus;
      } else {
        final parts = r.userName.trim().split(RegExp(r'\s+'));
        final initials = parts.length >= 2
            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
            : (r.userName.isNotEmpty
                ? r.userName.substring(0, 1).toUpperCase()
                : 'PR');
        _list.insert(
          0,
          AslabPresence(
            AslabStudent(initials, r.userName, r.userIdentifier),
            mappedStatus,
            proof: proofList,
            proofLink: true,
          ),
        );
        _initial.insert(0, mappedStatus);
      }
    }
  }

  @override
  void dispose() {
    PresensiSyncService.instance.removeListener(_onPresensiSync);
    _search.dispose();
    super.dispose();
  }

  int _count(AslabAttend a) => _list.where((p) => p.status == a).length;

  Future<void> _simpan() async {
    // Simpan hanya yang diubah agar metode (QR/Lokasi) & tanda tangan
    final changed = [
      for (var i = 0; i < _list.length; i++)
        if (_list[i].status != _initial[i]) _list[i],
    ];
    if (changed.isEmpty) {
      labToast(context, 'Belum ada status yang diubah');
      return;
    }
    try {
      await PresensiSyncService.instance.saveManualStatuses(
        courseId: widget.courseId,
        meetingNumber: widget.meetingNumber,
        presences: changed,
        updatedBy: AuthController.instance.userName,
      );
    } on StateError catch (e) {
      if (!mounted) return;
      labToast(context, e.message);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).maybePop();
    labToast(
      context,
      'Perubahan presensi Pertemuan ${widget.meetingNumber} disimpan',
    );
  }

  @override
  Widget build(BuildContext context) {
    final course = PraktikumSyncService.instance.courseById(widget.courseId);
    final classShort = course.kelas.contains(' - ')
        ? course.kelas.split(' - ').last
        : course.kelas;
    final meetingObj = course.meetings.firstWhere(
      (m) => m.number == widget.meetingNumber,
      orElse: () => course.meetings.first,
    );
    final dateShort = meetingObj.date.split(' • ').first;
    final q = _query.trim().toLowerCase();
    final items = [
      for (var i = 0; i < _list.length; i++)
        if ((_status == 0 ||
                _list[i].status == AslabAttend.values[_status - 1]) &&
            (q.isEmpty ||
                _list[i].student.name.toLowerCase().contains(q) ||
                _list[i].student.nim.contains(q)))
          i,
    ];
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            ListenableBuilder(
              listenable: PresensiSyncService.instance,
              builder: (_, __) {
                final active = PresensiSyncService.instance.activeSession;
                final live = active.courseId == widget.courseId &&
                    active.meetingNumber == widget.meetingNumber &&
                    active.isActive;
                return PrakSpaceRow(
                  left: live
                      ? const LabChip.live('Sesi Berlangsung')
                      : const LabChip.idle('Sesi Ditutup'),
                  right: LabMeta(icon: 'calendar', text: dateShort),
                );
              },
            ),
            LabOverline(
              overline: 'Praktikum ${course.name} • $classShort',
              title: 'Presensi\nPertemuan ${widget.meetingNumber}',
            ),
            AslabRekap(
              hadir: _count(AslabAttend.hadir),
              izin: _count(AslabAttend.izin),
              alpa: _count(AslabAttend.alpa),
            ),
          ],
        ),
        const PrakNotice.info(
          icon: 'info',
          text: 'Ubah status dengan memilih salah satu kotak. Setiap '
              'perubahan tercatat atas nama anda.',
        ),
        PrakSearchField(
          hint: 'Cari nama atau NIM praktikan...',
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          onFilter: _openFilter,
          filterActive: _status != 0,
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Tidak ada praktikan dengan filter ini.',
                textAlign: TextAlign.center,
                style: labText(12, c: ItlgColors.textSubtle)),
          ),
        LabColumn(
          gap: 10,
          children: [
            for (final i in items)
              _StudentCard(
                izinFolder: 'izin/${widget.courseId}/m${widget.meetingNumber}',
                presence: _list[i],
                changedFrom: _list[i].status != _initial[i]
                    ? _initial[i]
                    : null,
                onStatus: (v) =>
                    setState(() => _list[i].status = AslabAttend.values[v]),
                onProof: () => widget.nav.buktiPresensi(
                  context,
                  presence: _list[i],
                  courseId: widget.courseId,
                  meetingNumber: widget.meetingNumber,
                ),
              ),
          ],
        ),
        LabPrimaryButton(
          icon: 'check',
          label: 'Simpan Perubahan',
          large: true,
          onTap: _simpan,
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  final AslabPresence presence;
  final AslabAttend? changedFrom;
  final ValueChanged<int> onStatus;
  final VoidCallback onProof;

  /// Folder Storage tempat lampiran izin diunggah praktikan.
  final String izinFolder;

  const _StudentCard({
    required this.presence,
    required this.changedFrom,
    required this.onStatus,
    required this.onProof,
    required this.izinFolder,
  });

  static const List<String> _names = ['Hadir', 'Izin', 'Alpa'];

  @override
  Widget build(BuildContext context) {
    final p = presence;
    final tag = changedFrom != null
        ? 'Diubah dari ${_names[changedFrom!.index]}'
        : p.changedTag;
    final izin = p.izin;
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
          Row(
            children: [
              LabAvatar(p.student.initials),
              const SizedBox(width: 10),
              Expanded(
                child: LabColumn(
                  gap: 2,
                  children: [
                    Text(p.student.name, style: labText(14, w: kBold)),
                    Text(p.student.nim,
                        style: labText(11,
                            w: kMedium, c: ItlgColors.textSubtle)),
                  ],
                ),
              ),
              if (tag != null) ...[
                const SizedBox(width: 8),
                LabTag.blue(tag),
              ],
            ],
          ),
          if (p.proof.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onProof,
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        for (final m in p.proof)
                          LabMeta(icon: m.$1, text: m.$2),
                      ],
                    ),
                  ),
                  if (p.proofLink) ...[
                    const SizedBox(width: 8),
                    Text('Lihat Bukti',
                        style: labText(12, c: ItlgColors.primary)),
                  ],
                ],
              ),
            ),
          AslabStatusPicker(value: p.status.index, onChanged: onStatus),
          if (izin != null)
            InnerShadowBox(
              radius: 12,
              color: ItlgColors.surfaceDark,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: LabColumn(
                gap: 6,
                children: [
                  Text(izin.$1, style: labText(12, w: kBold)),
                  Text(izin.$2,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                  Row(
                    children: [
                      Flexible(
                        child: AslabFilePill(
                            icon: 'attach', text: izin.$3, raised: true),
                      ),
                      const SizedBox(width: 8),
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => labShowFilePreview(
                          context,
                          name: izin.$3,
                          source: 'Lampiran izin praktikan',
                          searchFolders: [izinFolder],
                        ),
                        child: Text('Lihat Lampiran',
                            style: labText(12, c: ItlgColors.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
