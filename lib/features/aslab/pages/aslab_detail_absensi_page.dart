import 'package:flutter/material.dart';

import '../../../core/services/presensi_sync_service.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/praktikan_store.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';
import '../widgets/aslab_ui.dart';

/// Halaman Detail Absensi Praktikum Asisten Lab.
class AslabDetailAbsensiPage extends StatefulWidget {
  final AslabNav nav;
  final AslabCourse course;

  const AslabDetailAbsensiPage({
    super.key,
    required this.nav,
    required this.course,
  });

  @override
  State<AslabDetailAbsensiPage> createState() => _AslabDetailAbsensiPageState();
}

class _AslabDetailAbsensiPageState extends State<AslabDetailAbsensiPage> {
  /// 0 Semua, 1 Selesai, 2 Belum Dibuat.
  int _tab = 0;

  static const List<String> _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static DateTime? _parseTanggal(String s) {
    final m = RegExp(r'(\d{1,2}) ([A-Za-z]{3}) (\d{4})').firstMatch(s);
    if (m == null) return null;
    final mon = _bulan.indexOf(m.group(2)!);
    if (mon < 0) return null;
    return DateTime(int.parse(m.group(3)!), mon + 1, int.parse(m.group(1)!));
  }

  bool _match(AslabSession s) {
    if (_tab == 1) return s.state == 2;
    if (_tab == 2) return s.state != 2;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final nav = widget.nav;
    final presensiSync = PresensiSyncService.instance;
    return ListenableBuilder(
      listenable: presensiSync,
      builder: (context, _) {
        final activeSession = presensiSync.activeSession;
        // Status & rekap tiap pertemuan dari catatan presensi nyata.
        final today = DateTime.now();
        final sessions = [
          for (final s0 in c.sessions)
            () {
              final recs = presensiSync.recordsForMeeting(c.id, s0.number);
              if (recs.isNotEmpty) {
                return AslabSession(s0.number, s0.module, s0.date, 2,
                    hadir: recs.where((r) => r.status == PrakAttend.hadir).length,
                    izin: recs.where((r) => r.status == PrakAttend.izin).length,
                    alpa: recs.where((r) => r.status == PrakAttend.alpa).length);
              }
              final d = _parseTanggal(s0.date);
              final reached = d == null ||
                  !DateTime(d.year, d.month, d.day)
                      .isAfter(DateTime(today.year, today.month, today.day));
              return AslabSession(s0.number, s0.module, s0.date, reached ? 0 : 1);
            }(),
        ];
        final items = sessions.where(_match).toList();
        final created = sessions.where((x) => x.state == 2).length;
        final allRecs = [
          for (final x in sessions)
            ...presensiSync.recordsForMeeting(c.id, x.number),
        ];
        final rata = allRecs.isEmpty
            ? '-'
            : '${(allRecs.where((r) => r.status == PrakAttend.hadir).length * 100 / allRecs.length).round()}%';
        return LabSubPage(
          onLogoTap: nav.home,
          children: [
            LabCard(
              children: [
                AslabClassTitle(kelas: c.kelas, name: c.name),
                LabStatRow(
                  gap: 13,
                  stats: [
                    LabStat(
                        icon: 'people_group',
                        label: 'Praktikan',
                        value: () {
                          final n = PresensiSyncService.instance
                              .knownStudentCount(c.id);
                          return n == 0 ? '-' : '$n Orang';
                        }()),
                    LabStat(
                        icon: 'statistic_up',
                        label: 'Rata-rata Hadir',
                        value: rata),
                  ],
                ),
                LabProgress(
                  label: 'Presensi dibuat',
                  value: '$created / 12 pertemuan',
                  fraction: created / 12,
                ),
              ],
            ),
            LabTabs(
              labels: const ['Semua', 'Selesai', 'Belum Dibuat'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            LabColumn(
              gap: 16,
              children: [
                for (final s in items)
                  Builder(
                    builder: (_) {
                      final isLiveSession = activeSession.courseId == c.id &&
                          activeSession.meetingNumber == s.number &&
                          activeSession.isActive;
                      final liveRecs = presensiSync.recordsForMeeting(
                          c.id, s.number);
                      final liveHadirCount = liveRecs
                          .where((r) => r.status == PrakAttend.hadir)
                          .length;
                      return _SessionCard(
                        session: s,
                        isLive: isLiveSession,
                        liveHadir: liveHadirCount,
                        liveIzin: liveRecs
                            .where((r) => r.status == PrakAttend.izin)
                            .length,
                        onCreate: () => isLiveSession
                            ? nav.sesiAktif(context)
                            : nav.buatSesi(
                                context,
                                courseId: c.id,
                                meetingNumber: s.number,
                              ),
                        onDetail: () => nav.detailPresensi(
                          context,
                          courseId: c.id,
                          meetingNumber: s.number,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final AslabSession session;
  final bool isLive;
  final int liveHadir;
  final int liveIzin;
  final VoidCallback onCreate;
  final VoidCallback onDetail;

  const _SessionCard({
    required this.session,
    this.isLive = false,
    this.liveHadir = 0,
    this.liveIzin = 0,
    required this.onCreate,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final s = session;
    final done = s.state == 2;
    return LabCard(
      gap: 12,
      children: [
        Row(
          children: [
            PrakNumberTile('${s.number}'),
            const SizedBox(width: 10),
            Expanded(
              child: LabColumn(
                gap: 2,
                children: [
                  Text('Pertemuan ${s.number}', style: labText(14, w: kBold)),
                  Text(s.module,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labText(11,
                          w: kMedium, c: const Color(0xFF6B7280))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isLive
                ? const LabChip.live('Sesi Berlangsung')
                : (done
                    ? const LabChip.live('Selesai')
                    : const LabChip.idle('Belum Dibuat')),
          ],
        ),
        LabMeta(icon: 'calendar', text: s.date),
        if (isLive) ...[
          AslabRekap(hadir: liveHadir, izin: liveIzin, alpa: 0),
          LabPrimaryButton(
              icon: 'qrcode',
              label: 'Lihat Sesi & QR Presensi',
              onTap: onCreate),
        ] else if (s.state == 0)
          LabPrimaryButton(
              icon: 'qrcode', label: 'Buat Sesi Presensi', onTap: onCreate),
        if (!isLive && s.state == 1)
          const LabMeta(
            icon: 'lock_on',
            text: 'Sesi dapat dibuat pada hari pertemuan',
          ),
        if (!isLive && done) ...[
          AslabRekap(hadir: s.hadir, izin: s.izin, alpa: s.alpa),
          LabOutlineButton(
            icon: 'eye',
            label: 'Detail Presensi Pertemuan ${s.number}',
            onTap: onDetail,
          ),
        ],
      ],
    );
  }
}
