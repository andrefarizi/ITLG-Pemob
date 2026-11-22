import 'package:flutter/material.dart';

import '../../../core/services/shift_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../laboran_store.dart';
import '../../shared/lab_actions.dart';
import '../widgets/laboran_ui.dart';

/// Figma: "Presensi Asisten-Laboran".
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
    final code = await _sync.generateAccessCode(
      generatedBy: AuthController.instance.userName,
    );
    widget.store.accessCode = code;
    if (!mounted) return;
    labToast(context, 'Kode akses baru: $code (tersinkron ke BE)');
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
    await _sync.updateShiftAttendance(shiftId: shift.id, status: status);
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
        final attended = _sync.attendedShiftCount;
        final total = _sync.totalShifts;
        final avgDiscipline = _sync.averageDisciplinePct;

        return LabSubPage(
          onLogoTap: widget.onLogoTap,
          children: [
            LabCard(
              children: [
                const LabOverline(
                  overline: 'Senin, 28 September 2026',
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
                      code: code,
                      caption: 'Asisten memindai QR ini untuk presensi shift. '
                          'Berlaku sampai ${_sync.accessValidUntil}.',
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
                    for (final s in assistants)
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
                  children: const [
                    LabSectionTitle(
                        icon: 'chart_bar', text: 'Rekap Kedisiplinan'),
                    Spacer(),
                    LabPill(icon: 'calendar', text: 'September'),
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
