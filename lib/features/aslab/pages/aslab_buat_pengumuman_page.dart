import 'package:flutter/material.dart';

import '../../../core/services/jadwal_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';

/// Figma: "Buat Pengumuman-Aslab".
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
  static const List<(int, String, String, String)> _jadwalOptions = [
    (0, '08:00', '09:40', 'Sen, 28 Sep 2026 • 08:00–09:40 (1j 40m)'),
    (0, '10:00', '11:40', 'Sen, 28 Sep 2026 • 10:00–11:40 (1j 40m)'),
    (1, '08:00', '09:40', 'Sel, 29 Sep 2026 • 08:00–09:40 (1j 40m)'),
    (1, '10:00', '11:40', 'Sel, 29 Sep 2026 • 10:00–11:40 (1j 40m)'),
    (2, '10:00', '11:40', 'Rab, 30 Sep 2026 • 10:00–11:40 (1j 40m)'),
    (2, '13:00', '14:40', 'Rab, 30 Sep 2026 • 13:00–14:40 (1j 40m)'),
    (3, '13:00', '14:40', 'Kam, 01 Okt 2026 • 13:00–14:40 (1j 40m)'),
    (3, '15:00', '16:40', 'Kam, 01 Okt 2026 • 15:00–16:40 (1j 40m)'),
    (4, '08:00', '09:40', 'Jum, 02 Okt 2026 • 08:00–09:40 (1j 40m)'),
    (5, '10:00', '11:40', 'Sab, 03 Okt 2026 • 10:00–11:40 (1j 40m)'),
  ];
  static const List<String> _ruang = [
    'Lab Komputer 1',
    'Lab Jaringan 2',
    'Lab Jaringan 1',
    'Lab AI & Data',
  ];

  final TextEditingController _judul =
      TextEditingController(text: 'Praktikum pengganti Pertemuan 4');
  final TextEditingController _isi = TextEditingController(
      text: 'Pertemuan dipindahkan karena bertepatan dengan kegiatan lab. '
          'Mohon hadir sesuai jadwal baru.');
  int _kat = 0;
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
    final scheds = JadwalSyncService.instance.schedules;
    final targetSched = _to < scheds.length ? scheds[_to] : null;
    final courseId = targetSched?.courseId;
    final sched = _jadwalOptions[_jd];
    await JadwalSyncService.instance.publishAnnouncementAndSchedule(
      courseId: courseId,
      scheduleId: targetSched?.id,
      categoryIndex: _kat,
      title: _judul.text.trim().isEmpty
          ? 'Pengumuman Praktikum'
          : _judul.text.trim(),
      body: _isi.text.trim(),
      author: AuthController.instance.userName,
      newDayIndex: _kat == 0 ? sched.$1 : null,
      newStartTime: _kat == 0 ? sched.$2 : null,
      newEndTime: _kat == 0 ? sched.$3 : null,
      newScheduleLabel: _kat == 0 ? sched.$4 : null,
      newRoom: _kat == 0 ? _ruang[_rg] : null,
    );
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
      ],
    );
  }
}
