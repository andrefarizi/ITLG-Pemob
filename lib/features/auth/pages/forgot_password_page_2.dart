import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../widgets/auth_design.dart';
import 'forgot_password_page_3.dart';

/// Lupa Password – langkah 2: OTP (Figma "Lupa Password 2").
class ForgotPasswordPage2 extends StatefulWidget {
  final String targetIdentifier;

  const ForgotPasswordPage2({
    super.key,
    this.targetIdentifier = 'email USU anda',
  });

  @override
  State<ForgotPasswordPage2> createState() => _ForgotPasswordPage2State();
}

class _ForgotPasswordPage2State extends State<ForgotPasswordPage2> {
  static const int _length = 6;
  static const int _resendSeconds = 60;

  final List<TextEditingController> _boxes =
      List.generate(_length, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(_length, (_) => FocusNode());

  Timer? _timer;
  int _countdown = _resendSeconds;
  bool _loading = false;
  String? _error;

  String get _code => _boxes.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _startCountdown();
    for (final n in _nodes) {
      n.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _boxes) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _onBoxChanged(int i, String value) {
    if (_error != null) setState(() => _error = null);
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      // Tempel (paste) beberapa digit sekaligus
      for (var k = 0; k < _length; k++) {
        final at = i + k;
        if (at >= _length || k >= digits.length) break;
        _boxes[at].text = digits[k];
      }
      final next = i + digits.length >= _length ? _length - 1 : i + digits.length;
      _nodes[next].requestFocus();
    } else {
      _boxes[i].text = digits;
      _boxes[i].selection = TextSelection.collapsed(offset: digits.length);
      if (digits.isNotEmpty && i < _length - 1) _nodes[i + 1].requestFocus();
    }
    setState(() {});
    if (_code.length == _length) FocusScope.of(context).unfocus();
  }

  KeyEventResult _onKey(int i, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _boxes[i].text.isEmpty &&
        i > 0) {
      _boxes[i - 1].clear();
      _nodes[i - 1].requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _confirm() async {
    if (_code.length < _length) {
      setState(() => _error = 'Masukkan 6 digit kode OTP');
      return;
    }
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordPage3()),
    );
  }

  void _resend() {
    for (final c in _boxes) {
      c.clear();
    }
    _nodes.first.requestFocus();
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Kode OTP baru dikirim ke ${widget.targetIdentifier}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      children: [
        const ResetPasswordHeader(step: 2),
        const SizedBox(height: 24),
        ItlgCard(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Kode OTP', style: ItlgText.style()),
              const SizedBox(height: 13),
              Row(
                children: [
                  for (var i = 0; i < _length; i++) ...[
                    Expanded(child: _otpBox(i)),
                    if (i < _length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: ItlgText.style(size: 12, color: ItlgColors.error)),
              ],
              const SizedBox(height: 18),
              const AuthNotice(),
              const SizedBox(height: 18),
              ItlgPrimaryButton(
                label: 'Konfirmasi OTP',
                leadingIcon: Icons.mark_email_read_rounded,
                loading: _loading,
                onPressed: _confirm,
              ),
              const SizedBox(height: 12),
              ItlgLinkRow(
                text: 'Tidak Menerima Kode?',
                link: _countdown > 0
                    ? 'Kirim Ulang (${_countdown}s)'
                    : 'Kirim Ulang >',
                onTap: _countdown > 0 ? null : _resend,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _otpBox(int i) {
    final focused = _nodes[i].hasFocus;
    return AspectRatio(
      aspectRatio: 50 / 63,
      child: InnerShadowBox(
        radius: 12,
        color: ItlgColors.surfaceWhite,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focused
                  ? ItlgColors.primary
                  : (_error != null
                      ? ItlgColors.error.withValues(alpha: 0.5)
                      : Colors.transparent),
              width: 1.4,
            ),
          ),
          child: Center(
            child: Focus(
              onKeyEvent: (_, e) => _onKey(i, e),
              child: TextField(
                controller: _boxes[i],
                focusNode: _nodes[i],
                autofocus: i == 0,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: ItlgColors.primary,
                style: ItlgText.style(size: 22, weight: FontWeight.w700),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: '',
                ),
                onChanged: (v) => _onBoxChanged(i, v),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
