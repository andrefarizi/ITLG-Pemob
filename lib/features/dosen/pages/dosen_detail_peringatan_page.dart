import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../dosen_store.dart';
import '../widgets/dosen_ui.dart';
import 'dosen_peringatan_page.dart';

/// Figma: "Detail Peringatan-Dosen" (Yoga), "(Lia)", dan "(Bagas)".
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
  /// 0 Semua, 1 Hadir, 2 Izin, 3 Alpa.
  int _tab = 0;

  bool _match(DosenMeeting m) {
    switch (_tab) {
      case 1:
        return m.status == MeetingStatus.hadir ||
            m.status == MeetingStatus.terlambat;
      case 2:
        return m.status == MeetingStatus.izin;
      case 3:
        return m.status == MeetingStatus.alpa;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final shown = s.meetings.where(_match).toList();

    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      children: [
        const LabTitle(
          title: 'Detail Peringatan',
          subtitle: 'Ringkasan kehadiran dan nilai praktikan berisiko',
        ),
        DosenStudentCard(student: s),
        LabCard(
          children: [
            DosenClassTitle(kelas: s.kelas),
            LabStatRow(
              stats: [
                LabStat(icon: 'check', label: 'Hadir', value: '${s.hadir}'),
                LabStat(icon: 'file', label: 'Izin', value: '${s.izin}'),
                LabStat(icon: 'cross', label: 'Alpa', value: '${s.alpa}'),
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
  final DosenMeeting meeting;
  const _MeetingCard({required this.meeting});

  Widget _chip() {
    switch (meeting.status) {
      case MeetingStatus.upcoming:
        return const LabChip.idle('Akan Datang');
      case MeetingStatus.hadir:
        return const LabChip.live('Hadir');
      case MeetingStatus.terlambat:
        return const LabChip.warn('Terlambat');
      case MeetingStatus.izin:
        return const LabChip.info('Izin');
      case MeetingStatus.alpa:
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

  Color get _noteColor {
    switch (meeting.status) {
      case MeetingStatus.alpa:
        return ItlgColors.primary;
      case MeetingStatus.izin:
        return ItlgColors.secondary;
      case MeetingStatus.terlambat:
        return LabColors.warnText;
      default:
        return LabColors.green;
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
          LabMeta(icon: m.noteIcon!, text: m.note!, color: _noteColor),
      ],
    );
  }
}
