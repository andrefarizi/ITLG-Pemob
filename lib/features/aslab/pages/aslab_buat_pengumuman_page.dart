import 'package:flutter/material.dart';

import '../../../core/services/jadwal_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/laboran_store.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';

/// Halaman Buat Pengumuman Asisten Lab.
class AslabBuatPengumumanPage extends StatefulWidget {
  final AslabNav nav;
  const AslabBuatPengumumanPage({super.key, required this.nav});

  @override
  State<AslabBuatPengumumanPage> createState() =>
      _AslabBuatPengumumanPageState();
}

class _AslabBuatPengumumanPageState extends State<AslabBuatPengumumanPage> {
  static const List<(String, String)> _kategori = [
    ('calendar', 'Perubahan Jadwal'),
    ('info', 'Umum'),
    ('triangle_alert', 'Penting'),
  ];
  static const List<String> _hari = [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min',
  ];
  static const List<String> _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  static const List<(String, String)> _slots = [
    ('08:00', '09:40'),
    ('10:00', '11:40'),
    ('13:00', '14:40'),
    ('15:00', '16:40'),
  ];

  /// Pilihan jadwal pengganti: 14 hari ke depan (Senin–Sabtu) × 4 slot
  late final List<(int, String, String, String)> _jadwalOptions = () {
    final out = <(int, String, String, String)>[];
    final today = DateTime.now();
    for (var i = 1; i <= 14; i++) {
      final d = DateTime(today.year, today.month, today.day + i);
      if (d.weekday == DateTime.sunday) continue;
      final label =
          '${_hari[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')} ${_bulan[d.month - 1]} ${d.year}';
      for (final sl in _slots) {
        out.add((d.weekday - 1, sl.$1, sl.$2,
            '$label • ${sl.$1}–${sl.$2} (1j 40m)'));
      }
    }
    return out;
  }();
  static const List<String> _ruang = [
    'Lab Jaringan 1',
    'Lab Jaringan 2',
    'Lab Jaringan 3',
    'Lab Jaringan 4',
  ];

  final TextEditingController _judul = TextEditingController();
  final TextEditingController _isi = TextEditingController();
  int _kat = 1; // bawaan "Umum": ubah jadwal harus dipilih dengan sadar
  bool _sending = false;
  int _to = 0;
  int _jd = 0;
  int _rg = 0;

  List<String> get _tujuan {
    final scheds = JadwalSyncService.instance.schedules;
    return [
      for (final s in scheds)
        '${s.courseName} • Kom C (${s.sessionShort} • ${s.dayShort} ${s.startTime}–${s.endTime})',
      'Semua praktikan Kom C (C1 & C2)',
    ];
  }

  @override
  void dispose() {
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  Future<void> _pick(String title, List<String> options, int current,
      ValueChanged<int> onPicked) async {
    final i = await prakShowPicker(context,
        title: title, options: options, selected: current);
    if (i != null && mounted) setState(() => onPicked(i));
  }

  Future<void> _kirim() async {
    if (_sending) return;
    final judul = _judul.text.trim();
    final isi = _isi.text.trim();
    if (judul.length < 5) {
      labToast(context, 'Isi judul pengumuman (minimal 5 karakter)');
      return;
    }
    if (isi.length < 10) {
      labToast(context, 'Tulis isi pengumuman (minimal 10 karakter)');
      return;
    }
    final scheds = JadwalSyncService.instance.schedules;
    final targetSched = _to < scheds.length ? scheds[_to] : null;
    if (_kat == 0 && targetSched == null) {
      labToast(context, 'Pilih praktikum yang jadwalnya diubah');
      return;
    }
    final courseId = targetSched?.courseId;
    final sched = _jadwalOptions[_jd];
    setState(() => _sending = true);
    try {
      await JadwalSyncService.instance.publishAnnouncementAndSchedule(
        courseId: courseId,
        scheduleId: targetSched?.id,
        categoryIndex: _kat,
        title: judul,
        body: isi,
        author: AuthController.instance.userName,
        newDayIndex: _kat == 0 ? sched.$1 : null,
        newStartTime: _kat == 0 ? sched.$2 : null,
        newEndTime: _kat == 0 ? sched.$3 : null,
        newScheduleLabel: _kat == 0 ? sched.$4 : null,
        newRoom: _kat == 0 ? _ruang[_rg] : null,
      );
    } on StateError catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        labToast(context, e.message);
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).maybePop();
    labToast(
      context,
      _kat == 0
          ? 'Jadwal diperbarui & pengumuman terkirim ke praktikan'
          : 'Pengumuman terkirim ke praktikan',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tujuanList = _tujuan;
    final jadwalLabels = [for (final j in _jadwalOptions) j.$4];
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            const LabOverline(
              overline: 'Pengumuman & Perubahan Jadwal',
              title: 'Buat Pengumuman',
            ),
            Text(
              'Praktikan menerima notifikasi begitu pengumuman dikirim.',
              style: labText(12, c: ItlgColors.textMuted),
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(
                  icon: 'bullhorn_outline', text: 'Isi Pengumuman'),
            ),
            PrakField(
              label: 'Kategori',
              child: PrakOptionChips(
                options: _kategori,
                index: _kat,
                onChanged: (i) => setState(() => _kat = i),
              ),
            ),
            PrakField(
              label: 'Ditujukan Kepada',
              child: PrakSelect(
                value: tujuanList[_to.clamp(0, tujuanList.length - 1)],
                onTap: () => _pick(
                    'Ditujukan Kepada', tujuanList, _to, (i) => _to = i),
              ),
            ),
            PrakField(label: 'Judul', child: PrakInput(controller: _judul)),
            PrakField(
              label: 'Isi Pengumuman :',
              child: PrakTextArea(controller: _isi, height: 96),
            ),
            if (_kat == 0) ...[
              PrakField(
                label: 'Jadwal Baru',
                child: PrakSelect(
                  value: jadwalLabels[_jd],
                  onTap: () =>
                      _pick('Jadwal Baru', jadwalLabels, _jd, (i) => _jd = i),
                ),
              ),
              PrakField(
                label: 'Ruangan',
                child: PrakSelect(
                  value: _ruang[_rg],
                  onTap: () => _pick('Ruangan', _ruang, _rg, (i) => _rg = i),
                ),
              ),
            ],
          ],
        ),
        LabPrimaryButton(
          icon: 'send',
          label: 'Kirim Pengumuman',
          large: true,
          onTap: _kirim,
        ),
        // Kartu "Status Peminjaman Ruangan"
        ListenableBuilder(
          listenable: JadwalSyncService.instance,
          builder: (_, __) {
            final reqs = JadwalSyncService.instance.roomRequests;
            if (reqs.isEmpty) return const SizedBox.shrink();
            return LabCard(
              gap: 12,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: LabSectionTitle(
                      icon: 'door', text: 'Status Peminjaman Ruangan'),
                ),
                for (final r in reqs.take(4))
                  LabRowCard(
                    gap: 8,
                    padding: const EdgeInsets.all(12),
                    children: [
                      PrakSpaceRow(
                        left: Text(
                          '${r.labName} • ${r.title.split('•').first.trim()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: labText(12, w: kBold),
                        ),
                        right: r.status == RoomStatus.disetujui
                            ? const LabChip.live('Disetujui')
                            : (r.status == RoomStatus.ditolak
                                ? const LabChip.danger('Ditolak')
                                : const LabChip.warn('Menunggu')),
                      ),
                      LabMeta(
                        icon: 'clock',
                        text: '${r.dateLabel} • ${r.timeRange}',
                      ),
                      if (r.status == RoomStatus.ditolak &&
                          (r.rejectionNote?.isNotEmpty ?? r.reason.isNotEmpty))
                        Text(
                          'Catatan Laboran (Ditolak): ${r.rejectionNote ?? r.reason}',
                          style: labText(11, c: ItlgColors.primary),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
