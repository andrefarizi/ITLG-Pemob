import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// State animasi Gyro (sama dengan `STATE_TO_CLIP` di gyro/mascot.js).
enum GyroMood {
  idle,
  hello,
  listening,
  thinking,
  answer,
  talking,
  poke,
  giggle,
  pat,
  happy;

  static GyroMood? tryParse(String? value) {
    for (final m in GyroMood.values) {
      if (m.name == value) return m;
    }
    return null;
  }
}

/// Pengendali maskot 3D.
class GyroMascotController {
  WebViewController? _web;
  bool _ready = false;
  _Framing? _framing;
  GyroMood? _pendingMood;

  /// Dipanggil setiap maskot berganti state (termasuk karena disentuh).
  ValueChanged<GyroMood>? onMoodChanged;

  /// Dipanggil saat maskot disentuh. `part`: head | body | many | busy.
  void Function(String part, GyroMood? mood)? onTouched;

  bool get isReady => _ready;

  void setMood(GyroMood mood) {
    if (!_ready) {
      _pendingMood = mood;
      return;
    }
    _run("gyro.setState('${mood.name}')");
  }

  /// Anggukan kecil, panggil setiap user mengetik satu huruf.
  void pulse([double strength = 1]) => _run('gyro.pulse($strength)');

  /// Arahkan tatapan (-1..1). y positif = melihat ke bawah.
  void lookAt(double x, double y) => _run('gyro.lookAt($x, $y)');

  /// Posisi kaki maskot (koordinat lokal widget) dan tinggi maskot dalam px.
  void setFraming({
    required double feetX,
    required double feetY,
    required double height,
    bool animate = true,
  }) {
    final next = _Framing(feetX, feetY, height);
    if (_framing != null && _framing!.closeTo(next)) return;
    _framing = next;
    if (_ready || _web != null) {
      _run('gyro.setFraming(${next.feetX.toStringAsFixed(1)}, '
          '${next.feetY.toStringAsFixed(1)}, '
          '${next.height.toStringAsFixed(1)}, $animate)');
    }
  }

  void pause() => _run('gyro.pause()');
  void resume() => _run('gyro.resume()');

  void _attach(WebViewController web) => _web = web;

  void _onPageLoaded() {
    final f = _framing;
    if (f != null) {
      _run('gyro.setFraming(${f.feetX}, ${f.feetY}, ${f.height}, false)');
    }
  }

  void _onReady() {
    _ready = true;
    _onPageLoaded();
    final mood = _pendingMood ?? GyroMood.hello;
    _pendingMood = null;
    _run("gyro.setState('${mood.name}')");
  }

  void _run(String js) {
    final web = _web;
    if (web == null) return;
    web.runJavaScript('window.gyro && $js').catchError((_) {});
  }
}

class _Framing {
  final double feetX;
  final double feetY;
  final double height;
  const _Framing(this.feetX, this.feetY, this.height);

  bool closeTo(_Framing o) =>
      (feetX - o.feetX).abs() < 0.5 &&
      (feetY - o.feetY).abs() < 0.5 &&
      (height - o.height).abs() < 0.5;
}

/// Menampilkan maskot Gyro 3D (three.js di WebView, latar transparan).
class GyroMascotView extends StatefulWidget {
  final GyroMascotController controller;

  const GyroMascotView({super.key, required this.controller});

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  State<GyroMascotView> createState() => _GyroMascotViewState();
}

class _GyroMascotViewState extends State<GyroMascotView> {
  WebViewController? _web;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (!GyroMascotView.isSupported) return;
    final web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel('GyroBridge', onMessageReceived: _onMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => widget.controller._onPageLoaded(),
        ),
      );
    widget.controller._attach(web);
    web.loadFlutterAsset('assets/gyro/gyro.html');
    _web = web;
  }

  void _onMessage(JavaScriptMessage message) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(message.message) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final controller = widget.controller;
    switch (data['type']) {
      case 'ready':
        controller._onReady();
        if (mounted) setState(() => _visible = true);
        break;
      case 'state':
        final mood = GyroMood.tryParse(data['state'] as String?);
        if (mood != null) controller.onMoodChanged?.call(mood);
        break;
      case 'touch':
        controller.onTouched?.call(
          data['part'] as String? ?? 'body',
          GyroMood.tryParse(data['state'] as String?),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final web = _web;
    if (web == null) return const _GyroPlaceholder();
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 350),
      child: WebViewWidget(
        controller: web,
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
        },
      ),
    );
  }
}

class _GyroPlaceholder extends StatelessWidget {
  const _GyroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Maskot 3D Gyro hanya tampil\ndi Android / iOS',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF5B636B), fontSize: 12),
      ),
    );
  }
}
