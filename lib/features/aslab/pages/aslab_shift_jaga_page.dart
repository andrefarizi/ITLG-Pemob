import 'package:flutter/material.dart';

import '../../../core/services/device_calendar_service.dart';
import '../../../core/services/jadwal_sync_service.dart';
import '../../../core/services/shift_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../widgets/aslab_ui.dart';
import 'aslab_pindai_qr_laboran_page.dart';

/// Figma: "Jadwal Mengajar-Aslab" (5497:1743).
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

  final ShiftSyncService _shiftSync = ShiftSyncService.instance;
  final JadwalSyncService _jadwalSync = JadwalSyncService.instance;
  int _day = 0;

  @override
  void initState() {
    super.initState();
    _shiftSync.refreshFromBackend();
  }

  Future<void> _syncCalendar() async {
    final res = await DeviceCalendarService.instance.syncSchedules(
      _jadwalSync.schedules,
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

  Future<void> _answer(ShiftSwapRecord swap, bool accept) async {
    widget.nav.store.swapAnswer = accept;
    await _shiftSync.decideSwap(
      swapCode: swap.swapCode,
      accept: accept,
      decidedByName: AuthController.instance.userName,
    );
    if (!mounted) return;
    labToast(
      context,
      accept
          ? 'Tukar shift dengan ${swap.requesterName} diterima & jadwal diperbarui'
          : 'Permintaan tukar shift dari ${swap.requesterName} ditolak',
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = widget.nav;
    return ListenableBuilder(
      listenable: Listenable.merge([_shiftSync, _jadwalSync]),
      builder: (context, _) {
        final dayShifts = _shiftSync.shiftsForDay(_day);
        final featuredSwap = _shiftSync.featuredIncomingSwap;
        final pendingCount = _shiftSync.pendingSwapCount;

        final myShiftToday = _shiftSync.allShifts.firstWhere(
          (s) => s.asistenName == AuthController.instance.userName,
          orElse: () => _shiftSync.allShifts.first,
        );
        final checkedIn = myShiftToday.attendanceStatus == 'Hadir';

        return LabSubPage(
          onLogoTap: nav.home,
          children: [
            const LabTitle(
              title: 'Jadwal Mengajar',
              subtitle: 'Kalender jadwal mengajar praktikum anda',
            ),
            LabCard(
              gap: 12,
              children: [
                PrakSpaceRow(
                  left: const LabSectionTitle(
                      icon: 'qrcode', text: 'Presensi Mengajar Hari Ini'),
                  right: checkedIn
                      ? const LabChip.live('Sudah Check-In')
                      : const LabChip.warn('Belum Check-In'),
                ),
                Text(
                  '${myShiftToday.dayLabel} • ${myShiftToday.shiftLabel} • ${myShiftToday.timeRange}',
                  style: labText(13, w: kBold),
                ),
                LabMeta(
                  icon: 'location',
                  text: '${myShiftToday.room} • check-in dibuka 07:45',
                ),
                LabButtonPair(
                  left: LabOutlineButton(
                    icon: 'key',
                    label: 'Masukkan Kode',
                    onTap: () => showAslabCheckInCodeSheet(context),
                  ),
                  right: LabPrimaryButton(
                    icon: 'qrcode',
                    label: 'Pindai QR Laboran',
                    onTap: () => labPush(
                      context,
                      AslabPindaiQrLaboranPage(onLogoTap: nav.home),
                    ),
                  ),
                ),
              ],
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
            if (dayShifts.isNotEmpty)
              LabColumn(
                gap: 16,
                children: [
                  for (final s in dayShifts)
                    _ShiftCard(
                      shift: s.shiftLabel,
                      partner: s.partnerName.isNotEmpty
                          ? '${s.asistenName} • ${s.partnerName}'
                          : 'Bersama ${s.asistenName}',
                      course: s.courseName,
                      time: '${s.dayLabel} • ${s.timeRange}',
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
                child: Text('Tidak ada jadwal mengajar pada hari ini.',
                    textAlign: TextAlign.center,
                    style: labText(12, c: ItlgColors.textSubtle)),
              ),
            if (featuredSwap != null)
              LabCard(
                children: [
                  PrakSpaceRow(
                    left: const LabSectionTitle(
                        icon: 'arrow_right_left',
                        text: 'Permintaan Tukar Jadwal'),
                    right: featuredSwap.isPending
                        ? LabTag.red(
                            '${pendingCount > 0 ? pendingCount : 1} Baru')
                        : (featuredSwap.isApproved
                            ? const LabChip.live('Diterima')
                            : const LabChip.danger('Ditolak')),
                  ),
                  LabInsetBox(
                    child: LabColumn(
                      gap: 10,
                      children: [
                        LabPerson(
                          initials: featuredSwap.requesterInitials,
                          name: featuredSwap.requesterName,
                          caption: featuredSwap.reason.isNotEmpty
                              ? featuredSwap.reason
                              : 'Meminta bertukar jadwal dengan anda',
                        ),
                        AslabSwapRow(
                          left: (
                            'Jadwal ${featuredSwap.requesterFirstName}',
                            featuredSwap.fromShiftLabel
                          ),
                          right: (
                            'Jadwal ${featuredSwap.isIncoming ? 'Anda' : featuredSwap.targetFirstName}',
                            featuredSwap.toShiftLabel
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (featuredSwap.isPending)
                    LabButtonPair(
                      left: LabOutlineButton(
                        icon: 'cross',
                        label: 'Tolak',
                        onTap: () => _answer(featuredSwap, false),
                      ),
                      right: LabPrimaryButton(
                        icon: 'check',
                        label: 'Terima',
                        onTap: () => _answer(featuredSwap, true),
                      ),
                    ),
                ],
              ),
            LabColumn(
              gap: 12,
              children: [
                LabPrimaryButton(
                  icon: 'arrow_right_left',
                  label: 'Ajukan Tukar Jadwal',
                  large: true,
                  onTap: () => nav.ajukanTukarShift(context),
                ),
                LabOutlineButton(
                  icon: 'clock',
                  label: 'Riwayat Tukar Jadwal',
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
