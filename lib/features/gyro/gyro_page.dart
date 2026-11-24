import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'gyro_replies.dart';
import 'widgets/gyro_mascot_view.dart';

/// Halaman asisten virtual Tanya Gyro.
class GyroPage extends StatefulWidget {
  const GyroPage({super.key});

  @override
  State<GyroPage> createState() => _GyroPageState();
}

class _ChatMessage {
  final bool fromUser;
  String text;
  _ChatMessage({required this.fromUser, required this.text});
}

class _GyroPageState extends State<GyroPage> with WidgetsBindingObserver {
  final GyroMascotController _mascot = GyroMascotController();
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();
  final List<_ChatMessage> _messages = [];

  GyroMood _mood = GyroMood.hello;
  String _bubble = GyroReplies.greeting;
  bool _busy = false; // sedang berpikir / menjawab
  bool _showTyping = false;
  Timer? _bubbleReset;
  Timer? _stream;
  int _session = 0;

  bool get _chatMode => _messages.isNotEmpty;

  String get _restingBubble => _chatMode
      ? 'Ada lagi yang mau kamu tanyakan?'
      : GyroReplies.greeting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mascot.onMoodChanged = _onMascotMood;
    _mascot.onTouched = _onMascotTouched;
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _session++;
    _bubbleReset?.cancel();
    _stream?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _mascot.resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _mascot.pause();
    }
  }

  // Event maskot

  void _setMood(GyroMood mood) {
    _mascot.setMood(mood);
    if (mounted) setState(() => _mood = mood);
  }

  void _onMascotMood(GyroMood mood) {
    if (!mounted) return;
    setState(() => _mood = mood);
  }

  void _onMascotTouched(String part, GyroMood? mood) {
    if (!mounted) return;
    String text;
    if (part == 'busy') {
      text = 'Sebentar ya, aku lagi fokus jawab...';
    } else {
      switch (mood) {
        case GyroMood.pat:
          text = 'Hehe, makasih udah dielus!';
          break;
        case GyroMood.giggle:
          text = 'Hihi, geli tau!';
          break;
        case GyroMood.poke:
          text = 'Eh! Kaget aku...';
          break;
        case GyroMood.happy:
          text = 'Yeay! Seneng banget diajak main!';
          break;
        default:
          text = 'Halo lagi!';
      }
    }
    _showBubble(text, resetAfter: const Duration(milliseconds: 2600));
  }

  void _showBubble(String text, {Duration? resetAfter}) {
    _bubbleReset?.cancel();
    setState(() => _bubble = text);
    if (resetAfter != null) {
      _bubbleReset = Timer(resetAfter, () {
        if (!mounted || _busy) return;
        setState(() => _bubble = _restingBubble);
      });
    }
  }

  // Input

  void _onInputChanged(String text) {
    if (_busy) return;
    if (text.trim().isNotEmpty) {
      if (_mood != GyroMood.listening) {
        _setMood(GyroMood.listening);
        _showBubble('Aku dengerin kok, lanjut aja...');
      }
      _mascot.pulse(0.6);
    } else {
      _setMood(GyroMood.idle);
      _showBubble(_restingBubble);
    }
  }

  void _onFocusChanged() {
    if (!_focus.hasFocus && _input.text.trim().isEmpty && !_busy) {
      if (_mood == GyroMood.listening) _setMood(GyroMood.idle);
    }
    if (mounted) setState(() {});
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _busy) return;
    final session = _session;
    bool alive() => mounted && session == _session;

    final reply = GyroReplies.answer(text);
    _input.clear();
    _bubbleReset?.cancel();
    setState(() {
      _messages.add(_ChatMessage(fromUser: true, text: text));
      _busy = true;
      _showTyping = true;
      _bubble = reply.thinking;
    });
    _setMood(GyroMood.thinking);
    _scrollToEnd();

    // "Menunggu respons AI"
    await Future<void>.delayed(const Duration(milliseconds: 1900));
    if (!alive()) return;

    // Jawaban masuk → Eureka lalu Talk, teks muncul bertahap
    final answer = _ChatMessage(fromUser: false, text: '');
    final answerStart = DateTime.now();
    setState(() {
      _showTyping = false;
      _messages.add(answer);
      _bubble = reply.isThanks ? 'Sama-sama!' : 'Nah, ketemu!';
    });
    _setMood(GyroMood.answer);
    _scrollToEnd();

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!alive()) return;
    await _streamText(answer, reply.answer);
    if (!alive()) return;

    // Biarkan lompatan Eureka selesai (2,6 dtk) + sedikit waktu "Talk"
    final elapsed = DateTime.now().difference(answerStart);
    const minAnswer = Duration(milliseconds: 3300);
    if (elapsed < minAnswer) {
      await Future<void>.delayed(minAnswer - elapsed);
      if (!alive()) return;
    }

    setState(() => _busy = false);
    if (reply.isThanks) {
      _setMood(GyroMood.happy);
      _showBubble('Yeay! Semangat ya!',
          resetAfter: const Duration(milliseconds: 2400));
    } else if (_input.text.trim().isNotEmpty) {
      _setMood(GyroMood.listening);
      _showBubble('Aku dengerin kok, lanjut aja...');
    } else {
      _setMood(GyroMood.idle);
      _showBubble(_restingBubble);
    }
  }

  Future<void> _streamText(_ChatMessage target, String full) {
    final done = Completer<void>();
    var index = 0;
    _stream?.cancel();
    _stream = Timer.periodic(const Duration(milliseconds: 28), (timer) {
      if (!mounted) {
        timer.cancel();
        if (!done.isCompleted) done.complete();
        return;
      }
      index = math.min(full.length, index + 2);
      setState(() => target.text = full.substring(0, index));
      _scrollToEnd(animate: false);
      if (index >= full.length) {
        timer.cancel();
        if (!done.isCompleted) done.complete();
      }
    });
    return done.future;
  }

  void _scrollToEnd({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic);
      } else {
        _scroll.jumpTo(target);
      }
    });
  }

  // Build

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final double topInset = mq.padding.top;
    final bool keyboardOpen = mq.viewInsets.bottom > 0;
    final double bottomSafe = keyboardOpen ? 0 : mq.padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _GyroColors.bgBottom,
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final layout = _GyroLayout.compute(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              topInset: topInset,
              bottomSafe: bottomSafe,
              keyboardOpen: keyboardOpen,
              chatMode: _chatMode,
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mascot.setFraming(
                feetX: layout.feetX,
                feetY: layout.feetY,
                height: layout.mascotHeight,
              );
            });
            return _buildStack(layout, topInset);
          },
        ),
      ),
    );
  }

  Widget _buildStack(_GyroLayout l, double topInset) {
    const duration = Duration(milliseconds: 450);
    const curve = Curves.easeOutCubic;
    final platformW = l.mascotHeight * 1.232;
    final platformH = l.mascotHeight * 0.264;

    return Stack(
      children: [
        // Latar gradasi
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_GyroColors.bgTop, _GyroColors.bgBottom],
              ),
            ),
          ),
        ),

        // Piringan tempat Gyro berdiri
        AnimatedPositioned(
          duration: duration,
          curve: curve,
          left: l.feetX - platformW / 2,
          top: l.feetY - platformH * (30 / 66),
          width: platformW,
          height: platformH,
          child: const _GyroPlatform(),
        ),

        // Maskot 3D (WebView transparan selebar layar)
        if (GyroMascotView.isSupported)
          Positioned.fill(child: GyroMascotView(controller: _mascot))
        else
          AnimatedPositioned(
            duration: duration,
            curve: curve,
            left: l.feetX - l.mascotHeight * 0.4,
            top: l.feetY - l.mascotHeight,
            width: l.mascotHeight * 0.8,
            height: l.mascotHeight,
            child: const FittedBox(
              child: Icon(Icons.smart_toy_rounded,
                  color: _GyroColors.secondary),
            ),
          ),

        // Header: Kembali + status
        Positioned(
          top: topInset + 8,
          left: 16,
          child: _BackButton(onTap: () => Navigator.of(context).maybePop()),
        ),
        Positioned(
          top: topInset + 10,
          right: 16,
          child: _StatusPill(mood: _mood),
        ),

        // Gelembung ucapan Gyro
        AnimatedPositioned(
          duration: duration,
          curve: curve,
          top: topInset + (_chatMode ? 74 : 72),
          left: 16,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: l.showBubble ? 1 : 0,
            child: _SpeechBubble(text: _bubble),
          ),
        ),

        // Bottom sheet
        AnimatedPositioned(
          duration: duration,
          curve: curve,
          left: 0,
          right: 0,
          bottom: 0,
          height: l.sheetHeight,
          child: _buildSheet(l),
        ),
      ],
    );
  }

  Widget _buildSheet(_GyroLayout l) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -6),
            blurRadius: 20,
            color: Color(0x4DA3B0C7), // #A3B0C7 30%
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(top: l.sheetPadTop, bottom: 22 + l.bottomSafe),
        child: Column(
          children: [
            Expanded(
              child: _chatMode
                  ? _buildChatList()
                  : AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: l.showHint ? 1 : 0,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            GyroReplies.hint,
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                              fontFamily: _GyroColors.font,
                              fontSize: 14,
                              height: 1.3,
                              color: _GyroColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            if (_chatMode) const SizedBox(height: 12),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    final itemCount = _messages.length + (_showTyping ? 1 : 0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth - 32;
        return ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i >= _messages.length) {
              return const Align(
                alignment: Alignment.centerLeft,
                child: _TypingIndicator(),
              );
            }
            final m = _messages[i];
            return m.fromUser
                ? Align(
                    alignment: Alignment.centerRight,
                    child: _UserBubble(text: m.text, maxWidth: w * 0.68),
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: _GyroBubble(text: m.text, maxWidth: w * 0.76),
                  );
          },
        );
      },
    );
  }

  Widget _buildFooter() {
    final suggestions = _chatMode
        ? GyroReplies.chatSuggestions
        : GyroReplies.introSuggestions;
    return SizedBox(
      height: _GyroLayout.footerHeight,
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _QuickReplyChip(
                label: suggestions[i],
                enabled: !_busy,
                onTap: () => _send(suggestions[i]),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: _GyroColors.border),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _InputField(
                    controller: _input,
                    focusNode: _focus,
                    onChanged: _onInputChanged,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 10),
                _SendButton(enabled: !_busy, onTap: () => _send()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Layout responsif

class _GyroLayout {
  static const double footerHeight = 121;

  final double sheetHeight;
  final double sheetPadTop;
  final double bottomSafe;
  final double feetX;
  final double feetY;
  final double mascotHeight;
  final bool showHint;
  final bool showBubble;

  const _GyroLayout({
    required this.sheetHeight,
    required this.sheetPadTop,
    required this.bottomSafe,
    required this.feetX,
    required this.feetY,
    required this.mascotHeight,
    required this.showHint,
    required this.showBubble,
  });

  factory _GyroLayout.compute({
    required double width,
    required double height,
    required double topInset,
    required double bottomSafe,
    required bool keyboardOpen,
    required bool chatMode,
  }) {
    final headerBottom = topInset + 56;
    double sheetH;
    double padTop;
    bool showHint = false;

    if (!chatMode) {
      // Perhitungan jarak tata letak panel bawah
      showHint = !keyboardOpen;
      padTop = showHint ? 28 : 18;
      sheetH = padTop + (showHint ? 139 : 0) + footerHeight + 22 + bottomSafe;
    } else {
      // Sheet mulai di bawah status bar
      padTop = 22;
      final minSheet = padTop + 150 + 12 + footerHeight + 22 + bottomSafe;
      final desiredTop = topInset + 312;
      final top = math.min(desiredTop, height - minSheet);
      sheetH = height - top;
    }
    sheetH = sheetH.clamp(0.0, height);

    final sheetTop = height - sheetH;
    final area = math.max(0.0, sheetTop - headerBottom);

    double mascotH;
    double feetY;
    if (!chatMode) {
      // Tinggi Gyro, kaki di atas sheet
      mascotH = math.min(250.0, area * 0.56);
      feetY = sheetTop - (area - mascotH) * 0.717;
    } else {
      // Tinggi Gyro, kaki di atas sheet
      mascotH = math.min(172.0, area * 0.67);
      feetY = sheetTop - (area - mascotH) * 0.43;
    }
    mascotH = math.max(mascotH, 40);

    return _GyroLayout(
      sheetHeight: sheetH,
      sheetPadTop: padTop,
      bottomSafe: bottomSafe,
      feetX: width / 2 + 16 * width / 402,
      feetY: feetY,
      mascotHeight: mascotH,
      showHint: showHint,
      showBubble: area > 140,
    );
  }
}

// Warna & gaya (Design System ITLG)

class _GyroColors {
  static const String font = 'Montserrat';
  static const Color primary = Color(0xFF850909);
  static const Color secondary = Color(0xFF2369B7);
  static const Color bgTop = Color(0xFFF8FAFC);
  static const Color bgBottom = Color(0xFFE8ECF1);
  static const Color surfaceDark = Color(0xFFF5F5F5);
  static const Color text = Color(0xFF0A0B0C);
  static const Color textMuted = Color(0xFF5B636B);
  static const Color placeholder = Color(0xFF6B7280);
  static const Color border = Color(0xFFE3E6EA);
  static const Color inputBg = Color(0xFFF9FAFB);
  static const Color success = Color(0xFF2E9B5B);
  static const Color warning = Color(0xFFD99A00);

  /// Efek bayangan kartu dan tombol.
  static const List<BoxShadow> outlineShadow = [
    BoxShadow(offset: Offset(1, 1), blurRadius: 3, color: Color(0x0F000000)),
    BoxShadow(offset: Offset(4, 5), blurRadius: 6, color: Color(0x0D000000)),
    BoxShadow(offset: Offset(8, 12), blurRadius: 8, color: Color(0x08000000)),
    BoxShadow(offset: Offset(14, 21), blurRadius: 10, color: Color(0x03000000)),
  ];

  static const List<BoxShadow> primaryShadow = [
    ...outlineShadow,
    BoxShadow(offset: Offset(0, 4), blurRadius: 4, color: Color(0x40850909)),
  ];
}

// Komponen

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _GyroColors.outlineShadow,
      ),
      child: Material(
        color: _GyroColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: const SizedBox(
            height: 40,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded,
                      size: 24, color: _GyroColors.primary),
                  SizedBox(width: 7),
                  Text(
                    'Kembali',
                    style: TextStyle(
                      fontFamily: _GyroColors.font,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: _GyroColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final GyroMood mood;
  const _StatusPill({required this.mood});

  (String, Color) get _style {
    switch (mood) {
      case GyroMood.hello:
        return ('Menyapa', _GyroColors.success);
      case GyroMood.idle:
        return ('Santai', _GyroColors.success);
      case GyroMood.listening:
        return ('Mendengarkan', _GyroColors.warning);
      case GyroMood.thinking:
        return ('Berpikir', _GyroColors.secondary);
      case GyroMood.answer:
      case GyroMood.talking:
        return ('Menjawab', _GyroColors.primary);
      case GyroMood.poke:
      case GyroMood.giggle:
      case GyroMood.pat:
      case GyroMood.happy:
        return ('Senang', _GyroColors.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = _style;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _GyroColors.outlineShadow,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RadioDot(color: color),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                label,
                key: ValueKey(label),
                style: const TextStyle(
                  fontFamily: _GyroColors.font,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: _GyroColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final Color color;
  const _RadioDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.6),
      ),
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _GyroColors.outlineShadow,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topLeft,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(anim),
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
          child: Text(
            text,
            key: ValueKey(text),
            style: const TextStyle(
              fontFamily: _GyroColors.font,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.3,
              color: _GyroColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _GyroPlatform extends StatelessWidget {
  const _GyroPlatform();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _PlatformPainter());
  }
}

/// Piringan Gyro
class _PlatformPainter extends CustomPainter {
  const _PlatformPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 308, sy = size.height / 66;
    Rect r(double x, double y, double w, double h) =>
        Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy);

    // Lapisan dasar piringan maskot
    final outer = r(0, 0, 308, 66);
    final outerPath = Path()..addOval(outer);
    canvas.drawPath(outerPath, Paint()..color = Colors.white);
    canvas.save();
    canvas.clipPath(outerPath);
    for (final (offset, blur, color) in [
      (Offset(6.3 * sx, 6.3 * sy), 6.3 * sx, const Color(0x1F000000)),
      (Offset(0, -3.1 * sy), 6.3 * sx, const Color(0x0D000000)),
    ]) {
      final ring = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(outer.inflate(40))
        ..addOval(outer);
      canvas.drawPath(
        ring.shift(offset),
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2),
      );
    }
    canvas.restore();

    // Lapisan tengah piringan maskot
    final mid = r(42, 14, 223, 31);
    canvas.drawOval(
      mid.shift(Offset(0, 6.3 * sy)),
      Paint()
        ..color = const Color(0x1A000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.1 * sx / 2),
    );
    canvas.drawOval(mid, Paint()..color = const Color(0xFFF7F7F7));

    // Lapisan dalam piringan maskot
    canvas.drawOval(r(80, 22, 146, 16), Paint()..color = const Color(0xFFE6E6E6));
  }

  @override
  bool shouldRepaint(covariant _PlatformPainter oldDelegate) => false;
}

class _UserBubble extends StatelessWidget {
  final String text;
  final double maxWidth;
  const _UserBubble({required this.text, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _GyroColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _GyroColors.primaryShadow,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: _GyroColors.font,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.3,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _GyroBubble extends StatelessWidget {
  final String text;
  final double maxWidth;
  const _GyroBubble({required this.text, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth, minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _GyroColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: _GyroColors.font,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.3,
          color: _GyroColors.text,
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 36,
      decoration: BoxDecoration(
        color: _GyroColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final t = (_c.value - i * 0.18) % 1.0;
            final wave = t < 0.5 ? math.sin(t * 2 * math.pi) : 0.0;
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
              child: Transform.translate(
                offset: Offset(0, -3 * wave),
                child: Opacity(
                  opacity: 0.45 + 0.55 * wave.clamp(0.0, 1.0),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _GyroColors.placeholder,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _QuickReplyChip({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.white,
        shape: const StadiumBorder(
          side: BorderSide(color: _GyroColors.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: _GyroColors.font,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  color: _GyroColors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: CustomPaint(
        foregroundPainter: const _InnerShadowPainter(radius: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _GyroColors.inputBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: _GyroColors.primary,
                style: const TextStyle(
                  fontFamily: _GyroColors.font,
                  fontSize: 14,
                  height: 1.3,
                  color: _GyroColors.text,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: 'Tanya sesuatu ke Gyro...',
                  hintStyle: TextStyle(
                    fontFamily: _GyroColors.font,
                    fontSize: 14,
                    height: 1.3,
                    color: _GyroColors.placeholder,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _SendButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: _GyroColors.primaryShadow,
        ),
        child: Material(
          color: _GyroColors.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onTap : null,
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.arrow_forward_rounded,
                  size: 22, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/// Efek bayangan kolom input pesan.
class _InnerShadowPainter extends CustomPainter {
  final double radius;
  const _InnerShadowPainter({required this.radius});

  static const List<BoxShadow> _shadows = [
    BoxShadow(offset: Offset(4, 4), blurRadius: 4, color: Color(0x1F000000)),
    BoxShadow(offset: Offset(0, -2), blurRadius: 4, color: Color(0x0D000000)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(rrect);
    for (final s in _shadows) {
      final paint = Paint()
        ..color = s.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.blurSigma);
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect((Offset.zero & size).inflate(30))
        ..addRRect(rrect);
      canvas.drawPath(path.shift(s.offset), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InnerShadowPainter old) => old.radius != radius;
}
