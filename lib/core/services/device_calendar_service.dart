import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'jadwal_sync_service.dart';

class CalendarSyncResult {
  final bool permissionGranted;
  final bool synced;
  final int count;
  final String calendarName;

  const CalendarSyncResult({
    required this.permissionGranted,
    required this.synced,
    required this.count,
    this.calendarName = 'Kalender Perangkat',
  });
}

/// Service native untuk meminta izin Kalender Android (READ/WRITE_CALENDAR)
class DeviceCalendarService {
  static final DeviceCalendarService instance = DeviceCalendarService._();
  DeviceCalendarService._();

  static const MethodChannel _channel =
      MethodChannel('com.example.itlg_mobile/calendar');

  bool _promptedOnce = false;

  Future<bool> hasPermission() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('hasCalendarPermission') ?? false;
    } catch (e) {
      debugPrint('[DeviceCalendar] hasPermission error: $e');
      return false;
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('requestCalendarPermission') ??
          false;
    } catch (e) {
      debugPrint('[DeviceCalendar] requestPermission error: $e');
      return false;
    }
  }

  /// Konversi dayIndex (0=Sen.. 5=Sab) + jam (HH:mm) ke DateTime minggu ini
  (DateTime start, DateTime end) _nextOccurrence(
      int dayIndex, String startTime, String endTime) {
    final now = DateTime.now();
    // Weekday Dart: 1 = Senin.. 7 = Minggu
    final targetWeekday = (dayIndex + 1).clamp(1, 6);
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final dayDate = monday.add(Duration(days: targetWeekday - 1));

    final sParts = startTime.split(':');
    final eParts = endTime.split(':');
    final sHour = sParts.isNotEmpty ? (int.tryParse(sParts[0]) ?? 8) : 8;
    final sMin = sParts.length > 1 ? (int.tryParse(sParts[1]) ?? 0) : 0;
    final eHour = eParts.isNotEmpty ? (int.tryParse(eParts[0]) ?? 9) : 9;
    final eMin = eParts.length > 1 ? (int.tryParse(eParts[1]) ?? 40) : 40;

    final start =
        DateTime(dayDate.year, dayDate.month, dayDate.day, sHour, sMin);
    final end = DateTime(dayDate.year, dayDate.month, dayDate.day, eHour, eMin);
    return (start, end);
  }

  /// Minta izin kalender otomatis satu kali saat pengguna membuka Beranda
  Future<CalendarSyncResult> ensurePermissionAndSyncOnce(
      List<PraktikumScheduleRecord> schedules) async {
    if (_promptedOnce) {
      final granted = await hasPermission();
      if (!granted) {
        return const CalendarSyncResult(
            permissionGranted: false, synced: false, count: 0);
      }
      return syncSchedules(schedules, askPermission: false);
    }
    _promptedOnce = true;
    return syncSchedules(schedules, askPermission: true);
  }

  /// Sinkronkan seluruh jadwal praktikum ke Kalender perangkat Android.
  Future<CalendarSyncResult> syncSchedules(
    List<PraktikumScheduleRecord> schedules, {
    bool askPermission = true,
  }) async {
    if (kIsWeb || !Platform.isAndroid || schedules.isEmpty) {
      return const CalendarSyncResult(
          permissionGranted: false, synced: false, count: 0);
    }

    final granted = askPermission
        ? await requestPermission()
        : await hasPermission();
    if (!granted) {
      return const CalendarSyncResult(
          permissionGranted: false, synced: false, count: 0);
    }

    final payload = <Map<String, dynamic>>[];
    for (final s in schedules) {
      final (start, end) = _nextOccurrence(s.dayIndex, s.startTime, s.endTime);
      payload.add({
        'id': s.id,
        'title': 'Praktikum ${s.courseName} (${s.sessionShort})',
        'description':
            '${s.kelas} • Durasi 1 jam 40 menit • Asisten: ${s.asisten} • ITLG Mobile',
        'location': '${s.room}, Fasilkom-TI USU',
        'startMillis': start.millisecondsSinceEpoch,
        'endMillis': end.millisecondsSinceEpoch,
        'rrule': 'FREQ=WEEKLY;COUNT=12',
      });
    }

    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'syncSchedulesToCalendar',
        payload,
      );
      final ok = (raw?['ok'] as bool?) ?? false;
      final count = (raw?['count'] as num?)?.toInt() ?? 0;
      final calName =
          (raw?['calendarName'] as String?) ?? 'Kalender Perangkat';
      debugPrint(
          '[DeviceCalendar] Sync selesai: ok=$ok, count=$count ($calName)');
      return CalendarSyncResult(
        permissionGranted: true,
        synced: ok,
        count: count,
        calendarName: calName,
      );
    } catch (e) {
      debugPrint('[DeviceCalendar] syncSchedules error: $e');
      return const CalendarSyncResult(
          permissionGranted: true, synced: false, count: 0);
    }
  }

  Future<void> openDeviceCalendar() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>(
        'openDeviceCalendar',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }
}
