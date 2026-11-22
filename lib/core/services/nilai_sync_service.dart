import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/dosen/dosen_store.dart';
import '../../features/shared/profil_data.dart';
import 'notification_sync_service.dart';
import 'praktikum_sync_service.dart';
import 'presensi_sync_service.dart';
import 'supabase_service.dart';

/// Status validasi nilai akhir per mata kuliah (Dosen ↔ Aslab ↔ Praktikan).
class GradeValidationRecord {
  final String courseId;

  /// 'pending' | 'revision_requested' | 'validated'
  String status;
  String? revisionPart;
  String? revisionNote;
  String? validatedBy;
  DateTime updatedAt;

  GradeValidationRecord({
    required this.courseId,
    this.status = 'pending',
    this.revisionPart,
    this.revisionNote,
    this.validatedBy,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get isValidated => status == 'validated';
  bool get isRevisionRequested => status == 'revision_requested';

  factory GradeValidationRecord.fromJson(Map<String, dynamic> json) {
    return GradeValidationRecord(
      courseId: (json['course_id'] ?? 'pemob').toString(),
      status: (json['status'] ?? 'pending').toString(),
      revisionPart: json['revision_part'] as String?,
      revisionNote: json['revision_note'] as String?,
      validatedBy: json['validated_by'] as String?,
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Catatan sanggahan nilai oleh Praktikan.
class GradeAppealRecord {
  final String id;
  final String courseId;
  final int modul;
  final String userIdentifier;
  final String userName;
  final List<String> components;
  final String reason;
  final String? attachmentName;
  String status;
  final DateTime createdAt;

  GradeAppealRecord({
    required this.id,
    required this.courseId,
    required this.modul,
    required this.userIdentifier,
    required this.userName,
    required this.components,
    required this.reason,
    this.attachmentName,
    this.status = 'pending',
    required this.createdAt,
  });

  factory GradeAppealRecord.fromJson(Map<String, dynamic> json) {
    final comps = ((json['components_json'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    return GradeAppealRecord(
      id: (json['id'] ?? '').toString(),
      courseId: (json['course_id'] ?? 'pemob').toString(),
      modul: (json['modul'] as num?)?.toInt() ?? 4,
      userIdentifier: (json['user_identifier'] ?? '').toString(),
      userName: (json['user_name'] ?? 'Praktikan').toString(),
      components: comps,
      reason: (json['reason'] ?? '').toString(),
      attachmentName: json['attachment_name'] as String?,
      status: (json['status'] ?? 'pending').toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Service pusat sinkronisasi Nilai Akhir, Validasi Dosen, Revisi Asisten,
/// Sanggahan Nilai Praktikan, dan Tindak Lanjut lintas role via Supabase.
class NilaiSyncService extends ChangeNotifier {
  static final NilaiSyncService instance = NilaiSyncService._internal();
  NilaiSyncService._internal() {
    _seedDefaults();
  }

  final Map<String, GradeValidationRecord> _validations = {};
  final List<GradeAppealRecord> _appeals = [];
  String _selectedCourseId = 'pemob';

  String get selectedCourseId => _selectedCourseId;

  void selectCourse(String courseId) {
    if (_selectedCourseId == courseId) return;
    _selectedCourseId = courseId;
    notifyListeners();
  }

  RealtimeChannel? _channel;
  bool _initialized = false;
  bool _backendAvailable = false;
  bool get isBackendAvailable => _backendAvailable;

  List<GradeAppealRecord> get appeals => List.unmodifiable(_appeals);

  GradeAppealRecord? appealFor(
      String courseId, int modul, String userIdentifier) {
    for (final a in _appeals) {
      if (a.courseId == courseId &&
          a.modul == modul &&
          a.userIdentifier == userIdentifier) {
        return a;
      }
    }
    return null;
  }

  GradeAppealRecord? pendingAppealForStudent(
      String courseId, String userIdentifier) {
    for (final a in _appeals) {
      if (a.courseId == courseId &&
          a.userIdentifier == userIdentifier &&
          a.status == 'pending') {
        return a;
      }
    }
    return null;
  }

  List<GradeAppealRecord> pendingAppealsForCourse(String courseId) {
    return _appeals
        .where((a) => a.courseId == courseId && a.status == 'pending')
        .toList();
  }

  /// Tandai sanggahan nilai sebagai selesai ditinjau saat Aslab menyimpan
  /// nilai revisi, lalu sinkronkan ke Supabase & kirim notifikasi ke Praktikan.
  Future<void> resolveAppeal({
    required String courseId,
    required int modul,
    required String userIdentifier,
    required int newScore,
    required String feedback,
  }) async {
    GradeAppealRecord? matched;
    for (final a in _appeals) {
      if (a.courseId == courseId &&
          a.modul == modul &&
          a.userIdentifier == userIdentifier &&
          a.status != 'resolved') {
        a.status = 'resolved';
        matched = a;
      }
    }
    if (matched == null) return;
    notifyListeners();

    final course = PraktikumSyncService.instance.courseById(courseId);
    NotificationSyncService.instance.push(
      role: 'praktikan',
      icon: 'circle_check',
      title: 'Sanggahan Modul $modul Diselesaikan',
      body:
          'Praktikum ${course.name}: nilai diperbarui menjadi $newScore / 100${feedback.isNotEmpty ? ' • $feedback' : ''}',
      targetKey: 'detailNilai',
      important: true,
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client
            .from('grade_appeals')
            .update({'status': 'resolved'})
            .eq('course_id', courseId)
            .eq('modul', modul)
            .eq('user_identifier', userIdentifier);
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[NilaiSync] resolveAppeal error: $e');
      }
    }
  }

  GradeValidationRecord validationFor(String courseId) {
    return _validations[courseId] ??
        GradeValidationRecord(courseId: courseId, status: 'pending');
  }

  bool isCourseValidated(String courseId) =>
      validationFor(courseId).isValidated;

  int get pendingValidationCount =>
      _validations.values.where((v) => !v.isValidated).length;

  void _seedDefaults() {
    _validations
      ..clear()
      ..addAll({
        'pemob': GradeValidationRecord(courseId: 'pemob', status: 'pending'),
        'desain': GradeValidationRecord(courseId: 'desain', status: 'pending'),
        'adj': GradeValidationRecord(courseId: 'adj', status: 'validated'),
        'ml': GradeValidationRecord(courseId: 'ml', status: 'validated'),
      });
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
      final valRows = await client.from('grade_validations').select();
      for (final r in valRows) {
        final rec =
            GradeValidationRecord.fromJson(Map<String, dynamic>.from(r));
        _validations[rec.courseId] = rec;
      }

      final appRows = await client
          .from('grade_appeals')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      _appeals
        ..clear()
        ..addAll(appRows
            .map((r) => GradeAppealRecord.fromJson(Map<String, dynamic>.from(r))));

      _backendAvailable = true;
      notifyListeners();
      debugPrint(
          '[NilaiSync] Berhasil sinkronisasi ${_validations.length} validasi & ${_appeals.length} sanggahan dari Supabase.');
    } catch (e) {
      _backendAvailable = false;
      debugPrint(
          '[NilaiSync] Menggunakan state nilai bersama (Supabase belum dijalankan / offline): $e');
    }
  }

  void _subscribeRealtime() {
    final client = SupabaseService.instance.client;
    if (client == null) return;
    try {
      _channel?.unsubscribe();
      _channel = client
          .channel('itlg-nilai-sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'grade_validations',
            callback: (_) => refreshFromBackend(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'grade_appeals',
            callback: (_) => refreshFromBackend(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('[NilaiSync] Gagal pasang realtime channel: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Perhitungan Nilai Live lintas Praktikan ↔ Aslab ↔ Dosen
  // ---------------------------------------------------------------------------

  static String letterForScore(int score) {
    if (score >= 88) return 'A';
    if (score >= 85) return 'A-';
    if (score >= 80) return 'B+';
    if (score >= 75) return 'B';
    if (score >= 70) return 'B-';
    if (score >= 65) return 'C+';
    if (score >= 60) return 'C';
    return 'D';
  }

  /// Gabungkan daftar nilai dasar Dosen dengan nilai tugas live dari
  /// [PraktikumSyncService] dan kehadiran live dari [PresensiSyncService].
  List<DosenGrade> liveDosenGrades(
    List<DosenGrade> baseGrades, {
    String courseId = 'pemob',
  }) {
    final praktikumSync = PraktikumSyncService.instance;
    final presensiSync = PresensiSyncService.instance;
    final course = praktikumSync.courseById(courseId);

    final gradedByNim = <String, TugasSubmissionRecord>{};
    for (final s in praktikumSync.allSubmissions) {
      if (s.courseId == courseId && s.status == 'graded' && s.score != null) {
        gradedByNim[s.userIdentifier] = s;
      }
    }

    final result = <DosenGrade>[];
    final seenNims = <String>{};

    // Tambahkan nilai aktual praktikan utama yang login bila belum ada di base
    final mainNim = ProfilData.praktikan.idValue;
    final mainName = ProfilData.praktikan.name;
    final mainAvg = double.tryParse(
            praktikumSync.effectiveAverageForCourse(course, mainNim).replaceAll(',', '.')) ??
        88.0;
    final mainSummary = presensiSync.summaryForCourse(course, mainNim);
    final mainDenom = mainSummary.doneMeetings > 0 ? mainSummary.doneMeetings : 4;
    final mainAttendPct =
        ((mainSummary.hadir * 100) / mainDenom).round().clamp(0, 100);
    final mainFinal = ((mainAvg * 0.75) + (mainAttendPct * 0.25)).round();
    if (!baseGrades.any((g) => g.nim == mainNim)) {
      seenNims.add(mainNim);
      result.add(
        DosenGrade(
          mainName,
          mainNim,
          '${mainAvg.round()}',
          '$mainAttendPct%',
          '$mainFinal',
          letterForScore(mainFinal),
        ),
      );
    }

    for (final g in baseGrades) {
      seenNims.add(g.nim);
      final liveSub = gradedByNim[g.nim];
      if (liveSub != null && liveSub.score != null) {
        final presPct =
            int.tryParse(g.presensi.replaceAll('%', '').trim()) ?? 92;
        final tugasScore = liveSub.score!;
        final akhir = ((tugasScore * 0.75) + (presPct * 0.25)).round();
        result.add(
          DosenGrade(
            g.name,
            g.nim,
            '$tugasScore',
            '$presPct%',
            '$akhir',
            letterForScore(akhir),
          ),
        );
      } else {
        result.add(g);
      }
    }

    // Tambahkan praktikan lain yang baru dinilai Aslab bila belum di list
    for (final entry in gradedByNim.entries) {
      if (seenNims.contains(entry.key)) continue;
      final s = entry.value;
      final tugasScore = s.score ?? 85;
      final akhir = ((tugasScore * 0.75) + (92 * 0.25)).round();
      result.insert(
        0,
        DosenGrade(
          s.userName,
          s.userIdentifier,
          '$tugasScore',
          '92%',
          '$akhir',
          letterForScore(akhir),
        ),
      );
    }

    return result;
  }

  /// Ringkasan statistik nilai & kehadiran live untuk kartu Dosen.
  ({String avgScore, int passCount, int totalCount, int avgAttendPct})
      summarizeGrades(List<DosenGrade> grades) {
    if (grades.isEmpty) {
      return (avgScore: '0,0', passCount: 0, totalCount: 0, avgAttendPct: 0);
    }
    var sumScore = 0.0;
    var sumAttend = 0;
    var pass = 0;
    for (final g in grades) {
      final s = int.tryParse(g.akhir) ?? 0;
      sumScore += s;
      if (g.lulus) pass++;
      sumAttend += int.tryParse(g.presensi.replaceAll('%', '').trim()) ?? 90;
    }
    final avg = (sumScore / grades.length)
        .toStringAsFixed(1)
        .replaceAll('.', ',');
    final avgAtt = (sumAttend / grades.length).round();
    return (
      avgScore: avg,
      passCount: pass,
      totalCount: grades.length,
      avgAttendPct: avgAtt,
    );
  }

  // ---------------------------------------------------------------------------
  // Aksi Backend: Validasi Dosen, Minta Revisi, Sanggah Nilai, Hubungi Asisten
  // ---------------------------------------------------------------------------

  Future<void> validateCourse({
    String courseId = 'pemob',
    required String validatedBy,
  }) async {
    final now = DateTime.now();
    _validations[courseId] = GradeValidationRecord(
      courseId: courseId,
      status: 'validated',
      validatedBy: validatedBy,
      updatedAt: now,
    );
    notifyListeners();

    final course = PraktikumSyncService.instance.courseById(courseId);
    NotificationSyncService.instance.push(
      role: 'aslab',
      icon: 'circle_check',
      title: 'Nilai Akhir Tervalidasi Dosen',
      body:
          'Nilai akhir ${course.name} (${course.kelas}) telah disahkan oleh $validatedBy',
      targetKey: 'evaluasi',
      important: true,
    );
    NotificationSyncService.instance.push(
      role: 'praktikan',
      icon: 'trophy',
      title: 'Nilai Akhir Praktikum Tervalidasi',
      body:
          'Nilai akhir Praktikum ${course.name} telah disinkronkan ke Portal Akademik',
      targetKey: 'detailNilai',
      important: true,
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('grade_validations').upsert(
          {
            'course_id': courseId,
            'status': 'validated',
            'validated_by': validatedBy,
            'updated_at': now.toIso8601String(),
          },
          onConflict: 'course_id',
        );
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[NilaiSync] validateCourse error: $e');
      }
    }
  }

  Future<void> requestRevision({
    String courseId = 'pemob',
    required String part,
    required String note,
    required List<String> assistants,
    required String requestedBy,
  }) async {
    final now = DateTime.now();
    _validations[courseId] = GradeValidationRecord(
      courseId: courseId,
      status: 'revision_requested',
      revisionPart: part,
      revisionNote: note,
      validatedBy: requestedBy,
      updatedAt: now,
    );
    notifyListeners();

    final course = PraktikumSyncService.instance.courseById(courseId);
    NotificationSyncService.instance.push(
      role: 'aslab',
      icon: 'pencil',
      title: 'Revisi $part Diminta Dosen',
      body: '${course.name} (${assistants.join(', ')}): $note',
      targetKey: 'evaluasi',
      important: true,
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('grade_validations').upsert(
          {
            'course_id': courseId,
            'status': 'revision_requested',
            'revision_part': part,
            'revision_note': note,
            'validated_by': requestedBy,
            'updated_at': now.toIso8601String(),
          },
          onConflict: 'course_id',
        );
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[NilaiSync] requestRevision error: $e');
      }
    }
  }

  Future<void> submitGradeAppeal({
    required String courseId,
    required int modul,
    required String userIdentifier,
    required String userName,
    required List<String> components,
    required String reason,
    String? attachmentName,
  }) async {
    final now = DateTime.now();
    final rec = GradeAppealRecord(
      id: 'local-appeal-${now.millisecondsSinceEpoch}',
      courseId: courseId,
      modul: modul,
      userIdentifier: userIdentifier,
      userName: userName,
      components: components,
      reason: reason,
      attachmentName: attachmentName,
      status: 'pending',
      createdAt: now,
    );
    // Perbarui sanggahan lama jika praktikan mengirim ulang untuk modul sama
    _appeals.removeWhere((a) =>
        a.courseId == courseId &&
        a.modul == modul &&
        a.userIdentifier == userIdentifier);
    _appeals.insert(0, rec);
    notifyListeners();

    final course = PraktikumSyncService.instance.courseById(courseId);
    NotificationSyncService.instance.push(
      role: 'aslab',
      icon: 'chat_bubble',
      title: 'Sanggahan Nilai Modul $modul',
      body:
          '$userName ($userIdentifier) menyanggah ${components.join(', ')} • ${course.name}',
      targetKey: 'evaluasi',
      important: true,
    );
    NotificationSyncService.instance.push(
      role: 'dosen',
      icon: 'clipboard',
      title: 'Sanggahan Nilai Praktikan',
      body: '$userName menyanggah nilai Modul $modul Praktikum ${course.name}',
      targetKey: 'validasi',
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('grade_appeals').insert({
          'course_id': courseId,
          'modul': modul,
          'user_identifier': userIdentifier,
          'user_name': userName,
          'components_json': components,
          'reason': reason,
          'attachment_name': attachmentName,
          'status': 'pending',
          'created_at': now.toIso8601String(),
        });
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[NilaiSync] submitGradeAppeal error: $e');
      }
    }
  }

  Future<void> sendAssistantFollowUp({
    required String studentNim,
    required String studentName,
    required String assistantName,
    required String followUpType,
    required String message,
  }) async {
    final now = DateTime.now();
    NotificationSyncService.instance.push(
      role: 'aslab',
      icon: 'chat_bubble',
      title: 'Tindak Lanjut Dosen: $followUpType',
      body: 'Untuk $studentName ($studentNim): $message',
      targetKey: 'detailPresensi',
      important: true,
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('assistant_followups').insert({
          'student_nim': studentNim,
          'student_name': studentName,
          'assistant_name': assistantName,
          'followup_type': followUpType,
          'message': message,
          'created_at': now.toIso8601String(),
        });
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[NilaiSync] sendAssistantFollowUp error: $e');
      }
    }
  }
}
