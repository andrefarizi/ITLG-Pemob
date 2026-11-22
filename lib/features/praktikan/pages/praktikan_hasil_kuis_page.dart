import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Hasil Kuis-Praktikan".
class PraktikanHasilKuisPage extends StatefulWidget {
  final PraktikanNav nav;
  final PrakCourse? course;
  final PrakMeeting? meeting;

  const PraktikanHasilKuisPage({
    super.key,
    required this.nav,
    this.course,
    this.meeting,
  });

  @override
  State<PraktikanHasilKuisPage> createState() => _PraktikanHasilKuisPageState();
}

class _PraktikanHasilKuisPageState extends State<PraktikanHasilKuisPage> {
  static const List<String> _letters = ['A', 'B', 'C', 'D'];
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final sync = PraktikumSyncService.instance;
    final c = widget.course ?? sync.courses.first;
    final mNum = widget.meeting?.number ?? 4;
    final questions = sync.questionsForCourse(c.id);
    final attempt = sync.quizAttemptFor(
      c.id,
      mNum,
      AuthController.instance.userIdentifier,
    );

    final review = <(String, bool)>[];
    if (attempt != null) {
      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        final picked = attempt.answers[i];
        final isCorrect = picked == q.answer;
        final correctOpt = '${_letters[q.answer]} • ${q.options[q.answer]}';
        if (picked == null) {
          review.add(('Belum dijawab • Jawaban benar: $correctOpt', false));
        } else if (isCorrect) {
          review.add(('Jawaban anda: ${_letters[picked]} • ${q.options[picked]}', true));
        } else {
          review.add((
            'Jawaban anda: ${_letters[picked]} • Jawaban benar: $correctOpt',
            false,
          ));
        }
      }
    } else {
      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        final correctOpt = '${_letters[q.answer]} • ${q.options[q.answer]}';
        review.add(('Jawaban anda: $correctOpt', true));
      }
    }

    final score = attempt?.score ?? 80;
    final correct = attempt?.correctCount ?? 8;
    final wrong = attempt?.wrongCount ?? 2;
    final timeStr = prakClock(attempt?.durationSeconds ?? (5 * 60 + 28));
    final shown = _all ? review.length : (review.length < 4 ? review.length : 4);

    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          decoration: BoxDecoration(
            color: ItlgColors.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            boxShadow: ItlgShadows.outline,
          ),
          child: Column(
            children: [
              const PrakIconWell('trophy'),
              const SizedBox(height: 13),
              Text('Pre-Test Selesai',
                  textAlign: TextAlign.center, style: labText(22, w: kBold)),
              const SizedBox(height: 4),
              Text(
                  (widget.meeting?.kuisTitle.isNotEmpty ?? false)
                      ? widget.meeting!.kuisTitle
                      : (widget.meeting != null
                          ? 'Kuis ${widget.meeting!.module.replaceFirst(' • ', ' : ')}'
                          : 'Kuis Modul $mNum : ${c.modulTitle}'),
                  textAlign: TextAlign.center,
                  style: labText(14, c: ItlgColors.textMuted)),
              const SizedBox(height: 13),
              PrakBigScore('$score'),
              const SizedBox(height: 13),
              LabStatRow(
                stats: [
                  LabStat(icon: 'check', label: 'Benar', value: '$correct'),
                  LabStat(icon: 'cross', label: 'Salah', value: '$wrong'),
                  LabStat(icon: 'clock', label: 'Waktu', value: timeStr),
                ],
              ),
            ],
          ),
        ),
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabSectionTitle(
                  icon: 'clipboard', text: 'Pembahasan'),
              right: PrakSideLink(
                _all ? 'Ringkas' : 'Lihat Semua',
                onTap: () => setState(() => _all = !_all),
              ),
            ),
            LabColumn(
              gap: 8,
              children: [
                for (var i = 0; i < shown; i++)
                  LabListItem(
                    leading: PrakNumberTile('${i + 1}'),
                    title: 'Soal ${i + 1}',
                    subtitle: review[i].$1,
                    titleSize: 12,
                    trailing: review[i].$2
                        ? const LabIcon('circle_check',
                            size: 18, color: LabColors.green)
                        : const LabIcon('cross',
                            size: 18, color: ItlgColors.primary),
                  ),
              ],
            ),
          ],
        ),
        const PrakNotice.info(
          icon: 'info',
          text: 'Nilai pre-test tidak memengaruhi nilai akhir, hanya untuk '
              'mengukur kesiapan sebelum praktikum.',
        ),
        LabPrimaryButton(
          icon: 'book_open',
          label: 'Lanjut ke Materi Modul $mNum',
          large: true,
          onTap: () => widget.nav.detailMateri(
            context,
            course: c,
            meeting: widget.meeting,
            replace: true,
          ),
        ),
      ],
    );
  }
}
