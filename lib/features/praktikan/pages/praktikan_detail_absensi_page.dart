import 'package:flutter/material.dart';

import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
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
  final PresensiSyncService _sync = PresensiSyncService.instance;

  /// 0 Semua, 1 Hadir, 2 Izin, 3 Alpa.
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onSyncChanged);
    _sync.refreshFromBackend();
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncChanged);
    super.dispose();
  }

  void _onSyncChanged() {
    if (mounted) setState(() {});
  }

  bool _match(PrakAttend status) {
    switch (_tab) {
      case 1:
        return status == PrakAttend.hadir;
      case 2:
        return status == PrakAttend.izin || status == PrakAttend.pending;
      case 3:
        return status == PrakAttend.alpa;
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
    final userId = AuthController.instance.userIdentifier;
    final summary = _sync.summaryForCourse(c, userId);
    final items = c.meetings
        .where((m) => _match(_sync.effectiveStatus(c.id, m, userId)))
        .toList();

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
                LabStat(
                    icon: 'check', label: 'Hadir', value: '${summary.hadir}'),
                LabStat(icon: 'file', label: 'Izin', value: '${summary.izin}'),
                LabStat(
                    icon: 'cross', label: 'Alpa', value: '${summary.alpa}'),
              ],
            ),
            LabProgress(
              label: 'Pertemuan terlaksana',
              value: '${summary.doneMeetings} / 12',
              fraction: (summary.doneMeetings / 12).clamp(0.0, 1.0),
            ),
          ],
        ),
        LabTabs(
          labels: const ['Semua', 'Hadir', 'Izin', 'Alpa'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        // Figma: semua pertemuan di dalam satu "Kartu Daftar".
        LabListCard(
          children: [
            for (final m in items)
              _MeetingCard(
                meeting: m,
                status: _sync.effectiveStatus(c.id, m, userId),
                notePair: _sync.effectiveNote(c.id, m, userId),
                onIzin: () => _ajukanIzin(m),
              ),
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
  final PrakAttend status;
  final (String, String) notePair;
  final VoidCallback onIzin;

  const _MeetingCard({
    required this.meeting,
    required this.status,
    required this.notePair,
    required this.onIzin,
  });

  Widget _chip() {
    switch (status) {
      case PrakAttend.upcoming:
        return const LabChip.idle('Akan Datang');
      case PrakAttend.hadir:
        return const LabChip.live('Hadir');
      case PrakAttend.izin:
        return const LabChip.info('Izin Sakit');
      case PrakAttend.pending:
        return const LabChip.warn('Izin Diajukan');
      case PrakAttend.alpa:
        return const LabChip.danger('Alpa');
    }
  }

  Widget? _extra() {
    switch (status) {
      case PrakAttend.upcoming:
        return LabOutlineButton(
          icon: 'h_file',
          label: 'Ajukan Izin Pertemuan ${meeting.number}',
          onTap: onIzin,
        );
      case PrakAttend.hadir:
        return LabMeta(
          icon: notePair.$1,
          text: notePair.$2,
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
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: ItlgColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LabIcon('attach',
                          size: 12, color: ItlgColors.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(meeting.izinFile ?? 'surat_izin.pdf',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: labText(11, w: kMedium)),
                      ),
                    ],
                  ),
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
      case PrakAttend.alpa:
        return LabMeta(
          icon: 'cross',
          text: notePair.$2.isNotEmpty
              ? notePair.$2
              : 'Tidak hadir tanpa keterangan',
          color: ItlgColors.primary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final extra = _extra();
    return LabRowCard(
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
