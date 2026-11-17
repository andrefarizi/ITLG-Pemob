import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Kuis Pre-Test-Praktikan".
///
/// Dibuka di posisi yang sama dengan Figma (Soal 3, soal 1–2 terjawab, B
/// dipilih). "Selanjutnya" pindah ke soal berikutnya; di soal terakhir
/// membuka Hasil Kuis.
class PraktikanKuisPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanKuisPage({super.key, required this.nav});

  @override
  State<PraktikanKuisPage> createState() => _PraktikanKuisPageState();
}

class _PraktikanKuisPageState extends State<PraktikanKuisPage> {
  static const List<String> _letters = ['A', 'B', 'C', 'D'];
  Timer? _timer;

  PraktikanStore get _s => widget.nav.store;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_s.quizSecondsLeft > 0) setState(() => _s.quizSecondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int? get _selected =>
      _s.quizDraft[_s.quizIndex] ?? _s.quizAnswers[_s.quizIndex];

  void _commit() {
    final d = _s.quizDraft.remove(_s.quizIndex);
    if (d != null) _s.quizAnswers[_s.quizIndex] = d;
  }

  void _go(int index) {
    setState(() {
      _commit();
      _s.quizIndex = index;
    });
  }

  void _prev() {
    if (_s.quizIndex == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    _go(_s.quizIndex - 1);
  }

  void _next() {
    if (_s.quizIndex < _s.questions.length - 1) {
      _go(_s.quizIndex + 1);
      return;
    }
    setState(_commit);
    widget.nav.hasilKuis(context, replace: true);
  }

  @override
  Widget build(BuildContext context) {
    final total = _s.questions.length;
    final i = _s.quizIndex;
    final q = _s.questions[i];
    final answered = _s.quizAnswers.length;
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
              right: PrakTimerPill(prakClock(_s.quizSecondsLeft)),
            ),
            const LabOverline(
              overline: 'Praktikum Pemrograman Mobile',
              title: 'Kuis Modul 4 :\nState Management',
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
                    onTap: () => setState(() => _s.quizDraft[i] = o),
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
                label: 'Selanjutnya',
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
                    answered: _s.quizAnswers.containsKey(n),
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

/// Bulatan nomor soal 28 px.
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
