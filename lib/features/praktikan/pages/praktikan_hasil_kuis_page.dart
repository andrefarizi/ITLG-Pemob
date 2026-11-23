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

  /// Figma: "Sheet Pembahasan Kuis-Praktikan" (5828:3459).
  void _showPembahasanSheet({
    required String kuisTitle,
    required List<PrakQuestion> questions,
    required KuisAttemptRecord? attempt,
    required int score,
    required int correct,
  }) {
    final total = questions.length;
    final lulus = score >= 70;
    labShowCustomSheet<void>(
      context,
      title: 'Pembahasan Kuis • Jawaban Kamu',
      subtitle:
          '$kuisTitle • Skor $score • $correct dari $total benar • ${lulus ? 'Lulus' : 'Remedial'}',
      child: LabColumn(
        gap: 8,
        children: [
          for (var i = 0; i < total; i++)
            () {
              final q = questions[i];
              final keyLetter = _letters[q.answer.clamp(0, _letters.length - 1)];
              final picked = attempt?.answers[i];
              final isOk = attempt != null
                  ? (picked != null && picked == q.answer)
                  : i < correct;
              final ansSub = attempt != null
                  ? (picked == null
                      ? 'Tidak dijawab • Kunci $keyLetter'
                      : 'Jawaban ${_letters[picked.clamp(0, _letters.length - 1)]} • Kunci $keyLetter')
                  : (isOk
                      ? 'Jawaban $keyLetter • Kunci $keyLetter'
                      : 'Jawaban ${_letters[(q.answer + 1) % _letters.length]} • Kunci $keyLetter');
              return LabListItem(
                leading: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: LabColors.tile,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: LabIcon(
                    isOk ? 'circle_check' : 'cross',
                    size: 18,
                    color: isOk ? LabColors.green : ItlgColors.primary,
                  ),
                ),
                title: 'Soal ${i + 1} • ${q.text}',
                subtitle: ansSub,
                titleSize: 12,
                trailing: isOk
                    ? const LabChip.live('Benar')
                    : const LabChip.danger('Salah'),
              );
            }(),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Menampilkan $total dari $total soal • geser ke bawah untuk melihat sisanya',
              style: labText(11, w: kMedium, c: ItlgColors.textSubtle),
            ),
          ),
        ],
      ),
    );
  }

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
    final shown = review.length < 4 ? review.length : 4;
    final kuisTitle = (widget.meeting?.kuisTitle.isNotEmpty ?? false)
        ? widget.meeting!.kuisTitle
        : (widget.meeting != null
            ? 'Kuis ${widget.meeting!.module.replaceFirst(' • ', ' : ')}'
            : 'Pre-Test Modul $mNum');

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
                'Lihat Semua',
                onTap: () => _showPembahasanSheet(
                  kuisTitle: kuisTitle,
                  questions: questions,
                  attempt: attempt,
                  score: score,
                  correct: correct,
                ),
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
                    onTap: () => _showPembahasanSheet(
                      kuisTitle: kuisTitle,
                      questions: questions,
                      attempt: attempt,
                      score: score,
                      correct: correct,
                    ),
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
