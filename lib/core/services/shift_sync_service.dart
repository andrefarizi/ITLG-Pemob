import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_sync_service.dart';
import 'supabase_service.dart';

/// Satu jadwal shift jaga + status presensi asisten laboratorium.
class ShiftRecord {
  final String id;

  /// 0 = Sen, 1 = Sel, 2 = Rab, 3 = Kam, 4 = Jum, 5 = Sab.
  final int dayIndex;
  final String dayLabel;
  final String shiftLabel;
  final String courseName;
  final String timeRange;
  final String room;
  String asistenName;
  String asistenInitials;
  String partnerName;

  /// 'hadir' | 'terlambat' | 'belum'
  String attendanceStatus;
  String? checkInTime;
  int disciplinePct;
  DateTime updatedAt;

  ShiftRecord({
    required this.id,
    required this.dayIndex,
    required this.dayLabel,
    required this.shiftLabel,
    required this.courseName,
    required this.timeRange,
    required this.room,
    required this.asistenName,
    required this.asistenInitials,
    required this.partnerName,
    this.attendanceStatus = 'belum',
    this.checkInTime,
    this.disciplinePct = 90,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  String get shortLabel {
    final start = timeRange.split('–').first.trim();
    return '$dayLabel • $start';
  }

  String get pickerLabel => '$dayLabel • ${timeRange.replaceAll(' WIB', '')} • $room';

  factory ShiftRecord.fromJson(Map<String, dynamic> json) {
    final name = (json['asisten_name'] as String?) ?? 'Asisten Lab';
    return ShiftRecord(
      id: (json['id'] ?? '').toString(),
      dayIndex: ((json['day_index'] as num?)?.toInt() ?? 0).clamp(0, 5),
      dayLabel: (json['day_label'] as String?) ?? 'Sen, 28 Sep',
      shiftLabel: (json['shift_label'] as String?) ?? 'Shift Pagi',
      courseName: (json['course_name'] as String?) ?? 'Praktikum Lab',
      timeRange: (json['time_range'] as String?) ?? '08:00–09:40 WIB',
      room: (json['room'] as String?) ?? 'Lab Komputer 1',
      asistenName: name,
      asistenInitials:
          (json['asisten_initials'] as String?) ?? ShiftSyncService.initialsOf(name),
      partnerName: (json['partner_name'] as String?) ?? '',
      attendanceStatus: (json['attendance_status'] as String?) ?? 'belum',
      checkInTime: json['check_in_time'] as String?,
      disciplinePct: ((json['discipline_pct'] as num?)?.toInt() ?? 90).clamp(0, 100),
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Satu permintaan / riwayat tukar shift antar asisten laboratorium.
class ShiftSwapRecord {
  final String swapCode;
  final String? requesterId;
  final String requesterName;
  final String requesterInitials;
  final String targetName;
  final String targetInitials;
  final String? fromShiftId;
  final String fromShiftLabel;
  final String? toShiftId;
  final String toShiftLabel;
  final String reason;

  /// 'pending' | 'approved' | 'rejected'
  String status;
  final bool isIncoming;
  final bool isMine;
  String metaNote;
  final DateTime createdAt;
  DateTime? decidedAt;

  ShiftSwapRecord({
    required this.swapCode,
    this.requesterId,
    required this.requesterName,
    required this.requesterInitials,
    required this.targetName,
    required this.targetInitials,
    this.fromShiftId,
    required this.fromShiftLabel,
    this.toShiftId,
    required this.toShiftLabel,
    this.reason = '',
    this.status = 'pending',
    this.isIncoming = false,
    this.isMine = true,
    this.metaNote = '',
    DateTime? createdAt,
    this.decidedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get requesterFirstName => requesterName.trim().split(' ').first;
  String get targetFirstName => targetName.trim().split(' ').first;
  String get pairNames => '$requesterName & $targetName';

  factory ShiftSwapRecord.fromJson(Map<String, dynamic> json) {
    final reqName = (json['requester_name'] as String?) ?? 'Asisten Lab';
    final tgtName = (json['target_name'] as String?) ?? 'Asisten Lab';
    return ShiftSwapRecord(
      swapCode: (json['swap_code'] as String?) ?? '#TS-000',
      requesterId: json['requester_id'] as String?,
      requesterName: reqName,
      requesterInitials: (json['requester_initials'] as String?) ??
          ShiftSyncService.initialsOf(reqName),
      targetName: tgtName,
      targetInitials: (json['target_initials'] as String?) ??
          ShiftSyncService.initialsOf(tgtName),
      fromShiftId: json['from_shift_id'] as String?,
      fromShiftLabel: (json['from_shift_label'] as String?) ?? '',
      toShiftId: json['to_shift_id'] as String?,
      toShiftLabel: (json['to_shift_label'] as String?) ?? '',
      reason: (json['reason'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending',
      isIncoming: (json['is_incoming'] as bool?) ?? false,
      isMine: (json['is_mine'] as bool?) ?? true,
      metaNote: (json['meta_note'] as String?) ?? '',
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      decidedAt: json['decided_at'] != null
          ? DateTime.tryParse(json['decided_at'].toString())
          : null,
    );
  }
}

/// Service pusat sinkronisasi Shift Jaga, Tukar Shift & Presensi Asisten
/// lintas role (Aslab ↔ Laboran) dengan backend Supabase + Realtime dan
/// fallback memori bersama otomatis.
class ShiftSyncService extends ChangeNotifier {
  static final ShiftSyncService instance = ShiftSyncService._internal();
  ShiftSyncService._internal() {
    _seedDefaults();
  }

  final List<ShiftRecord> _shifts = [];
  final List<ShiftSwapRecord> _swaps = [];
  String _accessCode = 'ITLG-4821';
  String _accessValidUntil = '17:00 WIB';

  RealtimeChannel? _channel;
  bool _initialized = false;
  bool _backendAvailable = false;
  bool get isBackendAvailable => _backendAvailable;

  String get accessCode => _accessCode;
  String get accessValidUntil => _accessValidUntil;

  /// Payload QR dinamis 60 detik untuk Presensi Mengajar Asisten (Laboran ↔ Aslab).
  String get rotatingQrPayload {
    final minuteBucket = DateTime.now().millisecondsSinceEpoch ~/ 60000;
    return '$_accessCode|T:$minuteBucket';
  }

  /// Validasi payload QR 60 detik (termasuk 1 menit masa tenggang) atau kode harian aktif.
  bool isQrPayloadValid(String raw) {
    final cleaned = raw.trim().toUpperCase();
    final expected = _accessCode.trim().toUpperCase();
    if (cleaned.isEmpty || expected.isEmpty) return false;
    if (cleaned == expected) return true;
    final m = RegExp(r'^([A-Z0-9-]+)\|T:(\d+)$').firstMatch(cleaned);
    if (m != null) {
      final code = m.group(1)!;
      final bucket = int.tryParse(m.group(2)!) ?? 0;
      final nowBucket = DateTime.now().millisecondsSinceEpoch ~/ 60000;
      return code == expected && (nowBucket - bucket).abs() <= 1;
    }
    return cleaned.contains(expected);
  }

  static String initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'AS';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  static String formatDateShort(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')} ${months[local.month - 1]} ${local.year}';
  }

  void _seedDefaults() {
    _shifts
      ..clear()
      ..addAll([
        ShiftRecord(
          id: 'shift-sen-pagi',
          dayIndex: 0,
          dayLabel: 'Sen, 28 Sep',
          shiftLabel: 'Sesi C1',
          courseName: 'Praktikum Pemrograman Mobile (Kom C)',
          timeRange: '08:00–09:40 WIB',
          room: 'Lab Komputer 1',
          asistenName: 'Abbil Rizki',
          asistenInitials: 'AR',
          partnerName: 'Andi Pratama',
          attendanceStatus: 'hadir',
          checkInTime: '07:52',
          disciplinePct: 96,
        ),
        ShiftRecord(
          id: 'shift-sen-siang',
          dayIndex: 0,
          dayLabel: 'Sen, 28 Sep',
          shiftLabel: 'Sesi C2',
          courseName: 'Praktikum Pemrograman Mobile (Kom C)',
          timeRange: '10:00–11:40 WIB',
          room: 'Lab Komputer 1',
          asistenName: 'Andi Pratama',
          asistenInitials: 'AP',
          partnerName: 'Abbil Rizki',
          attendanceStatus: 'hadir',
          checkInTime: '09:55',
          disciplinePct: 94,
        ),
        ShiftRecord(
          id: 'shift-sel-pagi',
          dayIndex: 1,
          dayLabel: 'Sel, 29 Sep',
          shiftLabel: 'Sesi C1',
          courseName: 'Praktikum Desain Interaksi (Kom C)',
          timeRange: '08:00–09:40 WIB',
          room: 'Lab Jaringan 2',
          asistenName: 'Feri Gunawan',
          asistenInitials: 'FG',
          partnerName: 'Sinta Marpaung',
          attendanceStatus: 'terlambat',
          checkInTime: '08:12',
          disciplinePct: 86,
        ),
        ShiftRecord(
          id: 'shift-rab-siang',
          dayIndex: 2,
          dayLabel: 'Rab, 30 Sep',
          shiftLabel: 'Sesi C1',
          courseName: 'Praktikum Analisis Desain Jaringan (Kom C)',
          timeRange: '10:00–11:40 WIB',
          room: 'Lab Jaringan 1',
          asistenName: 'Sinta Marpaung',
          asistenInitials: 'SM',
          partnerName: 'Abbil Rizki',
          attendanceStatus: 'hadir',
          checkInTime: '09:55',
          disciplinePct: 92,
        ),
        ShiftRecord(
          id: 'shift-kam-pagi',
          dayIndex: 3,
          dayLabel: 'Kam, 01 Okt',
          shiftLabel: 'Sesi C1',
          courseName: 'Praktikum Machine Learning (Kom C)',
          timeRange: '13:00–14:40 WIB',
          room: 'Lab AI & Data',
          asistenName: 'Abbil Rizki',
          asistenInitials: 'AR',
          partnerName: 'Rizky Harahap',
          attendanceStatus: 'belum',
          checkInTime: null,
          disciplinePct: 96,
        ),
        ShiftRecord(
          id: 'shift-jum-pagi',
          dayIndex: 3,
          dayLabel: 'Kam, 01 Okt',
          shiftLabel: 'Sesi C2',
          courseName: 'Praktikum Machine Learning (Kom C)',
          timeRange: '15:00–16:40 WIB',
          room: 'Lab AI & Data',
          asistenName: 'Rizky Harahap',
          asistenInitials: 'RH',
          partnerName: 'Abbil Rizki',
          attendanceStatus: 'belum',
          checkInTime: null,
          disciplinePct: 90,
        ),
      ]);

    _swaps
      ..clear()
      ..addAll([
        ShiftSwapRecord(
          swapCode: '#TS-015',
          requesterName: 'Feri Gunawan',
          requesterInitials: 'FG',
          targetName: 'Abbil Rizki',
          targetInitials: 'AR',
          fromShiftId: 'shift-rab-siang',
          fromShiftLabel: 'Rab, 30 Sep • 13:00',
          toShiftId: 'shift-kam-pagi',
          toShiftLabel: 'Kam, 01 Okt • 08:00',
          reason: 'Ada jadwal bimbingan skripsi di hari Rabu siang.',
          status: 'pending',
          isIncoming: true,
          isMine: true,
          metaNote: 'Menunggu konfirmasi anda',
        ),
        ShiftSwapRecord(
          swapCode: '#TS-014',
          requesterName: 'Abbil Rizki',
          requesterInitials: 'AR',
          targetName: 'Feri Gunawan',
          targetInitials: 'FG',
          fromShiftId: 'shift-rab-siang',
          fromShiftLabel: 'Rab, 30 Sep • 13:00',
          toShiftId: 'shift-kam-pagi',
          toShiftLabel: 'Kam, 01 Okt • 08:00',
          reason: 'Pertukaran shift rutin minggu ke-4.',
          status: 'approved',
          isIncoming: false,
          isMine: true,
          metaNote: 'Diajukan 27 Sep 2026 • Disetujui Feri',
        ),
        ShiftSwapRecord(
          swapCode: '#TS-013',
          requesterName: 'Sinta Marpaung',
          requesterInitials: 'SM',
          targetName: 'Rizky Harahap',
          targetInitials: 'RH',
          fromShiftId: 'shift-sel-pagi',
          fromShiftLabel: 'Sel, 22 Sep • 10:00',
          toShiftId: 'shift-jum-pagi',
          toShiftLabel: 'Kam, 24 Sep • 13:00',
          reason: 'Mengikuti seminar nasional TI.',
          status: 'approved',
          isIncoming: false,
          isMine: false,
          metaNote: 'Diajukan 20 Sep 2026 • Disetujui Rizky',
        ),
        ShiftSwapRecord(
          swapCode: '#TS-011',
          requesterName: 'Abbil Rizki',
          requesterInitials: 'AR',
          targetName: 'Sinta Marpaung',
          targetInitials: 'SM',
          fromShiftId: 'shift-sen-pagi',
          fromShiftLabel: 'Jum, 18 Sep • 08:00',
          toShiftId: 'shift-sen-siang',
          toShiftLabel: 'Sen, 21 Sep • 13:00',
          reason: 'Bentrok dengan kelas kuliah pengganti.',
          status: 'rejected',
          isIncoming: false,
          isMine: true,
          metaNote: 'Diajukan 16 Sep 2026 • Ditolak Sinta',
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
      final shiftRows = await client
          .from('lab_shifts')
          .select()
          .order('day_index', ascending: true);

      if (shiftRows.isNotEmpty) {
        _shifts
          ..clear()
          ..addAll(shiftRows
              .map((r) => ShiftRecord.fromJson(Map<String, dynamic>.from(r))));
        _backendAvailable = true;
      }

      final swapRows = await client
          .from('shift_swap_requests')
          .select()
          .order('created_at', ascending: false);

      if (swapRows.isNotEmpty) {
        _swaps
          ..clear()
          ..addAll(swapRows.map(
              (r) => ShiftSwapRecord.fromJson(Map<String, dynamic>.from(r))));
        _backendAvailable = true;
      }

      final codeRow = await client
          .from('assistant_access_codes')
          .select()
          .eq('id', 'today')
          .maybeSingle();

      if (codeRow != null) {
        _accessCode = (codeRow['code'] as String?) ?? _accessCode;
        _accessValidUntil =
            (codeRow['valid_until'] as String?) ?? _accessValidUntil;
        _backendAvailable = true;
      }

      notifyListeners();
      debugPrint(
          '[ShiftSync] Sinkronisasi sukses (${_shifts.length} shift, ${_swaps.length} tukar shift, kode $_accessCode).');
    } catch (e) {
      _backendAvailable = false;
      debugPrint(
          '[ShiftSync] Menggunakan state memori bersama (Supabase belum tersedia): $e');
    }
  }

  void _subscribeRealtime() {
    final client = SupabaseService.instance.client;
    if (client == null) return;
    try {
      _channel?.unsubscribe();
      _channel = client
          .channel('itlg-shift-sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'lab_shifts',
            callback: (_) => refreshFromBackend(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'shift_swap_requests',
            callback: (_) => refreshFromBackend(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'assistant_access_codes',
            callback: (_) => refreshFromBackend(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('[ShiftSync] Gagal pasang realtime channel: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Getter untuk Aslab & Laboran
  // ---------------------------------------------------------------------------

  List<ShiftRecord> get allShifts => List.unmodifiable(_shifts);

  List<ShiftRecord> shiftsForDay(int dayIndex) =>
      _shifts.where((s) => s.dayIndex == dayIndex).toList();

  /// Daftar asisten unik beserta status jaga & kedisiplinan (untuk Laboran).
  List<ShiftRecord> get dutyAssistants {
    final seen = <String>{};
    final result = <ShiftRecord>[];
    for (final s in _shifts) {
      if (seen.add(s.asistenName)) {
        result.add(s);
      }
    }
    return result;
  }

  int get totalShifts => _shifts.length;

  int get attendedShiftCount => _shifts
      .where((s) =>
          s.attendanceStatus == 'hadir' || s.attendanceStatus == 'terlambat')
      .length;

  int get averageDisciplinePct {
    final list = dutyAssistants;
    if (list.isEmpty) return 0;
    final sum = list.fold<int>(0, (acc, s) => acc + s.disciplinePct);
    return (sum / list.length).round();
  }

  List<String> availableAssistantNames({String? excludeName}) {
    final names = <String>{};
    for (final s in _shifts) {
      if (s.asistenName.isNotEmpty && s.asistenName != excludeName) {
        names.add(s.asistenName);
      }
      if (s.partnerName.isNotEmpty && s.partnerName != excludeName) {
        names.add(s.partnerName);
      }
    }
    if (names.isEmpty) {
      return const ['Feri Gunawan', 'Sinta Marpaung', 'Rizky Harahap'];
    }
    return names.toList();
  }

  List<ShiftSwapRecord> get allSwaps => List.unmodifiable(_swaps);

  List<ShiftSwapRecord> get pendingIncomingSwaps =>
      _swaps.where((s) => s.isIncoming && s.isPending).toList();

  /// Permintaan masuk utama yang ditampilkan pada kartu "Permintaan Tukar Shift".
  ShiftSwapRecord? get featuredIncomingSwap {
    for (final s in _swaps) {
      if (s.isIncoming && s.isPending) return s;
    }
    for (final s in _swaps) {
      if (s.isIncoming) return s;
    }
    return _swaps.isNotEmpty ? _swaps.first : null;
  }

  int get pendingSwapCount => pendingIncomingSwaps.length;

  int get approvedSwapCount => _swaps.where((s) => s.isApproved).length;

  int get rejectedSwapCount => _swaps.where((s) => s.isRejected).length;

  List<ShiftSwapRecord> swapsForTab(int tab) {
    if (tab == 1) return _swaps.where((s) => s.isMine).toList();
    if (tab == 2) return _swaps.where((s) => !s.isMine).toList();
    return List.unmodifiable(_swaps);
  }

  // ---------------------------------------------------------------------------
  // Aksi tulis ke BE Supabase + sinkronisasi lintas role
  // ---------------------------------------------------------------------------

  String _nextSwapCode() {
    var maxNum = 15;
    for (final s in _swaps) {
      final m = RegExp(r'(\d+)').firstMatch(s.swapCode);
      if (m != null) {
        final v = int.tryParse(m.group(1)!) ?? 0;
        if (v > maxNum) maxNum = v;
      }
    }
    return '#TJ-${(maxNum + 1).toString().padLeft(3, '0')}';
  }

  /// Ajukan permintaan tukar shift baru dari halaman Ajukan Tukar Shift.
  Future<ShiftSwapRecord> submitSwapRequest({
    String? requesterId,
    required String requesterName,
    required String targetName,
    ShiftRecord? fromShift,
    required String fromShiftLabel,
    ShiftRecord? toShift,
    required String toShiftLabel,
    required String reason,
  }) async {
    final code = _nextSwapCode();
    final now = DateTime.now();
    final rec = ShiftSwapRecord(
      swapCode: code,
      requesterId: requesterId,
      requesterName: requesterName,
      requesterInitials: initialsOf(requesterName),
      targetName: targetName,
      targetInitials: initialsOf(targetName),
      fromShiftId: fromShift?.id,
      fromShiftLabel: fromShiftLabel,
      toShiftId: toShift?.id,
      toShiftLabel: toShiftLabel,
      reason: reason,
      status: 'pending',
      isIncoming: false,
      isMine: true,
      metaNote: 'Diajukan ${formatDateShort(now)} • Menunggu ${targetName.split(' ').first}',
      createdAt: now,
    );

    _swaps.insert(0, rec);
    notifyListeners();

    NotificationSyncService.instance.push(
      role: 'aslab',
      icon: 'arrow_right_left',
      title: 'Pengajuan Tukar Shift ($code)',
      body: '$requesterName → $targetName ($fromShiftLabel ↔ $toShiftLabel)',
      targetKey: 'shiftJaga',
      important: true,
    );

    NotificationSyncService.instance.push(
      role: 'laboran',
      icon: 'arrow_right_left',
      title: 'Pengajuan Tukar Shift Asisten ($code)',
      body: '$requesterName mengajukan tukar shift dengan $targetName',
      targetKey: 'presensi',
      important: false,
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('shift_swap_requests').insert({
          'swap_code': rec.swapCode,
          'requester_id': rec.requesterId,
          'requester_name': rec.requesterName,
          'requester_initials': rec.requesterInitials,
          'target_name': rec.targetName,
          'target_initials': rec.targetInitials,
          'from_shift_id': rec.fromShiftId,
          'from_shift_label': rec.fromShiftLabel,
          'to_shift_id': rec.toShiftId,
          'to_shift_label': rec.toShiftLabel,
          'reason': rec.reason,
          'status': rec.status,
          'is_incoming': rec.isIncoming,
          'is_mine': rec.isMine,
          'meta_note': rec.metaNote,
          'created_at': now.toIso8601String(),
        });
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[ShiftSync] Insert swap request fallback lokal: $e');
      }
    }

    return rec;
  }

  /// Terima / Tolak permintaan tukar shift. Jika disetujui, jadwal shift di
  /// `lab_shifts` otomatis tertukar dan tersinkron ke Aslab & Laboran.
  Future<void> decideSwap({
    required String swapCode,
    required bool accept,
    required String decidedByName,
  }) async {
    ShiftSwapRecord? target;
    for (final s in _swaps) {
      if (s.swapCode == swapCode) {
        target = s;
        break;
      }
    }
    if (target == null || !target.isPending) return;
    // Hanya penerima yang dapat menyetujui/menolak permintaan masuk
    if (!target.isIncoming &&
        target.requesterName.toLowerCase() ==
            decidedByName.trim().toLowerCase()) {
      return;
    }

    final now = DateTime.now();
    final deciderFirst = decidedByName.trim().split(' ').first;
    target.status = accept ? 'approved' : 'rejected';
    target.decidedAt = now;
    target.metaNote =
        'Diputuskan ${formatDateShort(now)} • ${accept ? 'Disetujui' : 'Ditolak'} $deciderFirst';

    // Jika disetujui, tukar penugasan asisten pada kedua shift di BE
    if (accept) {
      ShiftRecord? sFrom;
      ShiftRecord? sTo;
      for (final sh in _shifts) {
        if (target.fromShiftId != null && sh.id == target.fromShiftId) {
          sFrom = sh;
        }
        if (target.toShiftId != null && sh.id == target.toShiftId) {
          sTo = sh;
        }
      }
      if (sFrom != null && sTo != null) {
        final tmpName = sFrom.asistenName;
        final tmpInit = sFrom.asistenInitials;
        sFrom.asistenName = sTo.asistenName;
        sFrom.asistenInitials = sTo.asistenInitials;
        sFrom.updatedAt = now;
        sTo.asistenName = tmpName;
        sTo.asistenInitials = tmpInit;
        sTo.updatedAt = now;
      }
    }

    notifyListeners();

    NotificationSyncService.instance.push(
      role: 'aslab',
      icon: accept ? 'circle_check' : 'cross',
      title: 'Tukar Shift $swapCode ${accept ? 'Disetujui' : 'Ditolak'}',
      body:
          '${target.requesterName} & ${target.targetName} (${target.fromShiftLabel} ↔ ${target.toShiftLabel})',
      targetKey: 'shiftJaga',
      important: true,
    );

    NotificationSyncService.instance.push(
      role: 'laboran',
      icon: 'arrow_right_left',
      title: 'Jadwal Shift Diperbarui ($swapCode)',
      body: accept
          ? '${target.requesterName} bertukar shift dengan ${target.targetName}'
          : 'Tukar shift ${target.requesterName} & ${target.targetName} ditolak',
      targetKey: 'presensi',
      important: accept,
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('shift_swap_requests').update({
          'status': target.status,
          'meta_note': target.metaNote,
          'decided_at': now.toIso8601String(),
        }).eq('swap_code', swapCode);

        if (accept) {
          for (final sh in _shifts) {
            if (sh.id == target.fromShiftId || sh.id == target.toShiftId) {
              await client.from('lab_shifts').update({
                'asisten_name': sh.asistenName,
                'asisten_initials': sh.asistenInitials,
                'updated_at': now.toIso8601String(),
              }).eq('id', sh.id);
            }
          }
        }
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[ShiftSync] Decide swap fallback lokal: $e');
      }
    }
  }

  /// Batalkan pengajuan tukar jadwal (hanya bisa dilakukan pemohon selama masih menunggu).
  Future<bool> cancelSwap({
    required String swapCode,
    required String requesterName,
  }) async {
    ShiftSwapRecord? target;
    for (final s in _swaps) {
      if (s.swapCode == swapCode) {
        target = s;
        break;
      }
    }
    if (target == null || !target.isPending) return false;
    if (target.isIncoming &&
        target.requesterName.toLowerCase() !=
            requesterName.trim().toLowerCase()) {
      return false;
    }

    final now = DateTime.now();
    target.status = 'rejected';
    target.decidedAt = now;
    target.metaNote = 'Dibatalkan ${formatDateShort(now)} oleh pemohon';
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('shift_swap_requests').update({
          'status': 'rejected',
          'meta_note': target.metaNote,
          'decided_at': now.toIso8601String(),
        }).eq('swap_code', swapCode);
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[ShiftSync] cancelSwap error: $e');
      }
    }
    return true;
  }

  /// Laboran menghasilkan Kode Akses Presensi Asisten baru & menyimpannya ke BE.
  Future<String> generateAccessCode({required String generatedBy}) async {
    final nextCode = 'ITLG-${1000 + Random().nextInt(9000)}';
    _accessCode = nextCode;
    notifyListeners();

    NotificationSyncService.instance.push(
      role: 'aslab',
      icon: 'key',
      title: 'Kode Akses Shift Diperbarui',
      body: 'Kode presensi shift hari ini: $nextCode (berlaku s/d $_accessValidUntil)',
      targetKey: 'shiftJaga',
      important: true,
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('assistant_access_codes').upsert(
          {
            'id': 'today',
            'code': nextCode,
            'valid_until': _accessValidUntil,
            'generated_by': generatedBy,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'id',
        );
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[ShiftSync] Update access code fallback lokal: $e');
      }
    }

    return nextCode;
  }

  /// Perbarui status presensi shift seorang asisten oleh Laboran (atau check-in).
  Future<void> updateShiftAttendance({
    required String shiftId,
    required String status, // 'hadir' | 'terlambat' | 'belum'
  }) async {
    ShiftRecord? rec;
    for (final s in _shifts) {
      if (s.id == shiftId) {
        rec = s;
        break;
      }
    }
    if (rec == null) return;

    final now = DateTime.now();
    final clock =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    rec.attendanceStatus = status;
    rec.checkInTime = status == 'belum' ? null : clock;
    if (status == 'hadir') {
      rec.disciplinePct = (rec.disciplinePct + 2).clamp(0, 100);
    } else if (status == 'terlambat') {
      rec.disciplinePct = (rec.disciplinePct - 4).clamp(50, 100);
    }
    rec.updatedAt = now;
    notifyListeners();

    final statusLabel = status == 'hadir'
        ? 'Hadir ($clock)'
        : (status == 'terlambat' ? 'Terlambat ($clock)' : 'Belum Hadir');
    NotificationSyncService.instance.push(
      role: 'aslab',
      icon: status == 'hadir' ? 'circle_check' : 'clock',
      title: 'Presensi Shift Diperbarui',
      body: '${rec.asistenName} • ${rec.shiftLabel} (${rec.room}): $statusLabel',
      targetKey: 'shiftJaga',
      important: false,
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('lab_shifts').update({
          'attendance_status': rec.attendanceStatus,
          'check_in_time': rec.checkInTime,
          'discipline_pct': rec.disciplinePct,
          'updated_at': now.toIso8601String(),
        }).eq('id', shiftId);
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[ShiftSync] Update attendance fallback lokal: $e');
      }
    }
  }
}
