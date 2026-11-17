import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../dosen_store.dart';
import 'dosen_peringatan_page.dart';

enum _Attend { upcoming, alpa, hadir }

class _Meeting {
  final int number;
  final String module;
  final String date;
  final _Attend status;

  /// Chip "Alpa" pertemuan 4 di Figma memakai Bold + bayangan.
  final bool emphasis;
  final String? noteIcon;
  final String? note;
  final Color? noteColor;

  const _Meeting({
    required this.number,
    required this.module,
    required this.date,
    required this.status,
    this.emphasis = false,
    this.noteIcon,
    this.note,
    this.noteColor,
  });
}

/// Figma: "Detail Peringatan-Dosen".
class DosenDetailPeringatanPage extends StatefulWidget {
  final DosenStudent student;
  final VoidCallback? onLogoTap;

  const DosenDetailPeringatanPage({
    super.key,
    required this.student,
    this.onLogoTap,
  });

  @override
  State<DosenDetailPeringatanPage> createState() =>
      _DosenDetailPeringatanPageState();
}

class _DosenDetailPeringatanPageState extends State<DosenDetailPeringatanPage> {
  static const List<_Meeting> _meetings = [
    _Meeting(
      number: 5,
      module: 'Modul 5 • Navigasi & Routing',
      date: 'Sen, 05 Okt 2026 • 08:00–09:40 WIB',
      status: _Attend.upcoming,
    ),
    _Meeting(
      number: 4,
      module: 'Modul 4 • State Management',
      date: 'Sen, 28 Sep 2026 • 08:00–09:40 WIB',
      status: _Attend.alpa,
      emphasis: true,
      noteIcon: 'cross',
      note: 'Tidak ada presensi tercatat',
      noteColor: ItlgColors.primary,
    ),
    _Meeting(
      number: 3,
      module: 'Modul 3 • Layout & Navigasi',
      date: 'Sen, 21 Sep 2026 • 08:00–09:40 WIB',
      status: _Attend.hadir,
      noteIcon: 'location',
      note: 'Tercatat 08:01 WIB melalui tombol hadir & lokasi',
      noteColor: LabColors.green,
    ),
    _Meeting(
      number: 2,
      module: 'Modul 2 • Widget Dasar',
      date: 'Sen, 14 Sep 2026 • 08:00–09:40 WIB',
      status: _Attend.alpa,
    ),
    _Meeting(
      number: 1,
      module: 'Modul 1 • Pengenalan Flutter',
      date: 'Sen, 07 Sep 2026 • 08:00–09:40 WIB',
      status: _Attend.hadir,
      noteIcon: 'qrcode',
      note: 'Tercatat 07:58 WIB melalui pindai QR',
      noteColor: LabColors.green,
    ),
  ];

  /// 0 Semua, 1 Hadir, 2 Izin, 3 Alpa.
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final shown = _meetings.where((m) {
      switch (_tab) {
        case 1:
          return m.status == _Attend.hadir;
        case 2:
          return false; // tidak ada izin pada data contoh
        case 3:
          return m.status == _Attend.alpa;
        default:
          return true;
      }
    }).toList();

    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      children: [
        const LabTitle(
          title: 'Detail Peringatan',
          subtitle: 'Ringkasan kehadiran dan nilai praktikan berisiko',
        ),
        DosenStudentCard(student: widget.student),
        LabCard(
          children: [
            LabColumn(
              gap: 6,
              children: [
                Text('TIF 3001 - ${widget.student.kelas}',
                    style: labText(16, w: kBold, c: ItlgColors.primaryDark)),
                Text('Praktikum\nPemrograman Mobile',
                    style: labText(22, w: kBold, c: Colors.black)),
              ],
            ),
            const LabStatRow(
              stats: [
                LabStat(icon: 'check', label: 'Hadir', value: '2'),
                LabStat(icon: 'file', label: 'Izin', value: '0'),
                LabStat(icon: 'cross', label: 'Alpa', value: '2'),
              ],
            ),
            const LabProgress(
              label: 'Pertemuan terlaksana',
              value: '4 / 12',
              fraction: 113 / 338,
            ),
          ],
        ),
        LabTabs(
          labels: const ['Semua', 'Hadir', 'Izin', 'Alpa'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Tidak ada pertemuan dengan status ini.',
              textAlign: TextAlign.center,
              style: labText(12, c: ItlgColors.textSubtle),
            ),
          )
        else
          LabColumn(
            gap: 16,
            children: [for (final m in shown) _MeetingCard(meeting: m)],
          ),
      ],
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final _Meeting meeting;
  const _MeetingCard({required this.meeting});

  Widget _chip() {
    switch (meeting.status) {
      case _Attend.upcoming:
        return const LabChip.idle('Akan Datang');
      case _Attend.hadir:
        return const LabChip.live('Hadir');
      case _Attend.alpa:
        return meeting.emphasis
            ? const LabChip(
                'Alpa',
                bg: LabColors.tagRedBg,
                fg: ItlgColors.primary,
                weight: kBold,
                shadow: true,
              )
            : const LabChip.danger('Alpa');
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = meeting;
    return LabCard(
      gap: 12,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ItlgColors.primary,
                borderRadius: BorderRadius.circular(9),
                boxShadow: LabShadows.neu,
              ),
              child: Text('${m.number}',
                  style: labText(16, w: kBold, c: Colors.white)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LabColumn(
                gap: 2,
                children: [
                  Text('Pertemuan ${m.number}', style: labText(14, w: kBold)),
                  Text(m.module,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _chip(),
          ],
        ),
        LabMeta(icon: 'calendar', text: m.date),
        if (m.note != null)
          LabMeta(icon: m.noteIcon!, text: m.note!, color: m.noteColor!),
      ],
    );
  }
}
