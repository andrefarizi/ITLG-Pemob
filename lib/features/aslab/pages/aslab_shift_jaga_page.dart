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

/// Halaman Jadwal Mengajar Asisten Lab.
class AslabShiftJagaPage extends StatefulWidget {
  final AslabNav nav;
  const AslabShiftJagaPage({super.key, required this.nav});

  @override
  State<AslabShiftJagaPage> createState() => _AslabShiftJagaPageState();
}

class _AslabShiftJagaPageState extends State<AslabShiftJagaPage> {
  static const List<String> _hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
  static const List<String> _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  static const List<String> _bulanPanjang = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli',
    'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  /// Senin minggu berjalan (hari Minggu → minggu berikutnya). Shift bersifat
  /// mingguan (`day_index`), jadi tanggal dihitung dari minggu ini, bukan
  /// label tetap "Sen, 28 Sep" dari data.
  static DateTime get _weekMonday {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final today = DateTime(now.year, now.month, now.day);
    if (today.weekday == DateTime.sunday) {
      return today.add(const Duration(days: 1));
    }
    return today.subtract(Duration(days: today.weekday - 1));
  }

  static DateTime _dateFor(int dayIndex) =>
      _weekMonday.add(Duration(days: dayIndex.clamp(0, 5)));

  static String _dayLabel(int dayIndex) {
    final d = _dateFor(dayIndex);
    return '${_hari[dayIndex.clamp(0, 5)]}, ${d.day.toString().padLeft(2, '0')} ${_bulan[d.month - 1]}';
  }

  static List<(String, String, String)> get _days => [
        for (var i = 0; i < 6; i++)
          (
            _hari[i],
            _dateFor(i).day.toString().padLeft(2, '0'),
            _bulan[_dateFor(i).month - 1],
          ),
      ];

  static int get _todayIndex {
    final wd = DateTime.now().toUtc().add(const Duration(hours: 7)).weekday;
    return wd == DateTime.sunday ? 0 : wd - 1;
  }

  final ShiftSyncService _shiftSync = ShiftSyncService.instance;
  final JadwalSyncService _jadwalSync = JadwalSyncService.instance;
  int _day = _todayIndex;

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
    // Menerima menukar penugasan shift nyata: minta konfirmasi dulu.
    final ok = await labShowConfirmDialog(
      context,
      icon: accept ? 'check' : 'cross',
      title: accept ? 'Terima Tukar Jadwal?' : 'Tolak Tukar Jadwal?',
      message: accept
          ? 'Shift anda dan ${swap.requesterName} akan langsung ditukar.'
          : 'Permintaan dari ${swap.requesterName} akan ditolak.',
      confirmLabel: accept ? 'Terima' : 'Tolak',
    );
    if (!ok || !mounted) return;
    try {
      await _shiftSync.decideSwap(
        swapCode: swap.swapCode,
        accept: accept,
        decidedByName: AuthController.instance.userName,
      );
    } on StateError catch (e) {
      if (mounted) labToast(context, e.message);
      return;
    }
    widget.nav.store.swapAnswer = accept;
    if (!mounted) return;
    await labShowResult(
      context,
      icon: accept ? 'circle_check' : 'person_cross',
      title: accept ? 'Tukar Jadwal Diterima' : 'Permintaan Ditolak',
      message: accept
          ? 'Jadwal mengajar kamu sudah diperbarui dan pemohon akan menerima notifikasi.'
          : 'Pemohon akan menerima notifikasi bahwa permintaannya ditolak.',
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

        // Shift milik Aslab yang login pada HARI INI saja.
        final me = AuthController.instance.userName;
        final myShiftToday = _shiftSync.allShifts
            .where((s) => s.asistenName == me && s.dayIndex == _todayIndex)
            .firstOrNull;
        final checkedIn = myShiftToday != null &&
            (myShiftToday.attendanceStatus.toLowerCase() == 'hadir' ||
                myShiftToday.attendanceStatus.toLowerCase() == 'terlambat');

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
                  right: myShiftToday == null
                      ? const LabChip.idle('Tidak Ada Jadwal')
                      : (checkedIn
                          ? const LabChip.live('Sudah Check-In')
                          : const LabChip.warn('Belum Check-In')),
                ),
                if (myShiftToday == null)
                  Text('Tidak ada jadwal mengajar hari ini.',
                      style: labText(13, c: ItlgColors.textSubtle))
                else ...[
                Text(
                  '${_dayLabel(myShiftToday.dayIndex)} • ${myShiftToday.shiftLabel} • ${myShiftToday.timeRange}',
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
              ],
            ),
            LabColumn(
              gap: 8,
              children: [
                PrakSpaceRow(
                  left: LabHeading(
                      icon: 'calendar',
                      text:
                          '${_bulanPanjang[_weekMonday.month - 1]} ${_weekMonday.year}'),
                  right: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _syncCalendar,
                    child: const LabPill(icon: 'calendar', text: 'Minggu ini'),
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
                      time: '${_dayLabel(s.dayIndex)} • ${s.timeRange}',
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
