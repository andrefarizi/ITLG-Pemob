import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/auth_controller.dart';
import '../utils/constants.dart';
import 'device_notification_service.dart';
import 'supabase_service.dart';

/// Satu item notifikasi lintas role yang tersinkron ke Supabase + Realtime.
class AppNotificationRecord {
  final String id;

  /// 'praktikan' | 'aslab' | 'laboran' | 'dosen'
  final String role;
  final String icon;
  final String title;
  final String body;
  final String targetKey;
  final String? courseId;
  final int? meetingNumber;
  final String? courseName;
  final String? moduleLabel;
  final bool important;

  /// Bila diisi, hanya pengguna dengan nomor induk ini yang melihat notifikasi
  /// (mis. nilai pribadi). Null = untuk semua pengguna di peran tersebut.
  final String? targetUser;
  bool isRead;
  final DateTime createdAt;

  AppNotificationRecord({
    required this.id,
    required this.role,
    required this.icon,
    required this.title,
    required this.body,
    required this.targetKey,
    this.courseId,
    this.meetingNumber,
    this.courseName,
    this.moduleLabel,
    this.important = false,
    this.targetUser,
    this.isRead = false,
    required this.createdAt,
  });

  bool get unread => !isRead;

  bool get isToday {
    final now = DateTime.now();
    final local = createdAt.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  bool get isYesterday {
    final yest = DateTime.now().subtract(const Duration(days: 1));
    final local = createdAt.toLocal();
    return local.year == yest.year &&
        local.month == yest.month &&
        local.day == yest.day;
  }

  bool get isEarlier => !isToday && !isYesterday;

  String get relativeTime {
    final diff = DateTime.now().difference(createdAt.toLocal());
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24 && isToday) return '${diff.inHours} jam lalu';
    final local = createdAt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    if (diff.inDays <= 1) return 'Kemarin, $hh:$mm';
    return '${diff.inDays} hari lalu';
  }

  factory AppNotificationRecord.fromJson(Map<String, dynamic> json) {
    return AppNotificationRecord(
      id: (json['id'] ?? '').toString(),
      role: (json['target_role'] ?? 'praktikan').toString(),
      icon: (json['icon'] ?? 'info').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      targetKey: (json['target_key'] ?? '').toString(),
      courseId: json['course_id'] as String?,
      meetingNumber: (json['meeting_number'] as num?)?.toInt(),
      courseName: json['course_name'] as String?,
      moduleLabel: json['module_label'] as String?,
      important: (json['important'] as bool?) ?? false,
      targetUser: json['target_user'] as String?,
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Layanan sinkronisasi notifikasi lintas peran.
class NotificationSyncService extends ChangeNotifier {
  static final NotificationSyncService instance =
      NotificationSyncService._internal();
  NotificationSyncService._internal() {
    _seedDefaults();
  }

  final List<AppNotificationRecord> _items = [];
  RealtimeChannel? _channel;
  bool _initialized = false;
  bool _backendAvailable = false;
  bool get isBackendAvailable => _backendAvailable;

  /// Status dibaca per pengguna dari `public.notification_reads`
  /// (null = tabel belum tersedia → pakai kolom bersama `is_read`).
  Set<String>? _readIds;

  /// ID notifikasi yang sudah ada sebelum sesi saat ini agar data historis
  /// lama tidak memicu spam pop-up notifikasi HP saat aplikasi pertama dibuka.
  final Set<String> _baselineIds = {};
  bool _baselineCaptured = false;

  /// Catatan ID notifikasi yang sudah pernah ditampilkan ke status bar HP per akun.
  final Map<String, Set<String>> _pushedByUser = {};

  String get _me => AuthController.instance.userIdentifier;

  String get _activeRoleKey {
    switch (AuthController.instance.currentRole) {
      case UserRole.praktikan:
        return 'praktikan';
      case UserRole.aslab:
        return 'aslab';
      case UserRole.laboran:
        return 'laboran';
      case UserRole.dosen:
        return 'dosen';
    }
  }

  bool _alreadyPushed(String userKey, String notifId) =>
      _pushedByUser[userKey]?.contains(notifId) ?? false;

  void _markPushed(String userKey, String notifId) {
    _pushedByUser.putIfAbsent(userKey, () => <String>{}).add(notifId);
  }

  Future<void> _maybeShowOnDevice(AppNotificationRecord n) async {
    if (!AuthController.instance.isLoggedIn) return;
    final role = _activeRoleKey;
    final userKey = '$role:$_me';
    if (!_visible(n, role) || n.isRead || n.id.startsWith('seed-')) return;
    if (_alreadyPushed(userKey, n.id)) return;

    _markPushed(userKey, n.id);
    await DeviceNotificationService.instance.show(
      id: n.id,
      title: n.title,
      body: n.body,
      forRole: role,
    );
  }

  /// Dipanggil setelah pengguna berhasil login untuk menyinkronkan notifikasi
  /// terbaru dan memunculkan notifikasi baru yang masuk ke status bar HP.
  Future<void> onUserLogin() async {
    await DeviceNotificationService.instance.requestPermissionOnce();
    await refreshFromBackend(notifyNewForActiveUser: false);
    if (!AuthController.instance.isLoggedIn) return;

    final role = _activeRoleKey;
    final userKey = '$role:$_me';
    final recentCutoff = DateTime.now().subtract(const Duration(minutes: 30));
    final sessionCutoff = DateTime.now().subtract(const Duration(hours: 12));
    final freshUnread = forRole(role)
        .where((n) =>
            !n.isRead &&
            !n.id.startsWith('seed-') &&
            !_alreadyPushed(userKey, n.id) &&
            ((!_baselineIds.contains(n.id) &&
                    n.createdAt.toLocal().isAfter(sessionCutoff)) ||
                n.createdAt.toLocal().isAfter(recentCutoff)))
        .take(3)
        .toList()
        .reversed;

    for (final n in freshUnread) {
      await _maybeShowOnDevice(n);
    }
  }

  bool _visible(AppNotificationRecord n, String role) =>
      n.role == role && (n.targetUser == null || n.targetUser == _me);

  List<AppNotificationRecord> forRole(String role) {
    final list = _items.where((n) => _visible(n, role)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int unreadCountForRole(String role) =>
      _items.where((n) => _visible(n, role) && n.unread).length;

  void _seedDefaults() {
    final now = DateTime.now();
    _items
      ..clear()
      ..addAll([
        // Praktikan
        AppNotificationRecord(
          id: 'seed-p-1',
          role: 'praktikan',
          icon: 'qrcode',
          title: 'Presensi Berlangsung',
          body:
              'Praktikum Pemrograman Mobile • Lab Komputer 1 sedang dibuka oleh Andi Pratama',
          targetKey: 'presensi',
          important: true,
          isRead: false,
          createdAt: now.subtract(const Duration(minutes: 5)),
        ),
        AppNotificationRecord(
          id: 'seed-p-2',
          role: 'praktikan',
          icon: 'bullhorn_outline',
          title: 'Pemindahan Jadwal Praktikum',
          body:
              'Machine Learning Kelas C pindah ke Kam, 01 Okt • 13:00 di Lab Jaringan 3',
          targetKey: 'pengumuman',
          important: true,
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        AppNotificationRecord(
          id: 'seed-p-3',
          role: 'praktikan',
          icon: 'clipboard',
          title: 'Batas Unggah Tugas 4',
          body:
              'Kumpulkan laporan & tautan repositori Pemrograman Mobile sebelum 10:30 WIB',
          targetKey: 'editTugas',
          important: false,
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 4)),
        ),
        AppNotificationRecord(
          id: 'seed-p-4',
          role: 'praktikan',
          icon: 'trophy',
          title: 'Nilai Modul 3 Tersedia',
          body: 'Nilai Layout & Navigasi (88) telah diterbitkan oleh asisten',
          targetKey: 'detailNilai',
          important: false,
          isRead: true,
          createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        ),

        // Aslab
        AppNotificationRecord(
          id: 'seed-a-1',
          role: 'aslab',
          icon: 'file',
          title: 'Pengajuan Izin Menunggu',
          body:
              'Rina Novita mengajukan Izin Sakit untuk Pertemuan 5 Pemrograman Mobile',
          targetKey: 'persetujuanIzin',
          important: true,
          isRead: false,
          createdAt: now.subtract(const Duration(minutes: 10)),
        ),
        AppNotificationRecord(
          id: 'seed-a-2',
          role: 'aslab',
          icon: 'clipboard',
          title: 'Tugas 4 Perlu Dievaluasi',
          body:
              '20 praktikan telah mengumpulkan Tugas 4 Praktikum Pemrograman Mobile',
          targetKey: 'evaluasi',
          important: true,
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        AppNotificationRecord(
          id: 'seed-a-3',
          role: 'aslab',
          icon: 'arrow_right_left',
          title: 'Permintaan Tukar Shift',
          body: 'Feri Gunawan meminta bertukar shift jaga minggu ini',
          targetKey: 'shiftJaga',
          important: false,
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
        AppNotificationRecord(
          id: 'seed-a-4',
          role: 'aslab',
          icon: 'question',
          title: 'Hasil Kuis Pre-Test Modul 4',
          body:
              '22 dari 24 praktikan telah menyelesaikan kuis dengan rata-rata 78,5',
          targetKey: 'hasilKuis',
          important: false,
          isRead: true,
          createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        ),

        // Laboran
        AppNotificationRecord(
          id: 'seed-l-1',
          role: 'laboran',
          icon: 'wrench_outline',
          title: 'Laporan Kerusakan Baru',
          body:
              'PC-12 Lab Komputer 1 dilaporkan mengalami kendala monitor tidak tampil',
          targetKey: 'tiket',
          important: true,
          isRead: false,
          createdAt: now.subtract(const Duration(minutes: 15)),
        ),
        AppNotificationRecord(
          id: 'seed-l-2',
          role: 'laboran',
          icon: 'calendar',
          title: '2 Pengajuan Pemakaian Ruangan',
          body:
              'Menunggu persetujuan jadwal pemakaian Lab Komputer 2 & Lab Jaringan 1',
          targetKey: 'ruangan',
          important: true,
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        AppNotificationRecord(
          id: 'seed-l-3',
          role: 'laboran',
          icon: 'key',
          title: 'Presensi Asisten On-Duty',
          body:
              'Andi Pratama & Feri Gunawan telah verifikasi kehadiran di laboratorium',
          targetKey: 'presensi',
          important: false,
          isRead: true,
          createdAt: now.subtract(const Duration(days: 1, hours: 1)),
        ),

        // Dosen
        AppNotificationRecord(
          id: 'seed-d-1',
          role: 'dosen',
          icon: 'triangle_alert',
          title: 'Peringatan Dini: 3 Praktikan',
          body:
              'Kehadiran atau nilai di bawah batas minimal pada grup praktikum diampu',
          targetKey: 'peringatan',
          important: true,
          isRead: false,
          createdAt: now.subtract(const Duration(minutes: 5)),
        ),
        AppNotificationRecord(
          id: 'seed-d-2',
          role: 'dosen',
          icon: 'circle_check',
          title: 'Modul 4 Selesai Dinilai',
          body: 'Praktikum Pemrograman Mobile Kelas C • Andi Pratama',
          targetKey: 'validasi',
          important: false,
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        AppNotificationRecord(
          id: 'seed-d-3',
          role: 'dosen',
          icon: 'chart_bar',
          title: 'Rekap Kehadiran Minggu ke-4',
          body: 'Rata-rata kehadiran 91% dari 4 grup praktikum aktif',
          targetKey: 'laporan',
          important: false,
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        AppNotificationRecord(
          id: 'seed-d-4',
          role: 'dosen',
          icon: 'clipboard',
          title: 'Nilai Akhir Siap Divalidasi',
          body:
              'Pemrograman Mobile Kelas C menunggu validasi dosen pengampu',
          targetKey: 'validasi',
          important: true,
          isRead: true,
          createdAt: now.subtract(const Duration(days: 1, hours: 4)),
        ),
      ]);
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refreshFromBackend(notifyNewForActiveUser: false);
    _baselineCaptured = true;
    _subscribeRealtime();
  }

  Future<void> refreshFromBackend({bool notifyNewForActiveUser = true}) async {
    final client = SupabaseService.instance.client;
    if (client == null) return;
    final previousIds = {for (final x in _items) x.id};
    try {
      final rows = await client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      // Status dibaca milik pengguna ini (tabel opsional).
      try {
        final me = _me;
        if (me.isNotEmpty) {
          final readRows = await client
              .from('notification_reads')
              .select('notification_id')
              .eq('user_identifier', me);
          _readIds = {
            for (final r in readRows) r['notification_id'].toString(),
          };
        }
      } catch (e) {
        _readIds = null;
        debugPrint('[NotificationSync] notification_reads belum tersedia: $e');
      }
      if (rows.isNotEmpty) {
        _items
          ..clear()
          ..addAll(rows.map((r) =>
              AppNotificationRecord.fromJson(Map<String, dynamic>.from(r))));
        final reads = _readIds;
        if (reads != null) {
          for (final n in _items) {
            n.isRead = reads.contains(n.id);
          }
        }
        if (!_baselineCaptured) {
          _baselineIds.addAll(_items.map((e) => e.id));
        }
        _backendAvailable = true;
        notifyListeners();

        if (notifyNewForActiveUser && _baselineCaptured) {
          final newlyArrived = _items
              .where((n) => !previousIds.contains(n.id) && !_baselineIds.contains(n.id))
              .toList()
              .reversed;
          for (final n in newlyArrived) {
            await _maybeShowOnDevice(n);
          }
        }
        debugPrint(
            '[NotificationSync] Berhasil sinkronisasi ${_items.length} notifikasi dari Supabase.');
      }
    } catch (e) {
      _backendAvailable = false;
      debugPrint(
          '[NotificationSync] Menggunakan notifikasi memori bersama (Supabase belum dijalankan / offline): $e');
    }
  }

  void _subscribeRealtime() {
    final client = SupabaseService.instance.client;
    if (client == null) return;
    try {
      _channel?.unsubscribe();
      _channel = client
          .channel('itlg-notifications-sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            callback: (_) => refreshFromBackend(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('[NotificationSync] Gagal pasang realtime channel: $e');
    }
  }

  /// Kirim notifikasi baru ke role tujuan (tersinkron lokal + Supabase).
  Future<void> push({
    required String role,
    required String icon,
    required String title,
    required String body,
    required String targetKey,
    String? courseId,
    int? meetingNumber,
    String? courseName,
    String? moduleLabel,
    bool important = false,
    String? targetUser,
  }) async {
    final now = DateTime.now();
    final localId = 'local-$role-${now.microsecondsSinceEpoch}';
    final rec = AppNotificationRecord(
      id: localId,
      role: role,
      icon: icon,
      title: title,
      body: body,
      targetKey: targetKey,
      courseId: courseId,
      meetingNumber: meetingNumber,
      courseName: courseName,
      moduleLabel: moduleLabel,
      important: important,
      targetUser: targetUser,
      isRead: false,
      createdAt: now,
    );
    _items.insert(0, rec);
    notifyListeners();
    await _maybeShowOnDevice(rec);

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        final row = <String, dynamic>{
          'target_role': role,
          'icon': icon,
          'title': title,
          'body': body,
          'target_key': targetKey,
          if (courseId != null) 'course_id': courseId,
          if (meetingNumber != null) 'meeting_number': meetingNumber,
          if (courseName != null) 'course_name': courseName,
          if (moduleLabel != null) 'module_label': moduleLabel,
          if (targetUser != null) 'target_user': targetUser,
          'important': important,
          'is_read': false,
          'created_at': now.toUtc().toIso8601String(),
        };
        Map<String, dynamic>? inserted;
        try {
          inserted = await client
              .from('notifications')
              .insert(row)
              .select()
              .maybeSingle();
        } on PostgrestException catch (e) {
          // Kolom target_user belum dibuat (SQL belum dijalankan): kirim
          // tanpa kolom itu agar notifikasi tetap tersimpan.
          if (targetUser == null || !e.message.contains('target_user')) {
            rethrow;
          }
          row.remove('target_user');
          inserted = await client
              .from('notifications')
              .insert(row)
              .select()
              .maybeSingle();
        }
        if (inserted != null) {
          final serverRec =
              AppNotificationRecord.fromJson(Map<String, dynamic>.from(inserted));
          if (AuthController.instance.isLoggedIn &&
              _visible(serverRec, _activeRoleKey)) {
            _markPushed('$_activeRoleKey:$_me', serverRec.id);
          }
          final idx = _items.indexWhere((x) => x.id == localId);
          if (idx != -1) {
            _items[idx] = serverRec;
            notifyListeners();
          }
        }
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[NotificationSync] push error: $e');
      }
    }
  }

  Future<void> markRead(String id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    if (_items[idx].isRead) return;
    _items[idx].isRead = true;
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null && !id.startsWith('seed-') && !id.startsWith('local-')) {
      try {
        if (_readIds != null) {
          // Dibaca oleh pengguna ini saja.
          await client.from('notification_reads').upsert({
            'notification_id': id,
            'user_identifier': _me,
          }, onConflict: 'notification_id,user_identifier');
          _readIds!.add(id);
        } else {
          await client
              .from('notifications')
              .update({'is_read': true}).eq('id', id);
        }
      } catch (e) {
        debugPrint('[NotificationSync] markRead error: $e');
      }
    }
  }

  Future<void> markAllRead(String role) async {
    final targets =
        _items.where((n) => _visible(n, role) && !n.isRead).toList();
    for (final n in targets) {
      n.isRead = true;
    }
    if (targets.isNotEmpty) notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        if (_readIds != null) {
          final ids = [
            for (final n in targets)
              if (!n.id.startsWith('seed-') && !n.id.startsWith('local-')) n.id,
          ];
          if (ids.isNotEmpty) {
            await client.from('notification_reads').upsert(
              [
                for (final id in ids)
                  {'notification_id': id, 'user_identifier': _me},
              ],
              onConflict: 'notification_id,user_identifier',
            );
            _readIds!.addAll(ids);
          }
        } else {
          await client
              .from('notifications')
              .update({'is_read': true})
              .eq('target_role', role)
              .eq('is_read', false);
        }
      } catch (e) {
        debugPrint('[NotificationSync] markAllRead error: $e');
      }
    }
  }
}
