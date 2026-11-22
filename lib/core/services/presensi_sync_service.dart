import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/aslab/aslab_store.dart';
import '../../features/praktikan/praktikan_store.dart';
import 'notification_sync_service.dart';
import 'supabase_service.dart';

/// State sesi presensi aktif (dibuka / diakhiri oleh Aslab, terbaca oleh Praktikan).
class AttendanceSessionRecord {
  final String id;
  final String courseId;
  final int meetingNumber;
  final String labName;
  final double lat;
  final double lng;
  final double radiusMeters;
  final bool allowQr;
  final bool allowButton;
  final bool requireSignature;
  final int durationMinutes;

  /// 'active' | 'closed'
  String status;
  String qrToken;
  DateTime? qrExpiresAt;
  final String startedBy;
  final DateTime startedAt;

  AttendanceSessionRecord({
    required this.id,
    required this.courseId,
    required this.meetingNumber,
    required this.labName,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
    required this.allowQr,
    required this.allowButton,
    required this.requireSignature,
    required this.durationMinutes,
    required this.status,
    this.qrToken = '',
    this.qrExpiresAt,
    required this.startedBy,
    required this.startedAt,
  });

  bool get isActive => status == 'active';

  factory AttendanceSessionRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceSessionRecord(
      id: (json['id'] ?? 'pemob-p5').toString(),
      courseId: (json['course_id'] ?? 'pemob').toString(),
      meetingNumber: (json['meeting_number'] as num?)?.toInt() ?? 5,
      labName: (json['lab_name'] ?? 'Lab Komputer 1').toString(),
      lat: (json['lat'] as num?)?.toDouble() ?? 3.5621,
      lng: (json['lng'] as num?)?.toDouble() ?? 98.6600,
      radiusMeters: (json['radius_m'] as num?)?.toDouble() ?? 50.0,
      allowQr: (json['allow_qr'] as bool?) ?? true,
      allowButton: (json['allow_button'] as bool?) ?? true,
      requireSignature: (json['require_signature'] as bool?) ?? true,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 15,
      status: (json['status'] ?? 'active').toString(),
      qrToken: (json['qr_token'] ?? '').toString(),
      qrExpiresAt: json['qr_expires_at'] != null
          ? DateTime.tryParse(json['qr_expires_at'].toString())
          : null,
      startedBy: (json['started_by'] ?? 'Andi Pratama').toString(),
      startedAt: json['started_at'] != null
          ? (DateTime.tryParse(json['started_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Catatan kehadiran praktikan per pertemuan (sinkron Praktikan ↔ Aslab).
class AttendanceRecord {
  final String courseId;
  final int meetingNumber;
  final String userIdentifier;
  final String userName;
  PrakAttend status;

  /// 'qr' | 'location' | 'manual' | 'izin'
  String method;
  String note;
  final double? lat;
  final double? lng;
  final double? distanceMeters;
  final bool hasSignature;
  final DateTime recordedAt;

  AttendanceRecord({
    required this.courseId,
    required this.meetingNumber,
    required this.userIdentifier,
    required this.userName,
    required this.status,
    required this.method,
    required this.note,
    this.lat,
    this.lng,
    this.distanceMeters,
    this.hasSignature = true,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  String get initials {
    final parts = userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'PR';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  String get formattedClock {
    final local = recordedAt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String get shortProofLabel {
    if (method == 'qr') return 'QR • $formattedClock';
    if (method == 'location') return 'Tombol • $formattedClock';
    if (method == 'izin') return 'Izin • $formattedClock';
    return 'Manual • $formattedClock';
  }

  String get noteIcon {
    if (method == 'location') return 'location';
    if (method == 'manual') return 'pencil';
    return 'qrcode';
  }

  static PrakAttend parseStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'hadir':
        return PrakAttend.hadir;
      case 'izin':
        return PrakAttend.izin;
      case 'alpa':
        return PrakAttend.alpa;
      case 'pending':
        return PrakAttend.pending;
      default:
        return PrakAttend.upcoming;
    }
  }

  static String serializeStatus(PrakAttend status) {
    switch (status) {
      case PrakAttend.hadir:
        return 'hadir';
      case PrakAttend.izin:
        return 'izin';
      case PrakAttend.alpa:
        return 'alpa';
      case PrakAttend.pending:
        return 'pending';
      case PrakAttend.upcoming:
        return 'pending';
    }
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      courseId: (json['course_id'] ?? 'pemob').toString(),
      meetingNumber: (json['meeting_number'] as num?)?.toInt() ?? 5,
      userIdentifier: (json['user_identifier'] ?? '').toString(),
      userName: (json['user_name'] ?? 'Praktikan').toString(),
      status: parseStatus(json['status'] as String?),
      method: (json['method'] ?? 'qr').toString(),
      note: (json['note'] ?? '').toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      distanceMeters: (json['distance_m'] as num?)?.toDouble(),
      hasSignature: (json['has_signature'] as bool?) ?? true,
      recordedAt: json['recorded_at'] != null
          ? (DateTime.tryParse(json['recorded_at'].toString()) ??
              DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Pengajuan izin praktikan ↔ persetujuan izin Aslab.
class LeaveRequestRecord {
  final String id;
  final String courseId;
  final int meetingNumber;
  final String userIdentifier;
  final String userName;
  final String leaveType;
  final String pertemuanLabel;
  final String note;
  final String? fileName;

  /// 0 Menunggu, 1 Disetujui, 2 Ditolak.
  int status;
  final DateTime createdAt;

  LeaveRequestRecord({
    required this.id,
    required this.courseId,
    required this.meetingNumber,
    required this.userIdentifier,
    required this.userName,
    required this.leaveType,
    required this.pertemuanLabel,
    required this.note,
    this.fileName,
    this.status = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get initials {
    final parts = userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'PR';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  String get submittedLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final local = createdAt.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$dd ${months[local.month - 1]}, $hh:$mm';
  }

  String get approveLabel =>
      leaveType.toLowerCase().contains('kendala') ? 'Tandai Hadir' : 'Setujui';

  AslabLeave toAslabLeave() {
    final leave = AslabLeave(
      student: AslabStudent(initials, userName, userIdentifier),
      type: leaveType,
      pertemuan: pertemuanLabel,
      diajukan: submittedLabel,
      note: note,
      file: fileName,
      approveLabel: approveLabel,
    );
    leave.status = status;
    return leave;
  }

  factory LeaveRequestRecord.fromJson(Map<String, dynamic> json) {
    return LeaveRequestRecord(
      id: (json['id'] ?? '').toString(),
      courseId: (json['course_id'] ?? 'pemob').toString(),
      meetingNumber: (json['meeting_number'] as num?)?.toInt() ?? 5,
      userIdentifier: (json['user_identifier'] ?? '').toString(),
      userName: (json['user_name'] ?? 'Praktikan').toString(),
      leaveType: (json['leave_type'] ?? 'Izin').toString(),
      pertemuanLabel: (json['pertemuan_label'] ?? '5 • Sen, 05 Okt').toString(),
      note: (json['note'] ?? '').toString(),
      fileName: json['file_name'] as String?,
      status: (json['status'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Service pusat sinkronisasi status Presensi, Sesi Aktif, dan Persetujuan Izin
/// antar peran (Praktikan ↔ Aslab ↔ Laboran) melalui Supabase + Realtime.
class PresensiSyncService extends ChangeNotifier {
  static final PresensiSyncService instance = PresensiSyncService._internal();
  PresensiSyncService._internal() {
    _seedDefaults();
  }

  late AttendanceSessionRecord _activeSession;
  final Map<String, AttendanceRecord> _records = {};
  final List<LeaveRequestRecord> _leaves = [];

  RealtimeChannel? _channel;
  bool _initialized = false;
  bool _backendAvailable = false;
  bool get isBackendAvailable => _backendAvailable;

  AttendanceSessionRecord get activeSession => _activeSession;
  List<LeaveRequestRecord> get leaves => List.unmodifiable(_leaves);
  int get pendingLeaveCount => _leaves.where((l) => l.status == 0).length;

  String _recKey(String courseId, int meetingNumber, String userIdentifier) =>
      '$courseId:$meetingNumber:$userIdentifier';

  void _seedDefaults() {
    _activeSession = AttendanceSessionRecord(
      id: 'pemob-p5',
      courseId: 'pemob',
      meetingNumber: 5,
      labName: 'Lab Komputer 1',
      lat: 3.5621,
      lng: 98.6600,
      radiusMeters: 50.0,
      allowQr: true,
      allowButton: true,
      requireSignature: true,
      durationMinutes: 15,
      status: 'active',
      startedBy: 'Andi Pratama',
      startedAt: DateTime.now().subtract(const Duration(minutes: 24, seconds: 18)),
    );

    _records.clear();
    final seedRecords = [
      AttendanceRecord(
        courseId: 'pemob',
        meetingNumber: 4,
        userIdentifier: '231402045',
        userName: 'Rina Novita',
        status: PrakAttend.hadir,
        method: 'location',
        note: 'Tombol + Lokasi • 08:02',
      ),
      AttendanceRecord(
        courseId: 'pemob',
        meetingNumber: 4,
        userIdentifier: '231402051',
        userName: 'Dimas Saputra',
        status: PrakAttend.hadir,
        method: 'manual',
        note: 'Diubah manual oleh asisten • tanpa tanda tangan',
        hasSignature: false,
      ),
      AttendanceRecord(
        courseId: 'pemob',
        meetingNumber: 4,
        userIdentifier: '231402063',
        userName: 'Maya Hutagalung',
        status: PrakAttend.izin,
        method: 'izin',
        note: 'Izin Sakit disetujui asisten',
        hasSignature: false,
      ),
      AttendanceRecord(
        courseId: 'pemob',
        meetingNumber: 4,
        userIdentifier: '231402070',
        userName: 'Yoga Siregar',
        status: PrakAttend.alpa,
        method: 'manual',
        note: 'Tidak hadir tanpa keterangan',
        hasSignature: false,
      ),
      AttendanceRecord(
        courseId: 'pemob',
        meetingNumber: 4,
        userIdentifier: '231402082',
        userName: 'Lia Nasution',
        status: PrakAttend.izin,
        method: 'izin',
        note: 'Izin Keluarga disetujui asisten',
        hasSignature: false,
      ),
      AttendanceRecord(
        courseId: 'pemob',
        meetingNumber: 5,
        userIdentifier: '231402045',
        userName: 'Rina Novita',
        status: PrakAttend.hadir,
        method: 'qr',
        note: 'QR • 08:02',
      ),
      AttendanceRecord(
        courseId: 'pemob',
        meetingNumber: 5,
        userIdentifier: '231402051',
        userName: 'Dimas Saputra',
        status: PrakAttend.hadir,
        method: 'location',
        note: 'Tombol • 08:03',
      ),
      AttendanceRecord(
        courseId: 'pemob',
        meetingNumber: 5,
        userIdentifier: '231402063',
        userName: 'Maya Hutagalung',
        status: PrakAttend.hadir,
        method: 'qr',
        note: 'QR • 08:05',
      ),
    ];
    for (final r in seedRecords) {
      _records[_recKey(r.courseId, r.meetingNumber, r.userIdentifier)] = r;
    }

    _leaves
      ..clear()
      ..addAll([
        LeaveRequestRecord(
          id: 'seed-leave-1',
          courseId: 'pemob',
          meetingNumber: 5,
          userIdentifier: '231402045',
          userName: 'Rina Novita',
          leaveType: 'Izin Sakit',
          pertemuanLabel: '5 • Sen, 05 Okt',
          note: 'Demam dan disarankan beristirahat oleh dokter klinik kampus.',
          fileName: 'surat_dokter.pdf',
          status: 0,
        ),
        LeaveRequestRecord(
          id: 'seed-leave-2',
          courseId: 'pemob',
          meetingNumber: 4,
          userIdentifier: '231402051',
          userName: 'Dimas Saputra',
          leaveType: 'Kendala Perangkat',
          pertemuanLabel: '4 • Sen, 28 Sep',
          note:
              'Kamera ponsel rusak sehingga tidak dapat memindai QR. Saya hadir di Lab Komputer 1.',
          status: 0,
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
      final sessionRows = await client
          .from('attendance_sessions')
          .select()
          .eq('id', 'pemob-p5')
          .maybeSingle();
      if (sessionRows != null) {
        _activeSession =
            AttendanceSessionRecord.fromJson(Map<String, dynamic>.from(sessionRows));
        _backendAvailable = true;
      }

      final recordRows = await client
          .from('attendance_records')
          .select()
          .order('recorded_at', ascending: false);
      if (recordRows.isNotEmpty) {
        for (final r in recordRows) {
          final rec =
              AttendanceRecord.fromJson(Map<String, dynamic>.from(r));
          _records[_recKey(rec.courseId, rec.meetingNumber, rec.userIdentifier)] =
              rec;
        }
        _backendAvailable = true;
      }

      final leaveRows = await client
          .from('leave_requests')
          .select()
          .order('created_at', ascending: false);
      if (leaveRows.isNotEmpty) {
        _leaves
          ..clear()
          ..addAll(leaveRows
              .map((r) => LeaveRequestRecord.fromJson(Map<String, dynamic>.from(r))));
        _backendAvailable = true;
      }

      notifyListeners();
      debugPrint(
          '[PresensiSync] Berhasil sinkronisasi (${recordRows.length} catatan hadir, ${leaveRows.length} izin).');
    } catch (e) {
      _backendAvailable = false;
      debugPrint(
          '[PresensiSync] Menggunakan sinkronisasi memori bersama (Supabase belum dijalankan / offline): $e');
    }
  }

  void _subscribeRealtime() {
    final client = SupabaseService.instance.client;
    if (client == null) return;
    try {
      _channel?.unsubscribe();
      _channel = client
          .channel('itlg-presensi-sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'attendance_sessions',
            callback: (_) => refreshFromBackend(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'attendance_records',
            callback: (_) => refreshFromBackend(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'leave_requests',
            callback: (_) => refreshFromBackend(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('[PresensiSync] Gagal pasang realtime channel: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Getter untuk Praktikan & Aslab
  // ---------------------------------------------------------------------------

  AttendanceRecord? recordFor(
      String courseId, int meetingNumber, String userIdentifier) {
    return _records[_recKey(courseId, meetingNumber, userIdentifier)];
  }

  /// Status efektif pertemuan untuk seorang praktikan (menggabungkan record BE
  /// + status bawaan pertemuan).
  PrakAttend effectiveStatus(
      String courseId, PrakMeeting meeting, String userIdentifier) {
    final rec = recordFor(courseId, meeting.number, userIdentifier);
    if (rec != null) return rec.status;
    return meeting.status;
  }

  /// Catatan kehadiran efektif (hijau) untuk sebuah pertemuan.
  (String icon, String note) effectiveNote(
      String courseId, PrakMeeting meeting, String userIdentifier) {
    final rec = recordFor(courseId, meeting.number, userIdentifier);
    if (rec != null && rec.note.isNotEmpty) {
      return (rec.noteIcon, rec.note);
    }
    return (meeting.noteIcon ?? 'qrcode', meeting.note ?? '');
  }

  /// Rekap jumlah hadir / izin / alpa untuk sebuah mata kuliah praktikan.
  ({int hadir, int izin, int alpa, int doneMeetings}) summaryForCourse(
      PrakCourse course, String userIdentifier) {
    var hadir = 0;
    var izin = 0;
    var alpa = 0;
    var done = 0;
    for (final m in course.meetings) {
      final st = effectiveStatus(course.id, m, userIdentifier);
      if (st == PrakAttend.hadir) {
        hadir++;
        done++;
      } else if (st == PrakAttend.izin) {
        izin++;
        done++;
      } else if (st == PrakAttend.alpa) {
        alpa++;
        done++;
      }
    }
    return (hadir: hadir, izin: izin, alpa: alpa, doneMeetings: done);
  }

  /// Daftar mahasiswa yang hadir pada sesi aktif (Pertemuan 5).
  List<AttendanceRecord> recordsForMeeting(String courseId, int meetingNumber) {
    return _records.values
        .where((r) =>
            r.courseId == courseId && r.meetingNumber == meetingNumber)
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }

  // ---------------------------------------------------------------------------
  // Aksi Backend: Sesi Aktif, Catat Hadir, Ajukan Izin, Keputusan Izin, Edit Manual
  // ---------------------------------------------------------------------------

  static String buildQrToken({
    required String courseId,
    required int meetingNumber,
    required int generation,
    DateTime? now,
  }) {
    final ts = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    return 'ITLG-${courseId.toUpperCase()}-P$meetingNumber-GEN$generation-$ts';
  }

  /// Putar token QR dinamis sesi aktif (dipanggil setiap 5 menit dari Aslab)
  /// dan sinkronkan ke Supabase agar praktikan lintas perangkat memvalidasi
  /// token yang sedang berlaku.
  Future<String> rotateActiveQrToken(int generation) async {
    final now = DateTime.now();
    final token = buildQrToken(
      courseId: _activeSession.courseId,
      meetingNumber: _activeSession.meetingNumber,
      generation: generation,
      now: now,
    );
    final expiresAt = now.add(const Duration(minutes: 5, seconds: 30));
    _activeSession.qrToken = token;
    _activeSession.qrExpiresAt = expiresAt;
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('attendance_sessions').update({
          'qr_token': token,
          'qr_expires_at': expiresAt.toIso8601String(),
        }).eq('id', _activeSession.id);
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[PresensiSync] rotateActiveQrToken info: $e');
      }
    }
    return token;
  }

  /// Validasi QR Code yang dipindai Praktikan.
  /// Mendukung QR dinamis yang di-generate Aslab untuk semua 4 praktikum
  /// maupun QR dummy uji coba.
  ({String? error, String courseId, int meetingNumber}) validateScannedQr(
      String raw) {
    final code = raw.trim();
    if (code == 'ITLG-PEMOB-PERTEMUAN5-TEST') {
      return (
        error: null,
        courseId: _activeSession.courseId,
        meetingNumber: _activeSession.meetingNumber,
      );
    }

    // Jika cocok langsung dengan token QR sesi aktif di BE
    if (_activeSession.qrToken.isNotEmpty && code == _activeSession.qrToken) {
      if (!_activeSession.isActive) {
        return (
          error: 'Sesi presensi sudah diakhiri oleh asisten',
          courseId: _activeSession.courseId,
          meetingNumber: _activeSession.meetingNumber,
        );
      }
      return (
        error: null,
        courseId: _activeSession.courseId,
        meetingNumber: _activeSession.meetingNumber,
      );
    }

    // Format baru: ITLG-{COURSE}-P{MEETING}-GEN{N}-{EPOCH}
    final mNew =
        RegExp(r'^ITLG-([A-Z0-9_]+)-P(\d+)-GEN\d+-(\d+)$').firstMatch(code);
    // Format lama: ITLG-{COURSE}-PERTEMUAN{MEETING}-GEN{N}-{EPOCH}
    final mOld =
        RegExp(r'^ITLG-([A-Z0-9_]+)-PERTEMUAN(\d+)-GEN\d+-(\d+)$')
            .firstMatch(code);
    final match = mNew ?? mOld;
    if (match == null) {
      return (
        error: 'QR tidak valid untuk sesi presensi ITLG',
        courseId: _activeSession.courseId,
        meetingNumber: _activeSession.meetingNumber,
      );
    }

    final parsedCourse = match.group(1)!.toLowerCase();
    final parsedMeeting = int.tryParse(match.group(2)!) ?? 5;
    final ts = int.tryParse(match.group(3)!) ?? 0;

    if (_activeSession.courseId == parsedCourse &&
        _activeSession.meetingNumber == parsedMeeting &&
        !_activeSession.isActive) {
      return (
        error: 'Sesi presensi sudah diakhiri oleh asisten',
        courseId: parsedCourse,
        meetingNumber: parsedMeeting,
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if ((now - ts).abs() > 330) {
      return (
        error: 'QR sudah kedaluwarsa, arahkan ke QR terbaru',
        courseId: parsedCourse,
        meetingNumber: parsedMeeting,
      );
    }

    return (
      error: null,
      courseId: parsedCourse,
      meetingNumber: parsedMeeting,
    );
  }

  Future<void> startSession({
    String courseId = 'pemob',
    int meetingNumber = 5,
    required String labName,
    required double lat,
    required double lng,
    required double radiusMeters,
    required bool allowQr,
    required bool allowButton,
    required bool requireSignature,
    required int durationMinutes,
    required String startedBy,
  }) async {
    final now = DateTime.now();
    final initialToken = buildQrToken(
      courseId: courseId,
      meetingNumber: meetingNumber,
      generation: 1,
      now: now,
    );
    final expiresAt = now.add(const Duration(minutes: 5, seconds: 30));
    _activeSession = AttendanceSessionRecord(
      id: '$courseId-p$meetingNumber',
      courseId: courseId,
      meetingNumber: meetingNumber,
      labName: labName,
      lat: lat,
      lng: lng,
      radiusMeters: radiusMeters,
      allowQr: allowQr,
      allowButton: allowButton,
      requireSignature: requireSignature,
      durationMinutes: durationMinutes,
      status: 'active',
      qrToken: initialToken,
      qrExpiresAt: expiresAt,
      startedBy: startedBy,
      startedAt: now,
    );
    notifyListeners();

    NotificationSyncService.instance.push(
      role: 'praktikan',
      icon: 'qrcode',
      title: 'Presensi Berlangsung',
      body: 'Pertemuan $meetingNumber • $labName dibuka oleh $startedBy',
      targetKey: 'presensi',
      important: true,
    );
    NotificationSyncService.instance.push(
      role: 'laboran',
      icon: 'key',
      title: 'Sesi Lab Dibuka',
      body: '$labName • Pertemuan $meetingNumber dimulai oleh $startedBy',
      targetKey: 'presensi',
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      final basePayload = <String, dynamic>{
        'id': _activeSession.id,
        'course_id': courseId,
        'meeting_number': meetingNumber,
        'lab_name': labName,
        'lat': lat,
        'lng': lng,
        'radius_m': radiusMeters,
        'allow_qr': allowQr,
        'allow_button': allowButton,
        'require_signature': requireSignature,
        'duration_minutes': durationMinutes,
        'status': 'active',
        'started_by': startedBy,
        'started_at': now.toIso8601String(),
        'ended_at': null,
      };
      try {
        await client.from('attendance_sessions').upsert(
          {
            ...basePayload,
            'qr_token': initialToken,
            'qr_expires_at': expiresAt.toIso8601String(),
          },
          onConflict: 'id',
        );
        _backendAvailable = true;
      } catch (e) {
        try {
          await client
              .from('attendance_sessions')
              .upsert(basePayload, onConflict: 'id');
          _backendAvailable = true;
        } catch (e2) {
          debugPrint('[PresensiSync] startSession error: $e2');
        }
      }
    }
  }

  Future<void> endActiveSession() async {
    _activeSession.status = 'closed';
    notifyListeners();

    NotificationSyncService.instance.push(
      role: 'praktikan',
      icon: 'clock',
      title: 'Sesi Presensi Ditutup',
      body:
          'Presensi Pertemuan ${_activeSession.meetingNumber} di ${_activeSession.labName} telah diakhiri',
      targetKey: 'detailAbsensi',
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('attendance_sessions').update({
          'status': 'closed',
          'ended_at': DateTime.now().toIso8601String(),
        }).eq('id', _activeSession.id);
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[PresensiSync] endActiveSession error: $e');
      }
    }
  }

  /// Catat presensi HADIR oleh Praktikan (setelah Tanda Tangan dikirim).
  Future<void> submitPresence({
    String courseId = 'pemob',
    int meetingNumber = 5,
    required String userIdentifier,
    required String userName,
    required String method, // 'qr' | 'location'
    double? lat,
    double? lng,
    double? distanceMeters,
    bool hasSignature = true,
  }) async {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final note = method == 'location'
        ? 'Tercatat $hh:$mm WIB melalui tombol hadir & lokasi'
        : 'Tercatat $hh:$mm WIB melalui pindai QR';

    final rec = AttendanceRecord(
      courseId: courseId,
      meetingNumber: meetingNumber,
      userIdentifier: userIdentifier,
      userName: userName,
      status: PrakAttend.hadir,
      method: method,
      note: note,
      lat: lat,
      lng: lng,
      distanceMeters: distanceMeters,
      hasSignature: hasSignature,
      recordedAt: now,
    );

    _records[_recKey(courseId, meetingNumber, userIdentifier)] = rec;
    notifyListeners();

    NotificationSyncService.instance.push(
      role: 'aslab',
      icon: 'circle_check',
      title: 'Presensi Tercatat • $userName',
      body: 'Pertemuan $meetingNumber ($userIdentifier) • $note',
      targetKey: 'detailPresensi',
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('attendance_records').upsert(
          {
            'course_id': courseId,
            'meeting_number': meetingNumber,
            'user_identifier': userIdentifier,
            'user_name': userName,
            'status': 'hadir',
            'method': method,
            'note': note,
            'lat': lat,
            'lng': lng,
            'distance_m': distanceMeters,
            'has_signature': hasSignature,
            'recorded_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          },
          onConflict: 'course_id,meeting_number,user_identifier',
        );
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[PresensiSync] submitPresence error: $e');
      }
    }
  }

  /// Praktikan mengajukan izin → masuk ke `leave_requests` & status pertemuan
  /// menjadi `pending` (Izin Diajukan), langsung tampil di Persetujuan Izin Aslab.
  Future<void> submitLeaveRequest({
    required String courseId,
    required int meetingNumber,
    required String userIdentifier,
    required String userName,
    required String leaveType,
    required String pertemuanLabel,
    required String note,
    String? fileName,
  }) async {
    final now = DateTime.now();
    final localId = 'leave-${now.millisecondsSinceEpoch}';
    final leave = LeaveRequestRecord(
      id: localId,
      courseId: courseId,
      meetingNumber: meetingNumber,
      userIdentifier: userIdentifier,
      userName: userName,
      leaveType: leaveType,
      pertemuanLabel: pertemuanLabel,
      note: note.isEmpty ? 'Mengajukan $leaveType' : note,
      fileName: fileName,
      status: 0,
      createdAt: now,
    );
    _leaves.insert(0, leave);

    // Tandai status pertemuan praktikan menjadi pending (Izin Diajukan)
    _records[_recKey(courseId, meetingNumber, userIdentifier)] =
        AttendanceRecord(
      courseId: courseId,
      meetingNumber: meetingNumber,
      userIdentifier: userIdentifier,
      userName: userName,
      status: PrakAttend.pending,
      method: 'izin',
      note: 'Pengajuan $leaveType sedang diperiksa asisten',
      hasSignature: false,
      recordedAt: now,
    );
    notifyListeners();

    NotificationSyncService.instance.push(
      role: 'aslab',
      icon: 'file',
      title: 'Pengajuan $leaveType Baru',
      body: '$userName ($userIdentifier) mengajukan $leaveType • Pertemuan $meetingNumber',
      targetKey: 'persetujuanIzin',
      important: true,
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        final inserted = await client
            .from('leave_requests')
            .insert({
              'course_id': courseId,
              'meeting_number': meetingNumber,
              'user_identifier': userIdentifier,
              'user_name': userName,
              'leave_type': leaveType,
              'pertemuan_label': pertemuanLabel,
              'note': leave.note,
              'file_name': fileName,
              'status': 0,
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            })
            .select()
            .maybeSingle();

        if (inserted != null) {
          final real =
              LeaveRequestRecord.fromJson(Map<String, dynamic>.from(inserted));
          final idx = _leaves.indexWhere((l) => l.id == localId);
          if (idx != -1) _leaves[idx] = real;
        }

        await client.from('attendance_records').upsert(
          {
            'course_id': courseId,
            'meeting_number': meetingNumber,
            'user_identifier': userIdentifier,
            'user_name': userName,
            'status': 'pending',
            'method': 'izin',
            'note': 'Pengajuan $leaveType sedang diperiksa asisten',
            'has_signature': false,
            'recorded_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          },
          onConflict: 'course_id,meeting_number,user_identifier',
        );
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[PresensiSync] submitLeaveRequest error: $e');
      }
    }
  }

  /// Aslab menyetujui / menolak izin → otomatis menyinkronkan status pertemuan
  /// praktikan (`izin` / `hadir` / `alpa`) di Supabase & UI Praktikan!
  Future<void> decideLeaveRequest({
    required LeaveRequestRecord leave,
    required bool approve,
    required String decidedBy,
  }) async {
    leave.status = approve ? 1 : 2;
    final now = DateTime.now();

    final newAttendStatus = approve
        ? (leave.leaveType.toLowerCase().contains('kendala')
            ? PrakAttend.hadir
            : PrakAttend.izin)
        : PrakAttend.alpa;

    final newNote = approve
        ? (newAttendStatus == PrakAttend.hadir
            ? 'Ditandai hadir oleh $decidedBy (kendala perangkat)'
            : 'Izin disetujui oleh $decidedBy')
        : 'Pengajuan izin ditolak oleh $decidedBy';

    _records[_recKey(leave.courseId, leave.meetingNumber, leave.userIdentifier)] =
        AttendanceRecord(
      courseId: leave.courseId,
      meetingNumber: leave.meetingNumber,
      userIdentifier: leave.userIdentifier,
      userName: leave.userName,
      status: newAttendStatus,
      method: newAttendStatus == PrakAttend.hadir ? 'manual' : 'izin',
      note: newNote,
      hasSignature: false,
      recordedAt: now,
    );
    notifyListeners();

    NotificationSyncService.instance.push(
      role: 'praktikan',
      icon: approve ? 'circle_check' : 'triangle_alert',
      title: approve ? 'Pengajuan Izin Disetujui' : 'Pengajuan Izin Ditolak',
      body: 'Pertemuan ${leave.meetingNumber}: $newNote',
      targetKey: 'detailAbsensi',
      important: true,
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        if (!leave.id.startsWith('seed-') && !leave.id.startsWith('leave-')) {
          await client.from('leave_requests').update({
            'status': leave.status,
            'decided_by': decidedBy,
            'updated_at': now.toIso8601String(),
          }).eq('id', leave.id);
        }

        await client.from('attendance_records').upsert(
          {
            'course_id': leave.courseId,
            'meeting_number': leave.meetingNumber,
            'user_identifier': leave.userIdentifier,
            'user_name': leave.userName,
            'status': AttendanceRecord.serializeStatus(newAttendStatus),
            'method': newAttendStatus == PrakAttend.hadir ? 'manual' : 'izin',
            'note': newNote,
            'has_signature': false,
            'updated_by': decidedBy,
            'recorded_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          },
          onConflict: 'course_id,meeting_number,user_identifier',
        );
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[PresensiSync] decideLeaveRequest error: $e');
      }
    }
  }

  /// Aslab memperbarui status presensi praktikan secara manual (Hadir / Izin / Alpa).
  Future<void> saveManualStatuses({
    String courseId = 'pemob',
    int meetingNumber = 4,
    required List<AslabPresence> presences,
    required String updatedBy,
  }) async {
    final now = DateTime.now();
    for (final p in presences) {
      final st = switch (p.status) {
        AslabAttend.hadir => PrakAttend.hadir,
        AslabAttend.izin => PrakAttend.izin,
        AslabAttend.alpa => PrakAttend.alpa,
      };
      final note = switch (p.status) {
        AslabAttend.hadir => 'Diubah manual oleh $updatedBy',
        AslabAttend.izin => 'Status izin dicatat oleh $updatedBy',
        AslabAttend.alpa => 'Ditandai alpa oleh $updatedBy',
      };
      _records[_recKey(courseId, meetingNumber, p.student.nim)] =
          AttendanceRecord(
        courseId: courseId,
        meetingNumber: meetingNumber,
        userIdentifier: p.student.nim,
        userName: p.student.name,
        status: st,
        method: 'manual',
        note: note,
        hasSignature: false,
        recordedAt: now,
      );
    }
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        final rows = [
          for (final p in presences)
            {
              'course_id': courseId,
              'meeting_number': meetingNumber,
              'user_identifier': p.student.nim,
              'user_name': p.student.name,
              'status': switch (p.status) {
                AslabAttend.hadir => 'hadir',
                AslabAttend.izin => 'izin',
                AslabAttend.alpa => 'alpa',
              },
              'method': 'manual',
              'note': 'Diperbarui oleh $updatedBy',
              'has_signature': false,
              'updated_by': updatedBy,
              'updated_at': now.toIso8601String(),
            }
        ];
        await client.from('attendance_records').upsert(
              rows,
              onConflict: 'course_id,meeting_number,user_identifier',
            );
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[PresensiSync] saveManualStatuses error: $e');
      }
    }
  }
}
