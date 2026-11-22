import 'package:flutter/material.dart';

import '../../../core/services/lab_desk_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../laboran_store.dart';
import '../widgets/laboran_ui.dart';

/// Figma: "Detail Tiket-Laboran".
class LaboranDetailTiketPage extends StatefulWidget {
  final LabTicket ticket;
  final VoidCallback? onLogoTap;

  const LaboranDetailTiketPage({super.key, required this.ticket, this.onLogoTap});

  @override
  State<LaboranDetailTiketPage> createState() => _LaboranDetailTiketPageState();
}

class _LaboranDetailTiketPageState extends State<LaboranDetailTiketPage> {
  static const List<String> _statuses = ['Reported', 'In Progress', 'Resolved'];

  /// 0 Reported, 1 In Progress, 2 Resolved.
  late int _status;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _status = widget.ticket.status;
    _note = TextEditingController(
      text: widget.ticket.handlingNote.isNotEmpty
          ? widget.ticket.handlingNote
          : 'Power supply diganti, menunggu pengujian ulang.',
    );
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Widget _statusChip() {
    switch (_status) {
      case 0:
        return const LabChip.danger('Reported');
      case 2:
        return const LabChip.live('Resolved');
      default:
        return const LabChip.warn('In Progress');
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    await LabDeskSyncService.instance.updateTicketStatus(
      ticketCode: widget.ticket.id,
      status: _status,
      handlingNote: _note.text.trim(),
    );
    if (!mounted) return;
    labToast(context, 'Status tiket ${widget.ticket.id} disimpan');
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      children: [
        LabCard(
          children: [
            Row(
              children: [
                LabTag.grey(t.id),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_status),
                    child: _statusChip(),
                  ),
                ),
              ],
            ),
            LabOverline(overline: 'Tiket Perbaikan', title: t.detailTitle),
            LabStatRow(
              gap: 13,
              stats: [
                LabStat(icon: 'location', label: 'Lokasi', value: t.lokasi),
                LabStat(
                    icon: 'desktop_device',
                    label: 'Kategori',
                    value: t.kategori),
              ],
            ),
            LabPerson(
              initials: t.initials,
              name: t.reporter,
              caption: 'Asisten Lab • ${t.reportedAt}',
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(icon: 'file', text: 'Detail Kerusakan'),
            ),
            Text(t.detail, style: labText(12, c: Colors.black)),
            LabInsetBox(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const LabIconTile('camera'),
                  const SizedBox(height: 7),
                  Text(t.photo, style: labText(12, w: kBold)),
                  const SizedBox(height: 7),
                  Text('Lampiran dari asisten • 1 foto',
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                ],
              ),
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(
                  icon: 'arrow_cycle', text: 'Status Penanganan'),
            ),
            LabColumn(
              gap: 14,
              children: [
                const _Step(
                  state: _StepState.done,
                  title: 'Reported',
                  caption: 'Laporan diterima • 08:15 WIB',
                ),
                _Step(
                  state: _status >= 2
                      ? _StepState.done
                      : (_status == 1 ? _StepState.active : _StepState.idle),
                  title: 'In Progress',
                  caption: _status >= 1
                      ? 'Sedang ditangani teknisi • 08:40 WIB'
                      : 'Menunggu penanganan',
                ),
                _Step(
                  state: _status == 2 ? _StepState.done : _StepState.idle,
                  title: 'Resolved',
                  caption: _status == 2
                      ? 'Perbaikan selesai'
                      : 'Menunggu penyelesaian',
                ),
              ],
            ),
            LabColumn(
              gap: 8,
              children: [
                Text('Perbarui Status', style: labText(14)),
                LabTabs(
                  labels: _statuses,
                  index: _status,
                  gap: 10,
                  hPadding: 12,
                  onChanged: (i) => setState(() => _status = i),
                ),
              ],
            ),
            LabColumn(
              gap: 8,
              children: [
                Text('Catatan Penanganan :', style: labText(14)),
                InnerShadowBox(
                  radius: 12,
                  height: 96,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: TextField(
                    controller: _note,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    cursorColor: ItlgColors.primary,
                    cursorWidth: 2.0,
                    cursorRadius: const Radius.circular(2),
                    style: labText(14),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: 'Tulis catatan penanganan...',
                      hintStyle: labText(14, c: ItlgColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        LabPrimaryButton(
          icon: 'check',
          label: 'Simpan Perubahan',
          large: true,
          onTap: _save,
        ),
      ],
    );
  }
}

enum _StepState { done, active, idle }

class _Step extends StatelessWidget {
  final _StepState state;
  final String title;
  final String caption;

  const _Step({
    required this.state,
    required this.title,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    Widget dot;
    switch (state) {
      case _StepState.done:
        dot = const LabStatusDot(
            size: 28, color: LabColors.green, icon: 'check');
        break;
      case _StepState.active:
        dot = const LabStatusDot(
            size: 28, color: ItlgColors.primary, icon: 'wrench_outline');
        break;
      case _StepState.idle:
        dot = const InnerShadowBox(
          width: 28,
          height: 28,
          radius: 14,
          color: LabColors.tile,
          shadows: LabShadows.track,
        );
        break;
    }
    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(key: ValueKey<_StepState>(state), child: dot),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LabColumn(
            gap: 2,
            children: [
              Text(
                title,
                style: labText(
                  12,
                  w: kBold,
                  c: state == _StepState.idle
                      ? ItlgColors.textSubtle
                      : ItlgColors.text,
                ),
              ),
              Text(caption,
                  style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
            ],
          ),
        ),
      ],
    );
  }
}
