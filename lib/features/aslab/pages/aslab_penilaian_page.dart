import 'package:flutter/material.dart';

import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/praktikan_store.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import 'aslab_sanggahan_nilai_page.dart';

/// Halaman Penilaian Asisten Lab.
class AslabPenilaianPage extends StatefulWidget {
  final AslabNav nav;
  const AslabPenilaianPage({super.key, required this.nav});

  @override
  State<AslabPenilaianPage> createState() => _AslabPenilaianPageState();
}

class _AslabPenilaianPageState extends State<AslabPenilaianPage> {
  /// 0 Perlu Dinilai, 1 Selesai.
  int _tab = 0;
  int _meetingFilter = 3; // 0-based -> Pertemuan 4
  int _sessionFilter = 0; // 0 Semua, 1 Sesi C1, 2 Sesi C2

  static const List<String> _meetingOptions = [
    'Pertemuan 1',
    'Pertemuan 2',
    'Pertemuan 3',
    'Pertemuan 4',
    'Pertemuan 5',
    'Pertemuan 6',
  ];
  static const List<String> _sessionOptions = ['Semua', 'Sesi C1', 'Sesi C2'];

  Widget _filterPill(String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ItlgShadows.outline,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: labText(12, w: kBold, c: Colors.black)),
            const SizedBox(width: 6),
            const LabIcon('chevron_down',
                size: 12, color: ItlgColors.textSubtle),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = widget.nav;
    final sync = PraktikumSyncService.instance;
    final nilaiSync = NilaiSyncService.instance;
    final activeMeeting = _meetingFilter + 1;
    return ListenableBuilder(
      listenable: Listenable.merge([sync, nilaiSync]),
      builder: (context, _) {
        final courses = sync.courses;
        final totalPending = courses.fold<int>(0, (sum, c) {
          final subs = sync.submissionsForCourse(c.id, activeMeeting);
          final pendingExtra = subs.where((s) => s.status != 'graded').length;
          final appeals = nilaiSync.pendingAppealsForCourse(c.id).length;
          return sum + pendingExtra + appeals;
        });
        final totalGraded = courses.fold<int>(0, (sum, c) {
          final subs = sync.submissionsForCourse(c.id, activeMeeting);
          final gradedExtra = subs.where((s) => s.status == 'graded').length;
          return sum + gradedExtra;
        });

        final pendingAppeals = nilaiSync.pendingAppealCount;
        final pemobVal = nilaiSync.validationFor('pemob');
        final valStep = pemobVal.isValidated
            ? 3
            : (pemobVal.isRevisionRequested
                ? 2
                : (pemobVal.isDraft ? 0 : 1));

        return LabTabBody(
          children: [
            const LabTitle(
              title: 'Penilaian',
              subtitle: 'Tugas praktikan yang perlu anda evaluasi',
            ),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _filterPill(_meetingOptions[_meetingFilter], () async {
                  final i = await prakShowPicker(
                    context,
                    title: 'Pilih Pertemuan',
                    options: _meetingOptions,
                    selected: _meetingFilter,
                  );
                  if (i != null && mounted) {
                    setState(() => _meetingFilter = i);
                  }
                }),
                _filterPill('Sesi: ${_sessionOptions[_sessionFilter]}', () async {
                  final i = await prakShowPicker(
                    context,
                    title: 'Pilih Sesi',
                    options: _sessionOptions,
                    selected: _sessionFilter,
                  );
                  if (i != null && mounted) {
                    setState(() => _sessionFilter = i);
                  }
                }),
              ],
            ),
            LabStatRow(
              stats: [
                LabStat(
                  icon: 'clipboard',
                  label: 'Tugas Aktif',
                  value: '${courses.length}',
                ),
                LabStat(
                  icon: 'clock',
                  label: 'Menunggu',
                  value: '$totalPending',
                ),
                LabStat(
                  icon: 'circle_check',
                  label: 'Dinilai',
                  value: '$totalGraded',
                ),
              ],
            ),
            // Kartu "Status Rekap Nilai"
            LabCard(
              gap: 12,
              children: [
                PrakSpaceRow(
                  left: const LabSectionTitle(
                      icon: 'clipboard', text: 'Status Rekap Nilai'),
                  right: pemobVal.isValidated
                      ? const LabChip.live('Divalidasi')
                      : (pemobVal.isRevisionRequested
                          ? const LabChip.warn('Revisi Diminta')
                          : (pemobVal.isDraft
                              ? const LabChip.idle('Draft')
                              : const LabChip.info('Diajukan'))),
                ),
                Text(
                  'Rekap Pertemuan 1–$activeMeeting • Pemrograman Mobile Kom C',
                  style: labText(12, w: kMedium, c: ItlgColors.textSubtle),
                ),
                // 4-segment horizontal progress bar
                Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: i <= valStep
                                    ? ItlgColors.primary
                                    : const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              const ['Draft', 'Diajukan', 'Revisi', 'Divalidasi']
                                  [i],
                              style: labText(
                                10,
                                w: i <= valStep ? kSemiBold : kMedium,
                                c: i <= valStep
                                    ? ItlgColors.primary
                                    : ItlgColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (pemobVal.isRevisionRequested &&
                    (pemobVal.revisionNote?.isNotEmpty ?? false)) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: LabColors.tagBlueBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: LabIcon('info',
                              size: 18, color: LabColors.blueDark),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Catatan Dosen',
                                style: labText(12,
                                    w: kBold, c: LabColors.blueDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pemobVal.revisionNote!,
                                style: labText(12,
                                    w: kMedium, c: LabColors.blueDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  LabPrimaryButton(
                    icon: 'send',
                    label: 'Ajukan Ulang Rekap ke Dosen',
                    large: true,
                    onTap: () async {
                      try {
                        await nilaiSync.resubmitValidation(
                          'pemob',
                          submittedBy: AuthController.instance.userName,
                        );
                      } on StateError catch (e) {
                        if (context.mounted) labToast(context, e.message);
                        return;
                      }
                      if (!context.mounted) return;
                      await labShowResultDialog(
                        context,
                        icon: 'send',
                        title: 'Rekap Terkirim ke Dosen',
                        message:
                            'Rekap nilai yang telah direvisi sudah diajukan ulang untuk validasi Dosen Pengampu.',
                        button: 'Selesai',
                      );
                    },
                  ),
                ] else if (pemobVal.isDraft) ...[
                  LabPrimaryButton(
                    icon: 'send',
                    label: 'Ajukan Rekap ke Dosen',
                    large: true,
                    onTap: () async {
                      try {
                        await nilaiSync.resubmitValidation(
                          'pemob',
                          submittedBy: AuthController.instance.userName,
                        );
                      } on StateError catch (e) {
                        if (context.mounted) labToast(context, e.message);
                        return;
                      }
                      if (!context.mounted) return;
                      await labShowResultDialog(
                        context,
                        icon: 'send',
                        title: 'Rekap Terkirim ke Dosen',
                        message:
                            'Rekap nilai sudah diajukan dari Draft untuk validasi Dosen Pengampu.',
                        button: 'Selesai',
                      );
                    },
                  ),
                ],
              ],
            ),
            // Kartu Pintasan "Sanggahan Nilai"
            LabListItem(
              leading: const LabIconTile('triangle_alert'),
              title: 'Sanggahan Nilai',
              subtitle: pendingAppeals > 0
                  ? '$pendingAppeals sanggahan menunggu ditinjau'
                  : 'Semua sanggahan sudah ditinjau',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pendingAppeals > 0) ...[
                    LabTag.red('$pendingAppeals Baru'),
                    const SizedBox(width: 6),
                  ],
                  const LabIcon('chevron_right',
                      size: 16, color: ItlgColors.primary),
                ],
              ),
              onTap: () => labPush(
                context,
                SanggahanNilaiReviewPage(
                  isDosen: false,
                  onLogoTap: nav.home,
                ),
              ),
            ),
            Builder(builder: (_) {
              // Data nyata pertemuan yang dipilih di filter.
              final cards = <(PrakCourse, int, int)>[
                for (final c in courses)
                  (
                    c,
                    sync.submissionsForCourse(c.id, activeMeeting).length,
                    sync
                        .submissionsForCourse(c.id, activeMeeting)
                        .where((s) => s.status == 'graded')
                        .length,
                  ),
              ];
              bool isDone((PrakCourse, int, int) e) => e.$2 > 0 && e.$3 == e.$2;
              final pending = cards.where((e) => !isDone(e)).toList();
              final done = cards.where(isDone).toList();
              final shown = _tab == 0 ? pending : done;
              return LabColumn(
                gap: 16,
                children: [
                  LabTabs(
                    labels: [
                      'Perlu Dinilai (${pending.length})',
                      'Selesai (${done.length})',
                    ],
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                  for (final e in shown)
                    Builder(builder: (_) {
                      final c = e.$1;
                      final meeting = sync.meetingFor(c.id, activeMeeting);
                      final tugasTitle =
                          (meeting?.tugasTitle.isNotEmpty ?? false)
                              ? meeting!.tugasTitle
                              : 'Tugas $activeMeeting';
                      final deadline =
                          (meeting?.tugasDeadline.isNotEmpty ?? false)
                              ? meeting!.tugasDeadline
                              : c.tugasDeadline;
                      return _TaskCard(
                        tag: 'Tugas $activeMeeting',
                        title: tugasTitle.replaceFirst(
                            RegExp(r'^Tugas \d+ : '), ''),
                        course: 'Praktikum ${c.name} • Kom C (C1 & C2)',
                        deadline: deadline,
                        done: e.$2 == 0
                            ? 'Belum ada pengumpulan'
                            : '${e.$3} / ${e.$2} dinilai',
                        fraction:
                            e.$2 == 0 ? 0 : (e.$3 / e.$2).clamp(0.0, 1.0),
                        finished: isDone(e),
                        onTap: () => nav.evaluasiTugas(
                          context,
                          courseId: c.id,
                          meetingNumber: activeMeeting,
                        ),
                      );
                    }),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        _tab == 0
                            ? 'Semua tugas pertemuan ini sudah dinilai.'
                            : 'Belum ada tugas yang selesai dinilai.',
                        textAlign: TextAlign.center,
                        style: labText(12, c: ItlgColors.textSubtle),
                      ),
                    ),
                ],
              );
            }),
          ],
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String tag;
  final String title;
  final String course;
  final String deadline;
  final String done;
  final double fraction;
  final bool finished;
  final VoidCallback onTap;

  const _TaskCard({
    required this.tag,
    required this.title,
    required this.course,
    this.deadline = 'Deadline 29 Sep, 10:30',
    required this.done,
    required this.fraction,
    required this.onTap,
    this.finished = false,
  });

  @override
  Widget build(BuildContext context) {
    return LabCard(
      children: [
        PrakSpaceRow(
          left: Align(
            alignment: Alignment.centerLeft,
            child: LabTag.red(tag),
          ),
          right: finished
              ? const LabChip.live('Selesai Dinilai')
              : LabMeta(icon: 'clock', text: deadline),
        ),
        Text(title, style: labText(16, w: kBold, c: Colors.black)),
        LabMeta(icon: 'book_open', text: course),
        LabProgress(
          label: 'Progres penilaian',
          value: done,
          fraction: fraction,
          color: finished ? LabColors.green : ItlgColors.primary,
        ),
        finished
            ? LabOutlineButton(
                icon: 'clipboard', label: 'Lihat Evaluasi', onTap: onTap)
            : LabPrimaryButton(
                icon: 'clipboard', label: 'Evaluasi Tugas', onTap: onTap),
      ],
    );
  }
}
