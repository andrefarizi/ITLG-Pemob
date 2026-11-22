import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';
import '../widgets/aslab_ui.dart';

/// Figma: "Hasil Kuis-Aslab".
class AslabHasilKuisPage extends StatefulWidget {
  final AslabNav nav;
  final String courseId;
  final int meetingNumber;
  const AslabHasilKuisPage({
    super.key,
    required this.nav,
    this.courseId = 'pemob',
    this.meetingNumber = 4,
  });

  @override
  State<AslabHasilKuisPage> createState() => _AslabHasilKuisPageState();
}

class _Result {
  final AslabStudent student;
  final int score;
  final String benar;
  final String waktu;

  /// Gaya chip di Figma berbeda: 0 putih polos, 1 kuning, 2 hijau berikon.
  final int chip;
  const _Result(this.student, this.score, this.benar, this.waktu, this.chip);

  bool get lulus => score >= 70;
}

class _AslabHasilKuisPageState extends State<AslabHasilKuisPage> {
  static const List<_Result> _all = [
    _Result(kRina, 90, '9 / 10 benar', '7 menit', 0),
    _Result(kDimas, 60, '6 / 10 benar', '10 menit', 1),
    _Result(kMaya, 100, '10 / 10 benar', '5 menit', 2),
  ];

  final TextEditingController _search = TextEditingController();
  String _query = '';

  /// 0 Semua, 1 Lulus, 2 Remedial.
  int _tab = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _match(_Result r) {
    if (_tab == 1 && !r.lulus) return false;
    if (_tab == 2 && r.lulus) return false;
    final q = _query.trim().toLowerCase();
    return q.isEmpty ||
        r.student.name.toLowerCase().contains(q) ||
        r.student.nim.contains(q);
  }

  Widget _chip(_Result r) {
    final text = '${r.lulus ? 'Lulus' : 'Remedial'} • ${r.score}';
    switch (r.chip) {
      case 1:
        return LabChip.warn(text);
      case 2:
        return LabChip.live(text);
      default:
        return Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(text,
                style: labText(12, w: kSemiBold, c: LabColors.green)),
          ),
        );
    }
  }

  _Result _resultFromAttempt(KuisAttemptRecord q) {
    final parts = q.userName.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (q.userName.isNotEmpty
            ? q.userName.substring(0, 1).toUpperCase()
            : 'PR');
    final mins = (q.durationSeconds / 60).ceil().clamp(1, 60);
    final chip = q.score >= 70 ? 2 : 1;
    return _Result(
      AslabStudent(initials, q.userName, q.userIdentifier),
      q.score,
      '${q.correctCount} / ${q.correctCount + q.wrongCount} benar',
      '$mins menit',
      chip,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sync = PraktikumSyncService.instance;
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final course = sync.courseById(widget.courseId);
        final meeting = sync.meetingFor(course.id, widget.meetingNumber);
        final liveAttempts = sync.allQuizAttempts
            .where((q) =>
                q.courseId == course.id &&
                q.meetingNumber == widget.meetingNumber)
            .toList();
        final dynamicResults = [
          for (final q in liveAttempts) _resultFromAttempt(q),
        ];
        final combined = [...dynamicResults, ..._all];
        final items = combined.where(_match).toList();
        final totalCount = (22 + dynamicResults.length).clamp(0, 24);
        final passExtra = dynamicResults.where((r) => r.lulus).length;
        final failExtra = dynamicResults.where((r) => !r.lulus).length;
        final passCount = 18 + passExtra;
        final failCount = 4 + failExtra;
        final maxScore = combined.fold<int>(
            0, (m, r) => r.score > m ? r.score : m);
        final avgNum = combined.isEmpty
            ? 0.0
            : combined.fold<int>(0, (acc, r) => acc + r.score) /
                combined.length;
        final avgLabel = avgNum.toStringAsFixed(1).replaceAll('.', ',');
        final kuisTitle = (meeting != null && meeting.kuisTitle.isNotEmpty)
            ? meeting.kuisTitle
            : course.preTest;

        return LabSubPage(
          onLogoTap: widget.nav.home,
          children: [
            LabTitle(
              title: 'Hasil Kuis',
              subtitle: 'Praktikum ${course.name} - ${course.kelas}',
            ),
            PrakSearchField(
              hint: 'Cari nama atau NIM praktikan...',
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              filterActive: _tab != 0,
              onFilter: () async {
                final i = await prakShowPicker(
                  context,
                  title: 'Filter Hasil Kuis',
                  options: [
                    'Semua ($totalCount)',
                    'Lulus ($passCount)',
                    'Remedial ($failCount)',
                  ],
                  selected: _tab,
                );
                if (i != null && mounted) setState(() => _tab = i);
              },
            ),
            LabCard(
              children: [
                const PrakSpaceRow(
                  left: LabTag.red('Kuis'),
                  right: LabMeta(
                      icon: 'clock', text: 'Ditutup 28 Sep 2026, 08:10 WIB'),
                ),
                Text(kuisTitle,
                    style: labText(16, w: kBold, c: Colors.black)),
                LabStatRow(
                  stats: [
                    LabStat(
                      icon: 'file',
                      label: 'Mengerjakan',
                      value: '$totalCount / 24',
                    ),
                    LabStat(
                      icon: 'check',
                      label: 'Rata-rata',
                      value: avgLabel,
                    ),
                    LabStat(
                      icon: 'clock',
                      label: 'Tertinggi',
                      value: '$maxScore',
                    ),
                  ],
                ),
              ],
            ),
            LabTabs(
              labels: [
                'Semua ($totalCount)',
                'Lulus ($passCount)',
                'Remedial ($failCount)',
              ],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            for (final r in items)
              LabCard(
                children: [
                  Row(
                    children: [
                      LabAvatar(r.student.initials),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LabColumn(
                          gap: 2,
                          children: [
                            Text(r.student.name, style: labText(14, w: kBold)),
                            Text(r.student.nim,
                                style: labText(11,
                                    w: kMedium, c: ItlgColors.textSubtle)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _chip(r),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AslabFilePill(icon: 'circle_check', text: r.benar),
                      AslabFilePill(icon: 'clock', text: r.waktu),
                    ],
                  ),
                ],
              ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Tidak ada hasil.',
                    textAlign: TextAlign.center,
                    style: labText(12, c: ItlgColors.textSubtle)),
              ),
          ],
        );
      },
    );
  }
}
