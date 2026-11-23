import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/laboran/laboran_store.dart';
import '../../features/praktikan/praktikan_store.dart';
import 'device_calendar_service.dart';
import 'notification_sync_service.dart';
import 'supabase_service.dart';

/// Data jadwal praktikum mingguan yang tersinkron ke Supabase & Kalender HP.
class PraktikumScheduleRecord {
  final String id;
  final String courseId;
  final String courseName;
  final String kelas;

  /// 0 = Sen, 1 = Sel, 2 = Rab, 3 = Kam, 4 = Jum, 5 = Sab.
  final int dayIndex;
  final String dayShort;
  final String startTime;
  final String endTime;
  final String room;
  final String asisten;
  final int weekNumber;
  final DateTime updatedAt;

  const PraktikumScheduleRecord({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.kelas,
    required this.dayIndex,
    required this.dayShort,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.asisten,
    this.weekNumber = 4,
    required this.updatedAt,
  });

  String get jadwalShort => '$dayShort • $startTime–$endTime WIB';

  /// Ekstrak label sesi ('Sesi C1' atau 'Sesi C2') dari nama kelas / id.
  String get sessionShort {
    final lower = kelas.toLowerCase();
    if (lower.contains('c2') || id.toLowerCase().endsWith('-c2')) {
      return 'Sesi C2';
    }
    return 'Sesi C1';
  }

  PraktikumScheduleRecord copyWith({
    int? dayIndex,
    String? dayShort,
    String? startTime,
    String? endTime,
    String? room,
    int? weekNumber,
    DateTime? updatedAt,
  }) {
    return PraktikumScheduleRecord(
      id: id,
      courseId: courseId,
      courseName: courseName,
      kelas: kelas,
      dayIndex: dayIndex ?? this.dayIndex,
      dayShort: dayShort ?? this.dayShort,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      asisten: asisten,
      weekNumber: weekNumber ?? this.weekNumber,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PraktikumScheduleRecord.fromJson(Map<String, dynamic> json) {
    final dayIdx = (json['day_index'] as num?)?.toInt() ?? 0;
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return PraktikumScheduleRecord(
      id: (json['id'] ?? '').toString(),
      courseId: (json['course_id'] ?? 'pemob').toString(),
      courseName: (json['course_name'] ?? 'Pemrograman Mobile').toString(),
      kelas: (json['kelas'] ?? 'Kelas C').toString(),
      dayIndex: dayIdx.clamp(0, 5),
      dayShort: (json['day_short'] ?? days[dayIdx.clamp(0, 5)]).toString(),
      startTime: (json['start_time'] ?? '08:00').toString(),
      endTime: (json['end_time'] ?? '09:40').toString(),
      room: (json['room'] ?? 'Lab Komputer 1').toString(),
      asisten: (json['asisten'] ?? 'Andi Pratama').toString(),
      weekNumber: (json['week_number'] as num?)?.toInt() ?? 4,
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Data pengumuman & perubahan jadwal (Aslab ↔ Praktikan) via Supabase.
class AnnouncementRecord {
  final String id;
  final String? courseId;

  /// 1 = Perubahan Jadwal, 2 = Umum, 3 = Penting.
  final int category;
  final String tag;
  final bool tagRed;
  final String title;
  final String body;
  final String author;
  final String? oldSchedule;
  final String? newSchedule;
  final String? room;
  final DateTime createdAt;

  const AnnouncementRecord({
    required this.id,
    this.courseId,
    required this.category,
    required this.tag,
    required this.tagRed,
    required this.title,
    required this.body,
    required this.author,
    this.oldSchedule,
    this.newSchedule,
    this.room,
    required this.createdAt,
  });

  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  PrakAnnouncement toPrakAnnouncement() {
    return PrakAnnouncement(
      tag: tag,
      tagRed: tagRed,
      time: relativeTime,
      title: title,
      body: body,
      author: author,
      category: category == 1 ? 1 : 2,
      scheduleBox: category == 1 && newSchedule != null && newSchedule!.isNotEmpty,
    );
  }

  factory AnnouncementRecord.fromJson(Map<String, dynamic> json) {
    final cat = (json['category'] as num?)?.toInt() ?? 1;
    return AnnouncementRecord(
      id: (json['id'] ?? '').toString(),
      courseId: json['course_id'] as String?,
      category: cat,
      tag: (json['tag'] ?? (cat == 1 ? 'Perubahan Jadwal' : 'Umum')).toString(),
      tagRed: (json['tag_red'] as bool?) ?? (cat != 2),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      author: (json['author'] ?? 'Asisten Lab').toString(),
      oldSchedule: json['old_schedule'] as String?,
      newSchedule: json['new_schedule'] as String?,
      room: json['room'] as String?,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Data permintaan & persetujuan peminjaman ruangan lab (Aslab ↔ Laboran).
class RoomBookingRecord {
  final String id;
  final String tag;
  final String labName;
  final String title;
  final String dateLabel;
  final String timeRange;
  final String initials;
  final String requesterName;
  final String requesterRole;
  final String reason;
  RoomStatus status;
  final DateTime createdAt;

  RoomBookingRecord({
    required this.id,
    required this.tag,
    required this.labName,
    required this.title,
    required this.dateLabel,
    required this.timeRange,
    required this.initials,
    required this.requesterName,
    this.requesterRole = 'Asisten Lab',
    required this.reason,
    this.status = RoomStatus.menunggu,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  RoomRequest toRoomRequest() => RoomRequest(
        tag: tag,
        lab: labName,
        title: title,
        date: dateLabel,
        time: timeRange,
        initials: initials,
        name: requesterName,
        role: requesterRole,
        reason: reason,
        status: status,
      );

  static RoomStatus parseStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'disetujui':
      case 'approved':
        return RoomStatus.disetujui;
      case 'ditolak':
      case 'rejected':
        return RoomStatus.ditolak;
      default:
        return RoomStatus.menunggu;
    }
  }

  static String serializeStatus(RoomStatus st) {
    switch (st) {
      case RoomStatus.disetujui:
        return 'disetujui';
      case RoomStatus.ditolak:
        return 'ditolak';
      case RoomStatus.menunggu:
        return 'menunggu';
    }
  }

  factory RoomBookingRecord.fromJson(Map<String, dynamic> json) {
    return RoomBookingRecord(
      id: (json['id'] ?? '').toString(),
      tag: (json['tag'] ?? 'Praktikum Pengganti').toString(),
      labName: (json['lab_name'] ?? 'Lab Komputer 1').toString(),
      title: (json['title'] ?? 'Praktikum Pengganti').toString(),
      dateLabel: (json['date_label'] ?? 'Kam, 01 Okt 2026').toString(),
      timeRange: (json['time_range'] ?? '13:00–14:40').toString(),
      initials: (json['requester_initials'] ?? 'AS').toString(),
      requesterName: (json['requester_name'] ?? 'Asisten Lab').toString(),
      requesterRole: (json['requester_role'] ?? 'Asisten Lab').toString(),
      reason: (json['reason'] ?? '').toString(),
      status: parseStatus(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Service pusat sinkronisasi Jadwal Praktikum & Pengumuman Perubahan Jadwal
/// ke Supabase + Realtime serta otomatis ke Kalender perangkat pengguna.
class JadwalSyncService extends ChangeNotifier {
  static final JadwalSyncService instance = JadwalSyncService._internal();
  JadwalSyncService._internal() {
    _seedDefaults();
  }

  final List<PraktikumScheduleRecord> _schedules = [];
  final List<AnnouncementRecord> _announcements = [];
  final List<RoomBookingRecord> _roomRequests = [];

  RealtimeChannel? _channel;
  bool _initialized = false;
  bool _backendAvailable = false;
  bool get isBackendAvailable => _backendAvailable;

  List<PraktikumScheduleRecord> get schedules => List.unmodifiable(_schedules);
  List<AnnouncementRecord> get announcements =>
      List.unmodifiable(_announcements);
  List<RoomBookingRecord> get roomRequests => List.unmodifiable(_roomRequests);

  int get pendingRoomRequestCount =>
      _roomRequests.where((r) => r.status == RoomStatus.menunggu).length;

  List<PraktikumScheduleRecord> schedulesForDay(int dayIndex) {
    return _schedules.where((s) => s.dayIndex == dayIndex).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  PraktikumScheduleRecord? scheduleForCourse(String courseId) {
    for (final s in _schedules) {
      if (s.courseId == courseId) return s;
    }
    return null;
  }

  void _seedDefaults() {
    final now = DateTime.now();
    _schedules
      ..clear()
      ..addAll([
        // 1. Pemrograman Mobile — Kom C (Senin) — 1 jam 40 menit per sesi
        PraktikumScheduleRecord(
          id: 'sched-pemob',
          courseId: 'pemob',
          courseName: 'Pemrograman Mobile',
          kelas: 'TIF 3001 - Kom C (Sesi C1)',
          dayIndex: 0,
          dayShort: 'Sen',
          startTime: '08:00',
          endTime: '09:40',
          room: 'Lab Komputer 1',
          asisten: 'Andi Pratama',
          weekNumber: 4,
          updatedAt: now,
        ),
        PraktikumScheduleRecord(
          id: 'sched-pemob-c2',
          courseId: 'pemob',
          courseName: 'Pemrograman Mobile',
          kelas: 'TIF 3001 - Kom C (Sesi C2)',
          dayIndex: 0,
          dayShort: 'Sen',
          startTime: '10:00',
          endTime: '11:40',
          room: 'Lab Komputer 1',
          asisten: 'Andi Pratama',
          weekNumber: 4,
          updatedAt: now,
        ),
        // 2. Desain Interaksi — Kom C (Selasa) — 1 jam 40 menit per sesi
        PraktikumScheduleRecord(
          id: 'sched-desain',
          courseId: 'desain',
          courseName: 'Desain Interaksi',
          kelas: 'TIF 3002 - Kom C (Sesi C1)',
          dayIndex: 1,
          dayShort: 'Sel',
          startTime: '08:00',
          endTime: '09:40',
          room: 'Lab Jaringan 2',
          asisten: 'Feri Gunawan',
          weekNumber: 4,
          updatedAt: now,
        ),
        PraktikumScheduleRecord(
          id: 'sched-desain-c2',
          courseId: 'desain',
          courseName: 'Desain Interaksi',
          kelas: 'TIF 3002 - Kom C (Sesi C2)',
          dayIndex: 1,
          dayShort: 'Sel',
          startTime: '10:00',
          endTime: '11:40',
          room: 'Lab Jaringan 2',
          asisten: 'Feri Gunawan',
          weekNumber: 4,
          updatedAt: now,
        ),
        // 3. Analisis Desain Jaringan — Kom C (Rabu) — 1 jam 40 menit per sesi
        PraktikumScheduleRecord(
          id: 'sched-adj',
          courseId: 'adj',
          courseName: 'Analisis Desain Jaringan',
          kelas: 'TIF 3003 - Kom C (Sesi C1)',
          dayIndex: 2,
          dayShort: 'Rab',
          startTime: '10:00',
          endTime: '11:40',
          room: 'Lab Jaringan 1',
          asisten: 'Sinta Marpaung',
          weekNumber: 4,
          updatedAt: now,
        ),
        PraktikumScheduleRecord(
          id: 'sched-adj-c2',
          courseId: 'adj',
          courseName: 'Analisis Desain Jaringan',
          kelas: 'TIF 3003 - Kom C (Sesi C2)',
          dayIndex: 2,
          dayShort: 'Rab',
          startTime: '13:00',
          endTime: '14:40',
          room: 'Lab Jaringan 1',
          asisten: 'Sinta Marpaung',
          weekNumber: 4,
          updatedAt: now,
        ),
        // 4. Machine Learning — Kom C (Kamis) — 1 jam 40 menit per sesi
        PraktikumScheduleRecord(
          id: 'sched-ml',
          courseId: 'ml',
          courseName: 'Machine Learning',
          kelas: 'TIF 3004 - Kom C (Sesi C1)',
          dayIndex: 3,
          dayShort: 'Kam',
          startTime: '13:00',
          endTime: '14:40',
          room: 'Lab AI & Data',
          asisten: 'Rizky Harahap',
          weekNumber: 4,
          updatedAt: now,
        ),
        PraktikumScheduleRecord(
          id: 'sched-ml-c2',
          courseId: 'ml',
          courseName: 'Machine Learning',
          kelas: 'TIF 3004 - Kom C (Sesi C2)',
          dayIndex: 3,
          dayShort: 'Kam',
          startTime: '15:00',
          endTime: '16:40',
          room: 'Lab AI & Data',
          asisten: 'Rizky Harahap',
          weekNumber: 4,
          updatedAt: now,
        ),
      ]);

    _announcements
      ..clear()
      ..addAll([
        AnnouncementRecord(
          id: 'seed-ann-1',
          courseId: 'ml',
          category: 1,
          tag: 'Perubahan Jadwal',
          tagRed: true,
          title: 'Jadwal Sesi C1 & C2 Kom C',
          body:
              'Praktikum Machine Learning Kom C (Sesi C1 13:00–14:40 & Sesi C2 15:00–16:40) dilaksanakan hari Kamis di Lab AI & Data.',
          author: 'Rizky Harahap • Asisten Lab',
          oldSchedule: 'Sel, 29 Sep • 13:00–14:40',
          newSchedule: 'Kam, 01 Okt • C1 13:00 | C2 15:00',
          room: 'Lab AI & Data',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        AnnouncementRecord(
          id: 'seed-ann-2',
          courseId: 'pemob',
          category: 2,
          tag: 'Umum',
          tagRed: false,
          title: 'Batas Unggah Tugas 4',
          body:
              'Jangan lupa mengunggah laporan PDF dan tautan repositori Tugas 4 sebelum pukul 10:30 WIB besok.',
          author: 'Andi Pratama • Asisten Lab',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ]);

    _roomRequests
      ..clear()
      ..addAll([
        RoomBookingRecord(
          id: 'room-req-1',
          tag: 'Praktikum Pengganti',
          labName: 'Lab Komputer 1',
          title: 'Desain Interaksi • Kom C (Sesi C2)',
          dateLabel: 'Sel, 29 Sep 2026',
          timeRange: '10:00–11:40',
          initials: 'FG',
          requesterName: 'Feri Gunawan',
          requesterRole: 'Asisten Lab',
          reason:
              'Pengganti pertemuan 3 Sesi C2 (durasi 1 jam 40 menit) karena libur nasional.',
        ),
        RoomBookingRecord(
          id: 'room-req-2',
          tag: 'Kelas Pengganti',
          labName: 'Lab Multimedia',
          title: 'Pemrograman Mobile • Kom C (Sesi C1)',
          dateLabel: 'Jum, 02 Okt 2026',
          timeRange: '08:00–09:40',
          initials: 'AR',
          requesterName: 'Abbil Rizki',
          requesterRole: 'Asisten Lab',
          reason:
              'Kelas pengganti Sesi C1 karena perbaikan proyektor di Lab Komputer 1.',
        ),
      ]);
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refreshFromBackend();
    _subscribeRealtime();
  }

  Future<void> refreshFromBackend() async {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    try {
      final schedRows = await client
          .from('praktikum_schedules')
          .select()
          .order('day_index', ascending: true)
          .order('start_time', ascending: true);

      if (schedRows.isNotEmpty) {
        final loaded = schedRows
            .map((r) =>
                PraktikumScheduleRecord.fromJson(Map<String, dynamic>.from(r)))
            .toList();
        final hasKomCSessions = loaded.length >= 8 &&
            loaded.any((s) => s.id == 'sched-pemob-c2') &&
            loaded.any((s) => s.kelas.contains('Kom C'));
        if (!hasKomCSessions) {
          // Migrasi otomatis jadwal lama (4 baris Kelas C) ke 8 sesi Kom C (C1 & C2)
          _seedDefaults();
          try {
            await client.from('praktikum_schedules').upsert(
              [
                for (final s in _schedules)
                  {
                    'id': s.id,
                    'course_id': s.courseId,
                    'course_name': s.courseName,
                    'kelas': s.kelas,
                    'day_index': s.dayIndex,
                    'day_short': s.dayShort,
                    'start_time': s.startTime,
                    'end_time': s.endTime,
                    'room': s.room,
                    'asisten': s.asisten,
                    'week_number': s.weekNumber,
                    'updated_at': DateTime.now().toIso8601String(),
                  },
              ],
              onConflict: 'id',
            );
          } catch (e) {
            debugPrint('[JadwalSync] Migrasi Kom C C1/C2 gagal: $e');
          }
        } else {
          _schedules
            ..clear()
            ..addAll(loaded);
        }
      }

      final annRows = await client
          .from('announcements')
          .select()
          .order('created_at', ascending: false)
          .limit(30);

      if (annRows.isNotEmpty) {
        _announcements
          ..clear()
          ..addAll(annRows.map(
              (r) => AnnouncementRecord.fromJson(Map<String, dynamic>.from(r))));
      }

      try {
        final roomRows = await client
            .from('room_booking_requests')
            .select()
            .order('created_at', ascending: false);
        if (roomRows.isNotEmpty) {
          _roomRequests
            ..clear()
            ..addAll(roomRows.map((r) =>
                RoomBookingRecord.fromJson(Map<String, dynamic>.from(r))));
        }
      } catch (e) {
        debugPrint('[JadwalSync] Load room_booking_requests dilewati: $e');
      }

      _backendAvailable = true;
      notifyListeners();
      debugPrint(
          '[JadwalSync] Berhasil sinkronisasi ${_schedules.length} jadwal & ${_announcements.length} pengumuman dari Supabase.');

      // Jika izin kalender sudah diberikan sebelumnya, otomatis segarkan kalender HP
      if (await DeviceCalendarService.instance.hasPermission()) {
        await DeviceCalendarService.instance
            .syncSchedules(_schedules, askPermission: false);
      }
    } catch (e) {
      _backendAvailable = false;
      debugPrint(
          '[JadwalSync] Menggunakan jadwal lokal (Supabase belum dijalankan / offline): $e');
    }
  }

  void _subscribeRealtime() {
    final client = SupabaseService.instance.client;
    if (client == null) return;
    try {
      _channel?.unsubscribe();
      _channel = client
          .channel('itlg-jadwal-sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'praktikum_schedules',
            callback: (_) => refreshFromBackend(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'announcements',
            callback: (_) => refreshFromBackend(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'room_booking_requests',
            callback: (_) => refreshFromBackend(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('[JadwalSync] Gagal pasang realtime channel: $e');
    }
  }

  /// Kirim pengumuman dari Aslab; bila kategori == 0 (Perubahan Jadwal),
  /// sekaligus memperbarui jadwal praktikum di Supabase & Kalender perangkat.
  Future<void> publishAnnouncementAndSchedule({
    required String? courseId,
    String? scheduleId,
    required int categoryIndex, // 0 Perubahan Jadwal, 1 Umum, 2 Penting
    required String title,
    required String body,
    required String author,
    int? newDayIndex,
    String? newStartTime,
    String? newEndTime,
    String? newScheduleLabel,
    String? newRoom,
  }) async {
    final now = DateTime.now();
    const dayShorts = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    String? oldScheduleLabel;

    if (categoryIndex == 0 && courseId != null && newDayIndex != null) {
      final idx = scheduleId != null
          ? _schedules.indexWhere((s) => s.id == scheduleId)
          : _schedules.indexWhere((s) => s.courseId == courseId);
      if (idx != -1) {
        final old = _schedules[idx];
        oldScheduleLabel = '${old.dayShort} • ${old.startTime}';
        final updated = old.copyWith(
          dayIndex: newDayIndex.clamp(0, 5),
          dayShort: dayShorts[newDayIndex.clamp(0, 5)],
          startTime: newStartTime ?? old.startTime,
          endTime: newEndTime ?? old.endTime,
          room: newRoom ?? old.room,
          updatedAt: now,
        );
        _schedules[idx] = updated;

        final client = SupabaseService.instance.client;
        if (client != null) {
          try {
            await client.from('praktikum_schedules').upsert(
              {
                'id': updated.id,
                'course_id': updated.courseId,
                'course_name': updated.courseName,
                'kelas': updated.kelas,
                'day_index': updated.dayIndex,
                'day_short': updated.dayShort,
                'start_time': updated.startTime,
                'end_time': updated.endTime,
                'room': updated.room,
                'asisten': updated.asisten,
                'week_number': updated.weekNumber,
                'updated_at': now.toIso8601String(),
              },
              onConflict: 'id',
            );
            _backendAvailable = true;
          } catch (e) {
            debugPrint('[JadwalSync] update schedule error: $e');
          }
        }
      }
    }

    final tag = const ['Perubahan Jadwal', 'Umum', 'Penting'][categoryIndex];
    final ann = AnnouncementRecord(
      id: 'local-${now.millisecondsSinceEpoch}',
      courseId: courseId,
      category: categoryIndex + 1,
      tag: tag,
      tagRed: categoryIndex != 1,
      title: title,
      body: body,
      author: '$author • Asisten Lab',
      oldSchedule: oldScheduleLabel,
      newSchedule: categoryIndex == 0 ? newScheduleLabel : null,
      room: categoryIndex == 0 ? newRoom : null,
      createdAt: now,
    );
    _announcements.insert(0, ann);
    notifyListeners();

    NotificationSyncService.instance.push(
      role: 'praktikan',
      icon: 'bullhorn_outline',
      title: '$tag: $title',
      body: body.isNotEmpty
          ? body
          : (newScheduleLabel != null
              ? 'Jadwal baru: $newScheduleLabel di ${newRoom ?? 'Lab'}'
              : 'Pengumuman baru dari $author'),
      targetKey: 'pengumuman',
      important: categoryIndex != 1,
    );
    if (categoryIndex == 0 && newRoom != null) {
      final parts = author.trim().split(RegExp(r'\s+'));
      final initials = parts.length >= 2
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : (author.isNotEmpty ? author.substring(0, 1).toUpperCase() : 'AS');
      final schedParts = (newScheduleLabel ?? 'Kam, 01 Okt 2026 • 13:00–14:40')
          .split('•');
      final dateLbl = schedParts.first.trim();
      final timeLbl =
          schedParts.length > 1 ? schedParts.last.trim() : '13:00–14:40';
      final roomReq = RoomBookingRecord(
        id: 'room-req-${now.millisecondsSinceEpoch}',
        tag: 'Praktikum Pengganti',
        labName: newRoom,
        title: title,
        dateLabel: dateLbl,
        timeRange: timeLbl,
        initials: initials,
        requesterName: author,
        requesterRole: 'Asisten Lab',
        reason: body.isNotEmpty
            ? body
            : 'Perubahan jadwal praktikum oleh asisten.',
      );
      _roomRequests.insert(0, roomReq);
      notifyListeners();

      final client = SupabaseService.instance.client;
      if (client != null) {
        try {
          await client.from('room_booking_requests').insert({
            'id': roomReq.id,
            'tag': roomReq.tag,
            'lab_name': roomReq.labName,
            'title': roomReq.title,
            'date_label': roomReq.dateLabel,
            'time_range': roomReq.timeRange,
            'requester_initials': roomReq.initials,
            'requester_name': roomReq.requesterName,
            'requester_role': roomReq.requesterRole,
            'reason': roomReq.reason,
            'status': 'menunggu',
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
        } catch (e) {
          debugPrint('[JadwalSync] insert room request fallback lokal: $e');
        }
      }

      NotificationSyncService.instance.push(
        role: 'laboran',
        icon: 'calendar',
        title: 'Permintaan Peminjaman Ruangan',
        body: '$author • $newRoom ($dateLbl, $timeLbl)',
        targetKey: 'ruangan',
        important: true,
      );
    }

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('announcements').insert({
          'course_id': courseId,
          'category': ann.category,
          'tag': ann.tag,
          'tag_red': ann.tagRed,
          'title': ann.title,
          'body': ann.body,
          'author': ann.author,
          'old_schedule': ann.oldSchedule,
          'new_schedule': ann.newSchedule,
          'room': ann.room,
          'created_at': now.toIso8601String(),
        });
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[JadwalSync] insert announcement error: $e');
      }
    }

    // Jika perubahan jadwal, perbarui juga kalender perangkat bila izin sudah aktif
    if (categoryIndex == 0 &&
        await DeviceCalendarService.instance.hasPermission()) {
      await DeviceCalendarService.instance
          .syncSchedules(_schedules, askPermission: false);
    }
  }

  /// Setujui / tolak permintaan peminjaman ruangan oleh Laboran dan sinkronkan
  /// ke Supabase (`public.room_booking_requests`) + notifikasi ke Aslab.
  Future<void> decideRoomRequest({
    required String requestId,
    required RoomStatus status,
  }) async {
    RoomBookingRecord? target;
    for (final r in _roomRequests) {
      if (r.id == requestId) {
        target = r;
        break;
      }
    }
    if (target == null) return;

    target.status = status;
    notifyListeners();

    final approved = status == RoomStatus.disetujui;
    NotificationSyncService.instance.push(
      role: 'aslab',
      icon: approved ? 'circle_check' : 'cross',
      title:
          'Peminjaman ${target.labName} ${approved ? 'Disetujui' : 'Ditolak'}',
      body: '${target.title} • ${target.dateLabel} (${target.timeRange})',
      targetKey: 'shiftJaga',
      important: true,
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('room_booking_requests').update({
          'status': RoomBookingRecord.serializeStatus(status),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', requestId);
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[JadwalSync] decideRoomRequest fallback lokal: $e');
      }
    }
  }
}
