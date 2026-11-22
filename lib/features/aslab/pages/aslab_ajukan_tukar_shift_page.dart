import 'package:flutter/material.dart';

import '../../../core/services/shift_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';

/// Figma: "Ajukan Tukar Shift-Aslab".
class AslabAjukanTukarShiftPage extends StatefulWidget {
  final AslabNav nav;
  const AslabAjukanTukarShiftPage({super.key, required this.nav});

  @override
  State<AslabAjukanTukarShiftPage> createState() =>
      _AslabAjukanTukarShiftPageState();
}

class _AslabAjukanTukarShiftPageState extends State<AslabAjukanTukarShiftPage> {
  final ShiftSyncService _sync = ShiftSyncService.instance;
  final TextEditingController _alasan = TextEditingController();
  int _saya = 0;
  int _asst = 0;
  int _ganti = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _sync.refreshFromBackend();
  }

  @override
  void dispose() {
    _alasan.dispose();
    super.dispose();
  }

  Future<void> _pick(String title, List<String> options, int current,
      ValueChanged<int> onPicked) async {
    final i = await prakShowPicker(context,
        title: title, options: options, selected: current);
    if (i != null && mounted) setState(() => onPicked(i));
  }

  Future<void> _kirim(
    List<ShiftRecord> myShifts,
    List<String> assistants,
    List<ShiftRecord> replacementShifts,
  ) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final auth = AuthController.instance;
    final fromShift = myShifts[_saya.clamp(0, myShifts.length - 1)];
    final targetName = assistants[_asst.clamp(0, assistants.length - 1)];
    final toShift =
        replacementShifts[_ganti.clamp(0, replacementShifts.length - 1)];

    final rec = await _sync.submitSwapRequest(
      requesterId: auth.userIdentifier,
      requesterName: auth.userName,
      targetName: targetName,
      fromShift: fromShift,
      fromShiftLabel: fromShift.shortLabel,
      toShift: toShift,
      toShiftLabel: toShift.shortLabel,
      reason: _alasan.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).maybePop();
    labToast(
        context, 'Permintaan ${rec.swapCode} dikirim ke $targetName');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sync,
      builder: (context, _) {
        final me = AuthController.instance.userName;
        final all = _sync.allShifts;
        final myShifts = all.where((s) => s.asistenName == me).toList();
        final effectiveMyShifts = myShifts.isNotEmpty ? myShifts : all;
        final assistants = _sync.availableAssistantNames(excludeName: me);
        final selectedTarget =
            assistants[_asst.clamp(0, assistants.length - 1)];
        final targetShifts =
            all.where((s) => s.asistenName == selectedTarget).toList();
        final effectiveReplacements = targetShifts.isNotEmpty
            ? targetShifts
            : all.where((s) => s.asistenName != me).toList();
        final finalReplacements =
            effectiveReplacements.isNotEmpty ? effectiveReplacements : all;

        final myLabels = [for (final s in effectiveMyShifts) s.pickerLabel];
        final replLabels = [for (final s in finalReplacements) s.pickerLabel];
        final safeSaya = _saya.clamp(0, myLabels.length - 1);
        final safeAsst = _asst.clamp(0, assistants.length - 1);
        final safeGanti = _ganti.clamp(0, replLabels.length - 1);

        return LabSubPage(
          onLogoTap: widget.nav.home,
          children: [
            LabCard(
              children: [
                const LabOverline(
                  overline: 'Koordinasi Shift Jaga',
                  title: 'Ajukan Tukar Shift',
                ),
                Text(
                  'Pilih shift yang ingin ditukar dan asisten yang akan '
                  'menggantikan.',
                  style: labText(12, c: ItlgColors.textMuted),
                ),
              ],
            ),
            LabCard(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: LabSectionTitle(
                      icon: 'arrow_right_left', text: 'Detail Penukaran'),
                ),
                PrakField(
                  label: 'Shift Saya',
                  child: PrakSelect(
                    value: myLabels[safeSaya],
                    onTap: () => _pick(
                        'Shift Saya', myLabels, safeSaya, (i) => _saya = i),
                  ),
                ),
                PrakField(
                  label: 'Asisten Pengganti',
                  child: PrakSelect(
                    value: assistants[safeAsst],
                    onTap: () => _pick('Asisten Pengganti', assistants,
                        safeAsst, (i) {
                      _asst = i;
                      _ganti = 0;
                    }),
                  ),
                ),
                PrakField(
                  label: 'Shift Pengganti',
                  child: PrakSelect(
                    value: replLabels[safeGanti],
                    onTap: () => _pick('Shift Pengganti', replLabels, safeGanti,
                        (i) => _ganti = i),
                  ),
                ),
                PrakField(
                  label: 'Alasan :',
                  child: PrakTextArea(
                    controller: _alasan,
                    hint: 'Tulis alasan penukaran shift...',
                  ),
                ),
              ],
            ),
            const PrakNotice.info(
              icon: 'bell',
              text: 'Asisten tujuan menerima notifikasi dan harus menyetujui '
                  'sebelum jadwal berubah.',
            ),
            LabPrimaryButton(
              icon: 'send',
              label: 'Kirim Permintaan',
              large: true,
              onTap: () => _kirim(
                  effectiveMyShifts, assistants, finalReplacements),
            ),
          ],
        );
      },
    );
  }
}
