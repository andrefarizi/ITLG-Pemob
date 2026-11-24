import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Halaman Kuis Pre-Test Praktikan.
class PraktikanKuisPage extends StatefulWidget {
  final PraktikanNav nav;
  final PrakCourse? course;
  final PrakMeeting? meeting;

  const PraktikanKuisPage({
    super.key,
    required this.nav,
    this.course,
    this.meeting,
  });

  @override
  State<PraktikanKuisPage> createState() => _PraktikanKuisPageState();
}

class _PraktikanKuisPageState extends State<PraktikanKuisPage> {
  static const List<String> _letters = ['A', 'B', 'C', 'D'];
  static const int _initialSeconds = 10 * 60;

  final PraktikumSyncService _sync = PraktikumSyncService.instance;
  final Map<int, int> _answers = {};
  final Map<int, int> _draft = {};
  int _index = 0;
  int _secondsLeft = _initialSeconds;
  Timer? _timer;
  bool _submitting = false;

  PrakCourse get _course => widget.course ?? _sync.courses.first;
  int get _meetingNumber => widget.meeting?.number ?? 4;
  List<PrakQuestion> get _questions => _sync.questionsForCourse(_course.id);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 0 && mounted) {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int? get _selected => _draft[_index] ?? _answers[_index];

  void _commit() {
    final d = _draft.remove(_index);
    if (d != null) _answers[_index] = d;
  }

  void _go(int index) {
    setState(() {
      _commit();
      _index = index;
    });
  }

  void _prev() {
    if (_index == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    _go(_index - 1);
  }

  Future<void> _next() async {
    if (_index < _questions.length - 1) {
      _go(_index + 1);
      return;
    }
    if (_submitting) return;
    setState(() => _commit());

    final total = _questions.length;
    final unanswered = <int>[
      for (var n = 0; n < total; n++)
        if (!_answers.containsKey(n)) n + 1,
    ];
    final msg = unanswered.isEmpty
        ? 'Anda telah menjawab semua $total soal. Yakin ingin mengakhiri dan mengumpulkan kuis?'
        : 'Anda telah menjawab ${_answers.length} dari $total soal. Soal nomor ${unanswered.join(', ')} belum dijawab. Yakin ingin mengakhiri dan mengumpulkan kuis?';

    final ok = await labShowConfirmDialog(
      context,
      icon: 'triangle_alert',
      title: 'Kumpulkan Kuis Sekarang?',
      message: msg,
      cancelLabel: 'Periksa Kembali',
      confirmLabel: 'Ya, Kumpulkan',
    );
    if (!ok || !mounted) return;
    setState(() => _submitting = true);

    final auth = AuthController.instance;
    final elapsed = (_initialSeconds - _secondsLeft).clamp(1, _initialSeconds);
    try {
      await _sync.submitKuisAttempt(
        courseId: _course.id,
        meetingNumber: _meetingNumber,
        userIdentifier: auth.userIdentifier,
        userName: auth.userName,
        answers: _answers,
        durationSeconds: elapsed,
      );
    } on StateError catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        labToast(context, e.message);
      }
      return;
    }
    if (!mounted) return;
    widget.nav.hasilKuis(
      context,
      course: _course,
      meeting: widget.meeting,
      replace: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    final total = questions.length;
    final i = _index;
    final q = questions[i];
    final answered = _answers.length;
    final percent = ((i + 1) * 100 / total).round();

    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            PrakSpaceRow(
              left: const Align(
                alignment: Alignment.centerLeft,
                child: LabTag.blue('Pre-Test'),
              ),
              right: PrakTimerPill(prakClock(_secondsLeft)),
            ),
            LabOverline(
              overline: 'Praktikum ${_course.name}',
              title: (widget.meeting?.kuisTitle.isNotEmpty ?? false)
                  ? widget.meeting!.kuisTitle
                  : (widget.meeting != null
                      ? 'Kuis ${widget.meeting!.module.replaceFirst(' • ', ' :\n')}'
                      : 'Kuis Modul $_meetingNumber :\n${_course.modulTitle}'),
            ),
            LabProgress(
              label: 'Soal ${i + 1} dari $total',
              value: '$percent%',
              fraction: (i + 1) / total,
              color: ItlgColors.primary,
            ),
          ],
        ),
        LabCard(
          children: [
            Text('Soal ${i + 1}',
                style: labText(12, w: kBold, c: ItlgColors.primary)),
            Text(q.text, style: labText(14, c: Colors.black)),
            LabColumn(
              gap: 10,
              children: [
                for (var o = 0; o < q.options.length; o++)
                  _AnswerOption(
                    letter: _letters[o],
                    text: q.options[o],
                    selected: _selected == o,
                    onTap: () => setState(() => _draft[i] = o),
                  ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              flex: 183,
              child: LabOutlineButton(
                icon: 'arrow_left',
                label: 'Sebelumnya',
                large: true,
                onTap: _prev,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 175,
              child: PrakTrailingButton(
                label: i == total - 1 ? 'Selesai' : 'Selanjutnya',
                icon: 'arrow_right',
                large: true,
                onTap: _next,
              ),
            ),
          ],
        ),
        LabCard(
          children: [
            PrakSpaceRow(
              left:
                  const LabSectionTitle(icon: 'grid', text: 'Navigasi Soal'),
              right: PrakSideLink('$answered terjawab'),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var n = 0; n < total; n++)
                  _NumberDot(
                    number: n + 1,
                    current: n == i,
                    answered: _answers.containsKey(n),
                    onTap: () => _go(n),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Pilihan jawaban: putih timbul, atau merah muda bergaris merah bila dipilih.
class _AnswerOption extends StatelessWidget {
  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.letter,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 12.5 : 14,
          vertical: selected ? 12 : 12,
        ),
        decoration: BoxDecoration(
          color: selected ? LabColors.tagRedBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: ItlgColors.primary, width: 1.5)
              : null,
          boxShadow: selected ? const [] : ItlgShadows.outline,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? ItlgColors.primary : LabColors.tile,
                shape: BoxShape.circle,
              ),
              child: Text(letter,
                  style: labText(12,
                      w: kBold, c: selected ? Colors.white : ItlgColors.text)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: labText(14))),
          ],
        ),
      ),
    );
  }
}

/// Bulatan nomor soal.
class _NumberDot extends StatelessWidget {
  final int number;
  final bool current;
  final bool answered;
  final VoidCallback onTap;

  const _NumberDot({
    required this.number,
    required this.current,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = Text('$number',
        style: labText(12,
            w: kBold,
            c: current
                ? Colors.white
                : (answered ? ItlgColors.primary : ItlgColors.textSubtle)));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: current || answered
          ? Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: current ? ItlgColors.primary : LabColors.tagRedBg,
                shape: BoxShape.circle,
              ),
              child: label,
            )
          : InnerShadowBox(
              width: 28,
              height: 28,
              radius: 14,
              color: LabColors.tile,
              shadows: LabShadows.track,
              child: Center(child: label),
            ),
    );
  }
}
