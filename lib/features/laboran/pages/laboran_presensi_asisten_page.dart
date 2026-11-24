import 'package:flutter/material.dart';

import '../../../core/services/shift_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../laboran_store.dart';
import '../../shared/lab_actions.dart';
import '../widgets/laboran_ui.dart';

/// Halaman Presensi Asisten Laboran.
class LaboranPresensiAsistenPage extends StatefulWidget {
  final LaboranStore store;
  final VoidCallback? onLogoTap;

  const LaboranPresensiAsistenPage({
    super.key,
    required this.store,
    this.onLogoTap,
  });

  @override
  State<LaboranPresensiAsistenPage> createState() =>
      _LaboranPresensiAsistenPageState();
}

class _LaboranPresensiAsistenPageState
    extends State<LaboranPresensiAsistenPage> {
  final ShiftSyncService _sync = ShiftSyncService.instance;

  @override
  void initState() {
    super.initState();
    _sync.refreshFromBackend();
  }

  Future<void> _generate() async {
    final String code;
    try {
      code = await _sync.generateAccessCode(
        generatedBy: AuthController.instance.userName,
      );
    } on StateError catch (e) {
      if (mounted) labToast(context, e.message);
      return;
    }
    widget.store.accessCode = code;
    if (!mounted) return;
    await labShowResult(
      context,
      icon: 'key',
      title: 'Kode Akses Diperbarui',
      message:
          'Kode baru berlaku sampai 17:00 WIB. Bagikan ke asisten yang bertugas hari ini.',
    );
  }

  Future<void> _updateAssistantStatus(ShiftRecord shift) async {
    const options = ['Hadir Tepat Waktu', 'Terlambat', 'Belum Hadir'];
    final current = shift.attendanceStatus == 'hadir'
        ? 0
        : (shift.attendanceStatus == 'terlambat' ? 1 : 2);
    final picked = await prakShowPicker(
      context,
      title: 'Presensi ${shift.asistenName}',
      options: options,
      selected: current,
    );
    if (picked == null || !mounted) return;
    final status = picked == 0 ? 'hadir' : (picked == 1 ? 'terlambat' : 'belum');
    try {
      await _sync.updateShiftAttendance(shiftId: shift.id, status: status);
    } on StateError catch (e) {
      if (mounted) labToast(context, e.message);
      return;
    }
    if (!mounted) return;
    labToast(context, 'Presensi ${shift.asistenName} diperbarui');
  }

  Widget _attendanceChip(ShiftRecord s) {
    switch (s.attendanceStatus) {
      case 'hadir':
        return LabChip.live(s.checkInTime ?? 'Hadir');
      case 'terlambat':
        return const LabChip.warn('Terlambat');
      default:
        return const LabChip.idle('Belum');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sync,
      builder: (context, _) {
        final code = _sync.accessCode;
        final assistants = _sync.dutyAssistants;
        final today = _sync.todayShifts;
        final attended = _sync.todayAttendedCount;
        final total = today.length;
        const hari = [
          'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
        ];
        const bulan = [
          'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli',
          'Agustus', 'September', 'Oktober', 'November', 'Desember',
        ];
        final now = DateTime.now().toUtc().add(const Duration(hours: 7));
        final todayLabel =
            '${hari[now.weekday - 1]}, ${now.day} ${bulan[now.month - 1]} ${now.year}';
        final avgDiscipline = _sync.averageDisciplinePct;

        return LabSubPage(
          onLogoTap: widget.onLogoTap,
          children: [
            LabCard(
              children: [
                LabOverline(
                  overline: todayLabel,
                  title: 'Presensi Asisten',
                ),
                LabInsetBox(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('Kode Akses Presensi Hari Ini',
                          style: labText(12, c: ItlgColors.textSubtle)),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          code,
                          key: ValueKey<String>(code),
                          style: labText(27, w: kBold, c: ItlgColors.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      LabMeta(
                          icon: 'clock',
                          text: 'Berlaku sampai ${_sync.accessValidUntil}'),
                      const SizedBox(height: 8),
                      Text(
                        'Asisten check-in dengan memindai QR ini atau mengetik kode di menu Jadwal Mengajar.',
                        textAlign: TextAlign.center,
                        style: labText(11, c: ItlgColors.textMuted),
                      ),
                    ],
                  ),
                ),
                LabButtonPair(
                  left: LabOutlineButton(
                    icon: 'qrcode',
                    label: 'Tampilkan QR',
                    onTap: () => labShowQr(
                      context,
                      title: 'QR Presensi Asisten',
                      code: _sync.rotatingQrPayload,
                      caption:
                          'Minta asisten memindai QR ini dari menu Jadwal Mengajar (diperbarui tiap 60 detik). Kode cadangan $code berlaku sampai ${_sync.accessValidUntil}.',
                    ),
                  ),
                  right: LabPrimaryButton(
                    icon: 'key',
                    label: 'Generate Akses',
                    onTap: _generate,
                  ),
                ),
              ],
            ),
            LabCard(
              children: [
                Row(
                  children: [
                    const LabSectionTitle(
                        icon: 'people_group', text: 'Asisten Bertugas'),
                    const Spacer(),
                    Text('$attended / $total Hadir',
                        style: labText(16, w: kBold, c: ItlgColors.primary)),
                  ],
                ),
                LabColumn(
                  gap: 8,
                  children: [
                    if (today.isEmpty)
                      Text('Tidak ada shift asisten hari ini.',
                          style: labText(12, c: ItlgColors.textSubtle)),
                    for (final s in today)
                      LabListItem(
                        leading: LabAvatar(s.asistenInitials),
                        title: s.asistenName,
                        subtitle: '${s.shiftLabel} • ${s.room}',
                        trailing: _attendanceChip(s),
                        onTap: () => _updateAssistantStatus(s),
                      ),
                  ],
                ),
              ],
            ),
            LabCard(
              children: [
                Row(
                  children: [
                    const LabSectionTitle(
                        icon: 'chart_bar', text: 'Rekap Kedisiplinan'),
                    const Spacer(),
                    LabPill(icon: 'calendar', text: bulan[now.month - 1]),
                  ],
                ),
                for (final s in assistants)
                  LabProgress(
                    label: s.asistenName,
                    value: '${s.disciplinePct}%',
                    fraction: (s.disciplinePct / 100).clamp(0.0, 1.0),
                    color: s.disciplinePct < 80
                        ? ItlgColors.primary
                        : LabColors.green,
                  ),
                Container(height: 1, color: const Color(0x80B5B9BC)),
                Row(
                  children: [
                    Expanded(
                      child: Text('Rata-rata Tepat Waktu',
                          style: labText(12, w: kBold)),
                    ),
                    Text('$avgDiscipline%',
                        style: labText(16, w: kBold, c: ItlgColors.primary)),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
