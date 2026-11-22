import 'package:flutter/material.dart';

import '../../../core/services/device_calendar_service.dart';
import '../../../core/services/jadwal_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../widgets/aslab_ui.dart';

/// Figma: "Shift Jaga-Aslab".
class AslabShiftJagaPage extends StatefulWidget {
  final AslabNav nav;
  const AslabShiftJagaPage({super.key, required this.nav});

  @override
  State<AslabShiftJagaPage> createState() => _AslabShiftJagaPageState();
}

class _AslabShiftJagaPageState extends State<AslabShiftJagaPage> {
  static const List<(String, String, String)> _days = [
    ('Sen', '28', 'Sep'),
    ('Sel', '29', 'Sep'),
    ('Rab', '30', 'Sep'),
    ('Kam', '01', 'Okt'),
    ('Jum', '02', 'Okt'),
    ('Sab', '03', 'Okt'),
  ];

  int _day = 0;

  Future<void> _syncCalendar() async {
    final res = await DeviceCalendarService.instance.syncSchedules(
      JadwalSyncService.instance.schedules,
      askPermission: true,
    );
    if (!mounted) return;
    if (!res.permissionGranted) {
      labToast(context, 'Izin Kalender diperlukan untuk sinkron shift jaga');
    } else if (res.synced && res.count > 0) {
      labToast(
          context, '${res.count} jadwal shift tersinkron ke ${res.calendarName}');
    }
  }

  void _answer(bool accept) {
    setState(() => widget.nav.store.swapAnswer = accept);
    labToast(
      context,
      accept
          ? 'Tukar shift dengan Feri Gunawan diterima'
          : 'Permintaan tukar shift ditolak',
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = widget.nav;
    final answer = nav.store.swapAnswer;
    final jadwalSync = JadwalSyncService.instance;
    return ListenableBuilder(
      listenable: jadwalSync,
      builder: (context, _) {
        final daySchedules = jadwalSync.schedulesForDay(_day);
        return LabSubPage(
          onLogoTap: nav.home,
          children: [
            const LabTitle(
              title: 'Shift Jaga',
              subtitle: 'Kalender jadwal tugas jaga laboratorium anda',
            ),
            LabColumn(
              gap: 8,
              children: [
                PrakSpaceRow(
                  left: const LabHeading(
                      icon: 'calendar', text: 'September 2026'),
                  right: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _syncCalendar,
                    child: const LabPill(icon: 'calendar', text: 'Minggu ke-4'),
                  ),
                ),
                AslabDaySelector(
                  days: _days,
                  index: _day,
                  onChanged: (i) => setState(() => _day = i),
                ),
              ],
            ),
            if (daySchedules.isNotEmpty)
              LabColumn(
                gap: 16,
                children: [
                  for (final s in daySchedules)
                    _ShiftCard(
                      shift: int.tryParse(s.startTime.split(':').first) != null &&
                              int.parse(s.startTime.split(':').first) < 12
                          ? 'Shift Pagi'
                          : 'Shift Siang',
                      partner: 'Bersama ${s.asisten}',
                      course: 'Praktikum ${s.courseName}',
                      time: s.jadwalShort,
                      room: s.room,
                    ),
                ],
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                decoration: BoxDecoration(
                  color: ItlgColors.surfaceDark,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: ItlgShadows.outline,
                ),
                child: Text('Tidak ada shift jaga pada hari ini.',
                    textAlign: TextAlign.center,
                    style: labText(12, c: ItlgColors.textSubtle)),
              ),
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabSectionTitle(
                  icon: 'arrow_right_left', text: 'Permintaan Tukar Shift'),
              right: answer == null
                  ? const LabTag.red('1 Baru')
                  : (answer
                      ? const LabChip.live('Diterima')
                      : const LabChip.danger('Ditolak')),
            ),
            const LabInsetBox(
              child: LabColumn(
                gap: 10,
                children: [
                  LabPerson(
                    initials: 'FG',
                    name: 'Feri Gunawan',
                    caption: 'Meminta bertukar shift dengan anda',
                  ),
                  AslabSwapRow(
                    left: ('Shift Feri', 'Rab, 30 Sep • 13:00'),
                    right: ('Shift Anda', 'Kam, 01 Okt • 08:00'),
                  ),
                ],
              ),
            ),
            if (answer == null)
              LabButtonPair(
                left: LabOutlineButton(
                  icon: 'cross',
                  label: 'Tolak',
                  onTap: () => _answer(false),
                ),
                right: LabPrimaryButton(
                  icon: 'check',
                  label: 'Terima',
                  onTap: () => _answer(true),
                ),
              ),
          ],
        ),
        LabColumn(
          gap: 12,
          children: [
            LabPrimaryButton(
              icon: 'arrow_right_left',
              label: 'Ajukan Tukar Shift',
              large: true,
              onTap: () => nav.ajukanTukarShift(context),
            ),
            LabOutlineButton(
              icon: 'clock',
              label: 'Riwayat Tukar Shift',
              large: true,
              onTap: () => nav.riwayatTukarShift(context),
            ),
          ],
        ),
      ],
    );
      },
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final String shift;
  final String partner;
  final String course;
  final String time;
  final String room;

  const _ShiftCard({
    required this.shift,
    required this.partner,
    required this.course,
    required this.time,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return LabCard(
      children: [
        PrakSpaceRow(
          left: LabChip.info(shift),
          right: LabMeta(icon: 'people_group', text: partner),
        ),
        Text(course, style: labText(16, w: kBold, c: Colors.black)),
        Row(
          children: [
            Flexible(child: LabMeta(icon: 'clock', text: time)),
            const SizedBox(width: 24),
            Flexible(child: LabMeta(icon: 'location', text: room)),
          ],
        ),
      ],
    );
  }
}
