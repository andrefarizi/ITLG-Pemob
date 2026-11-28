import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Layanan native untuk menampilkan push notification di status bar HP Android.
class DeviceNotificationService extends ChangeNotifier {
  static final DeviceNotificationService instance =
      DeviceNotificationService._internal();

  DeviceNotificationService._internal() {
    _channel.setMethodCallHandler(_handleNativeCallback);
  }

  static const MethodChannel _channel =
      MethodChannel('com.example.itlg_mobile/notifications');

  final Map<String, bool> _roleEnabled = {
    'praktikan': true,
    'aslab': true,
    'laboran': true,
    'dosen': true,
  };

  bool _permissionAskedOnce = false;
  Future<bool>? _permissionFuture;
  VoidCallback? _onTapHandler;

  bool isEnabledForRole(String role) => _roleEnabled[role] ?? true;

  Future<bool> setEnabledForRole(String role, bool enabled) async {
    _roleEnabled[role] = enabled;
    notifyListeners();
    if (enabled) {
      final granted = await requestPermission();
      if (granted) {
        await show(
          id: 'toggle-$role-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Notifikasi Push Aktif',
          body: 'Pemberitahuan real-time ITLG Mobile aktif di perangkat ini.',
        );
      }
      return granted;
    }
    return true;
  }

  void registerTapHandler(VoidCallback handler) {
    _onTapHandler = handler;
    _consumeInitialTapIfAny();
  }

  void unregisterTapHandler(VoidCallback handler) {
    if (_onTapHandler == handler) {
      _onTapHandler = null;
    }
  }

  Future<dynamic> _handleNativeCallback(MethodCall call) async {
    if (call.method == 'onNotificationTapped') {
      _onTapHandler?.call();
    }
  }

  Future<void> _consumeInitialTapIfAny() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final tapped =
          await _channel.invokeMethod<bool>('consumeInitialTap') ?? false;
      if (tapped) {
        _onTapHandler?.call();
      }
    } catch (_) {}
  }

  Future<bool> hasPermission() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('hasNotificationPermission') ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (_permissionFuture != null) return _permissionFuture!;
    final fut = _doRequestPermission();
    _permissionFuture = fut;
    try {
      return await fut;
    } finally {
      _permissionFuture = null;
    }
  }

  Future<bool> _doRequestPermission() async {
    try {
      return await _channel
              .invokeMethod<bool>('requestNotificationPermission') ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Minta izin notifikasi satu kali saat pengguna masuk ke beranda aplikasi.
  Future<bool> requestPermissionOnce() async {
    if (_permissionFuture != null) return _permissionFuture!;
    if (_permissionAskedOnce) return hasPermission();
    _permissionAskedOnce = true;
    final has = await hasPermission();
    if (has) return true;
    return requestPermission();
  }

  /// Tampilkan notifikasi pada sistem Android (heads-up banner + status bar).
  Future<bool> show({
    required String id,
    required String title,
    required String body,
    String? forRole,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (forRole != null && !isEnabledForRole(forRole)) return false;

    var allowed = await hasPermission();
    if (!allowed && !_permissionAskedOnce) {
      _permissionAskedOnce = true;
      allowed = await requestPermission();
    }
    if (!allowed) return false;

    final int notifId = id.hashCode & 0x7fffffff;
    try {
      return await _channel.invokeMethod<bool>('showNotification', {
            'id': notifId == 0 ? 1001 : notifId,
            'title': title,
            'body': body,
          }) ??
          false;
    } catch (e) {
      debugPrint('[DeviceNotification] Gagal menampilkan notifikasi HP: $e');
      return false;
    }
  }
}
