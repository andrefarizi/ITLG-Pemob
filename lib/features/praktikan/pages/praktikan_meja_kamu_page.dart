import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/lab_desk_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/desk_map.dart';
import '../widgets/praktikan_ui.dart';

/// Halaman Meja Kamu Praktikan.
class PraktikanMejaKamuPage extends StatelessWidget {
  final PraktikanNav nav;
  const PraktikanMejaKamuPage({super.key, required this.nav});

  Future<void> _pindahMeja(
    BuildContext context, {
    required String labName,
    required int currentDesk,
  }) async {
    final newDesk = await showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Pindah Meja',
      barrierColor: const Color(0x660A0B0C),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (dialogCtx, anim, _, __) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(dialogCtx).viewInsets.bottom,
          ),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 370),
                child: Material(
                  color: Colors.transparent,
                  child: _PindahMejaDialog(
                    labName: labName,
                    currentDesk: currentDesk,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (newDesk == null) return;
    nav.store.selectedDesk = newDesk;
    nav.store.bookedDesk = newDesk;
    if (!context.mounted) return;
    labToast(context, 'Berhasil pindah ke Meja $newDesk', error: false);
  }

  Future<void> _akhiriMeja(
    BuildContext context, {
    required String labName,
    required int deskNumber,
  }) async {
    final ok = await labShowConfirmDialog(
      context,
      icon: 'stop',
      title: 'Akhiri Pemakaian Meja?',
      message:
          'Meja $deskNumber akan dikosongkan dan bisa dipilih praktikan lain. Pastikan berkas kamu sudah tersimpan.',
      cancelLabel: 'Batal',
      confirmLabel: 'Ya, Akhiri',
    );
    if (!ok || !context.mounted) return;
    final userKey = AuthController.instance.userIdentifier;
    await LabDeskSyncService.instance.releaseDesk(
      labName: labName,
      deskNumber: deskNumber,
      userKey: userKey,
    );
    nav.store.bookedDesk = null;
    if (!context.mounted) return;
    nav.home();
    labToast(context, 'Pemakaian Meja $deskNumber diakhiri dan dikosongkan');
  }

  @override
  Widget build(BuildContext context) {
    final sync = LabDeskSyncService.instance;
    final presensi = PresensiSyncService.instance;
    final praktikum = PraktikumSyncService.instance;
    final s = nav.store;

    return ListenableBuilder(
      listenable: Listenable.merge([sync, presensi, praktikum]),
      builder: (context, _) {
        final session = presensi.activeSession;
        final course = praktikum.courseById(session.courseId);
        final labName = session.labName;
        final userKey = AuthController.instance.userIdentifier;
        final n = sync.bookedDeskForUser(userKey, labName: labName) ??
            s.bookedDesk ??
            s.selectedDesk;
        final pc = n.toString().padLeft(2, '0');
        final liveMap = sync.deskStatusMap(labName: labName);
        final taken = sync.takenCount(labName: labName);
        final deskRec = sync.deskRecord(n, labName: labName);
        final spec = deskRec?.spec ?? 'Core i5-12400 • 16 GB • SSD 512 GB';
        final hasActiveTicket =
            sync.activeTicketForDesk(n, labName: labName) != null;

        return LabSubPage(
          onLogoTap: nav.home,
          onBack: nav.home,
          gap: 24,
          children: [
            LabCard(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: LabTag.blue('Kom C • Sesi C1'),
                ),
                LabOverline(
                  overline: '$labName • ${course.name}',
                  title: 'Meja Kamu',
                ),
                Row(
                  children: [
                    Flexible(
                      child: LabMeta(
                          icon: 'clock', text: course.jadwalAbsensi),
                    ),
                    const SizedBox(width: 24),
                    Flexible(
                      child: LabMeta(
                          icon: 'people_group', text: '$taken / 30 terisi'),
                    ),
                  ],
                ),
              ],
            ),
            LabCard(
              children: [
                const PrakSpaceRow(
                  left: LabSectionTitle(
                      icon: 'desktop_device', text: 'Denah Meja'),
                  right: LabTag.blue('30 PC'),
                ),
                PrakDeskMap(desks: liveMap, selected: n),
                const PrakDeskLegend(selectedLabel: 'Meja Kamu'),
              ],
            ),
            LabListItem(
              leading: const LabIconTile('desktop_device'),
              title: 'Meja $n • PC-$pc',
              subtitle: spec,
              titleSize: 12,
              trailing: (deskRec?.status == PrakDesk.broken || hasActiveTicket)
                  ? const LabChip.danger('Dilaporkan Rusak')
                  : const LabChip.live('Sedang Dipakai'),
            ),
            Text(
              'Meja $n tercatat atas namamu sampai sesi berakhir pukul 09:40. '
              'Kalau PC bermasalah, pindah ke meja lain atau laporkan kendalanya. '
              'Akhiri pemakaian saat praktikum selesai.',
              style: labText(13, c: LabColors.textGrey).copyWith(height: 1.4),
            ),
            LabColumn(
              gap: 12,
              children: [
                LabPrimaryButton(
                  icon: 'home',
                  label: 'Kembali ke Beranda',
                  large: true,
                  onTap: nav.home,
                ),
                LabButtonPair(
                  left: LabOutlineButton(
                    icon: 'arrow_right_left',
                    label: 'Pindah Meja',
                    onTap: () => _pindahMeja(
                      context,
                      labName: labName,
                      currentDesk: n,
                    ),
                  ),
                  right: LabOutlineButton(
                    icon: 'triangle_alert',
                    label: 'Lapor Kendala',
                    onTap: () => nav.laporkanKerusakan(context),
                  ),
                ),
                LabSoftDangerButton(
                  icon: 'stop',
                  label: 'Akhiri Pemakaian Meja',
                  onTap: () => _akhiriMeja(
                    context,
                    labName: labName,
                    deskNumber: n,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PindahMejaDialog extends StatefulWidget {
  final String labName;
  final int currentDesk;

  const _PindahMejaDialog({
    required this.labName,
    required this.currentDesk,
  });

  @override
  State<_PindahMejaDialog> createState() => _PindahMejaDialogState();
}

class _PindahMejaDialogState extends State<_PindahMejaDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _submitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final raw = _controller.text.trim();
    final targetDesk = int.tryParse(raw);

    if (targetDesk == null) {
      setState(() => _errorText = 'Masukkan nomor meja tujuan terlebih dahulu.');
      return;
    }
    if (targetDesk < 1 || targetDesk > 30) {
      setState(() => _errorText = 'Nomor meja harus berupa angka 1 sampai 30.');
      return;
    }
    if (targetDesk == widget.currentDesk) {
      setState(() => _errorText = 'Kamu sudah berada di Meja $targetDesk.');
      return;
    }

    final sync = LabDeskSyncService.instance;
    final liveMap = sync.deskStatusMap(labName: widget.labName);
    final pc = targetDesk.toString().padLeft(2, '0');
    final status = liveMap[targetDesk];

    if (status == PrakDesk.broken) {
      setState(
        () => _errorText = 'Meja $pc sedang rusak, silakan pilih meja lain.',
      );
      return;
    }
    if (status == PrakDesk.taken) {
      setState(
        () => _errorText = 'Meja $pc sudah terisi praktikan lain.',
      );
      return;
    }

    setState(() {
      _errorText = null;
      _submitting = true;
    });

    final auth = AuthController.instance;
    final result = await sync.bookDesk(
      labName: widget.labName,
      deskNumber: targetDesk,
      userKey: auth.userIdentifier,
      userName: auth.userName,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.success) {
      setState(
        () => _errorText = result.errorMessage ?? 'Meja gagal dipilih, coba lagi.',
      );
      return;
    }

    Navigator.of(context).pop(targetDesk);
  }

  Widget _buildStatusHint() {
    if (_errorText != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: LabIcon('triangle_alert', size: 14, color: ItlgColors.error),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _errorText!,
              style: labText(12, w: kMedium, c: ItlgColors.error),
            ),
          ),
        ],
      );
    }

    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) return const SizedBox.shrink();
    if (parsed < 1 || parsed > 30) {
      return Text(
        'Nomor meja tersedia dari 1 sampai 30.',
        style: labText(12, w: kMedium, c: ItlgColors.error),
      );
    }
    if (parsed == widget.currentDesk) {
      return Text(
        'Meja $parsed sedang kamu gunakan saat ini.',
        style: labText(12, w: kMedium, c: LabColors.warnText),
      );
    }

    final liveMap = LabDeskSyncService.instance.deskStatusMap(
      labName: widget.labName,
    );
    final pc = parsed.toString().padLeft(2, '0');
    final status = liveMap[parsed];

    if (status == PrakDesk.available) {
      return Row(
        children: [
          const LabIcon('circle_check', size: 14, color: LabColors.green),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Meja $pc • PC-$pc tersedia dan siap dipakai',
              style: labText(12, w: kSemiBold, c: LabColors.green),
            ),
          ),
        ],
      );
    }
    if (status == PrakDesk.broken) {
      return Row(
        children: [
          const LabIcon('triangle_alert', size: 14, color: ItlgColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Meja $pc • PC-$pc sedang rusak',
              style: labText(12, w: kMedium, c: ItlgColors.error),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        const LabIcon('triangle_alert', size: 14, color: LabColors.warnText),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Meja $pc • PC-$pc sudah terisi',
            style: labText(12, w: kMedium, c: LabColors.warnText),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ItlgShadows.outline,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: 72,
              height: 72,
              child: InnerShadowBox(
                width: 72,
                height: 72,
                radius: 18,
                color: ItlgColors.field,
                shadows: ItlgShadows.innerLarge,
                child: const Center(
                  child: LabIcon(
                    'arrow_right_left',
                    size: 36,
                    color: ItlgColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pindah Meja',
            textAlign: TextAlign.center,
            style: labText(22, w: kBold, c: ItlgColors.text),
          ),
          const SizedBox(height: 6),
          Text(
            'Masukkan nomor meja tujuan (1–30) yang tersedia untuk berpindah dari Meja ${widget.currentDesk}.',
            textAlign: TextAlign.center,
            style: labText(13, c: ItlgColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text('Nomor Meja Tujuan', style: labText(13, w: kSemiBold)),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 48,
            decoration: BoxDecoration(
              color: _isFocused ? Colors.white : ItlgColors.field,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _errorText != null
                    ? ItlgColors.error
                    : (_isFocused
                          ? ItlgColors.primary
                          : const Color(0xFFE2E8F0)),
                width: (_isFocused || _errorText != null) ? 1.5 : 1.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: ItlgColors.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: InnerShadowBox(
                radius: 11,
                color: _isFocused ? Colors.white : ItlgColors.field,
                shadows: _isFocused ? const [] : ItlgShadows.inner,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      LabIcon(
                        'desktop_device',
                        size: 18,
                        color: _isFocused
                            ? ItlgColors.primary
                            : ItlgColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          onChanged: (_) {
                            setState(() => _errorText = null);
                          },
                          onSubmitted: (_) => _submit(),
                          cursorColor: ItlgColors.primary,
                          cursorWidth: 2.0,
                          cursorRadius: const Radius.circular(2),
                          style: labText(14, w: kSemiBold, c: ItlgColors.text),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            hintText: 'Contoh: 14',
                            hintStyle: labText(14, c: ItlgColors.textSubtle),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildStatusHint(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _submitting ? null : () => Navigator.of(context).pop(),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: LabColors.bar,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 1),
                      boxShadow: ItlgShadows.outline,
                    ),
                    child: Text(
                      'Batal',
                      textAlign: TextAlign.center,
                      style: labText(16, w: kBold, c: ItlgColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _submitting ? null : _submit,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _submitting
                          ? LabColors.divider
                          : ItlgColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ItlgShadows.outline,
                    ),
                    child: Text(
                      _submitting ? 'Memproses...' : 'Pindah',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labText(16, w: kBold, c: ItlgColors.surfaceWhite),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
