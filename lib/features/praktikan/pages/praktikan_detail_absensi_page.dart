import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Detail Absensi-Praktikan".
class PraktikanDetailAbsensiPage extends StatefulWidget {
  final PraktikanNav nav;
  final PrakCourse course;

  const PraktikanDetailAbsensiPage({
    super.key,
    required this.nav,
    required this.course,
  });

  @override
  State<PraktikanDetailAbsensiPage> createState() =>
      _PraktikanDetailAbsensiPageState();
}

class _PraktikanDetailAbsensiPageState
    extends State<PraktikanDetailAbsensiPage> {
  /// 0 Semua, 1 Hadir, 2 Izin, 3 Alpa.
  int _tab = 0;

  bool _match(PrakMeeting m) {
    switch (_tab) {
      case 1:
        return m.status == PrakAttend.hadir;
      case 2:
        return m.status == PrakAttend.izin || m.status == PrakAttend.pending;
      case 3:
        return false; // Belum ada pertemuan alpa.
      default:
        return true;
    }
  }

  void _ajukanIzin(PrakMeeting m) {
    widget.nav.ajukanIzin(context, widget.course, m).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final items = c.meetings.where(_match).toList();
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            LabColumn(
              gap: 6,
              children: [
                Text(c.kelas,
                    style: labText(16, w: kBold, c: ItlgColors.primaryDark)),
                Text('Praktikum\n${c.name}',
                    style: labText(22, w: kBold, c: Colors.black)),
              ],
            ),
            LabStatRow(
              stats: [
                LabStat(icon: 'check', label: 'Hadir', value: '${c.hadir}'),
                LabStat(icon: 'file', label: 'Izin', value: '${c.izin}'),
                LabStat(icon: 'cross', label: 'Alpa', value: '${c.alpa}'),
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
        LabColumn(
          gap: 16,
          children: [
            for (final m in items)
              _MeetingCard(meeting: m, onIzin: () => _ajukanIzin(m)),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Tidak ada pertemuan.',
                    textAlign: TextAlign.center,
                    style: labText(12, c: ItlgColors.textSubtle)),
              ),
          ],
        ),
      ],
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final PrakMeeting meeting;
  final VoidCallback onIzin;
  const _MeetingCard({required this.meeting, required this.onIzin});

  Widget _chip() {
    switch (meeting.status) {
      case PrakAttend.upcoming:
        return const LabChip.idle('Akan Datang');
      case PrakAttend.hadir:
        return const LabChip.live('Hadir');
      case PrakAttend.izin:
        return const LabChip.info('Izin Sakit');
      case PrakAttend.pending:
        return const LabChip.warn('Izin Diajukan');
    }
  }

  Widget? _extra() {
    switch (meeting.status) {
      case PrakAttend.upcoming:
        return LabOutlineButton(
          icon: 'file',
          label: 'Ajukan Izin Pertemuan ${meeting.number}',
          onTap: onIzin,
        );
      case PrakAttend.hadir:
        return LabMeta(
          icon: meeting.noteIcon ?? 'qrcode',
          text: meeting.note ?? '',
          color: LabColors.green,
        );
      case PrakAttend.izin:
        return LabInsetBox(
          child: Row(
            children: [
              Expanded(
                child: Text('Izin disetujui asisten',
                    style: labText(12, w: kBold)),
              ),
              const SizedBox(width: 8),
              InnerShadowBox(
                radius: 12,
                color: ItlgColors.surfaceDark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LabIcon('attach',
                        size: 12, color: ItlgColors.primary),
                    const SizedBox(width: 6),
                    Text(meeting.izinFile ?? '',
                        style: labText(11, w: kMedium)),
                  ],
                ),
              ),
            ],
          ),
        );
      case PrakAttend.pending:
        return const LabMeta(
          icon: 'clock',
          text: 'Pengajuan izin sedang diperiksa asisten',
          color: LabColors.warnText,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final extra = _extra();
    return LabCard(
      gap: 12,
      children: [
        Row(
          children: [
            PrakNumberTile('${meeting.number}'),
            const SizedBox(width: 10),
            Expanded(
              child: LabColumn(
                gap: 2,
                children: [
                  Text('Pertemuan ${meeting.number}',
                      style: labText(14, w: kBold)),
                  Text(meeting.module,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _chip(),
          ],
        ),
        LabMeta(icon: 'calendar', text: meeting.date),
        if (extra != null) extra,
      ],
    );
  }
}
