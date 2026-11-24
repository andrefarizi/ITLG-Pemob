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

  /// 'draft' | 'pending' (diajukan) | 'revision_requested' (revisi) | 'validated' (divalidasi)
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

  bool get isDraft => status == 'draft';
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
  final int currentScore;
  final int proposedScore;
  String? assistantRecommendation;
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
    this.currentScore = 70,
    this.proposedScore = 85,
    this.assistantRecommendation,
    this.status = 'pending',
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isRecommendedApprove => status == 'recommended_approve';
  bool get isRecommendedReject => status == 'recommended_reject';
  bool get isWaitingAslab => status == 'pending';
  bool get isWaitingDosen =>
      status == 'pending' ||
      status == 'recommended_approve' ||
      status == 'recommended_reject';
  bool get isApproved => status == 'approved' || status == 'resolved';
  bool get isRejected => status == 'rejected';

  String get initials {
    final parts = userName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'PR';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

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
      currentScore: (json['current_score'] as num?)?.toInt() ?? 70,
      proposedScore: (json['proposed_score'] as num?)?.toInt() ?? 85,
      assistantRecommendation: json['assistant_recommendation'] as String?,
      status: (json['status'] ?? 'pending').toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Catatan pesan tindak lanjut Dosen ke Asisten (Dosen ↔ Aslab ↔ Praktikan).
class AssistantFollowUpRecord {
  final String id;
  final String studentNim;
  final String studentName;
  final String assistantName;
  final String followUpType;
  final String message;
  String status;
  final DateTime createdAt;

  AssistantFollowUpRecord({
    required this.id,
    required this.studentNim,
    required this.studentName,
    required this.assistantName,
    required this.followUpType,
    required this.message,
    this.status = 'pending',
    required this.createdAt,
  });

  bool get isDone => status == 'done';

  String get formattedClock {
    final local = createdAt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} WIB';
  }

  factory AssistantFollowUpRecord.fromJson(Map<String, dynamic> json) {
    return AssistantFollowUpRecord(
      id: (json['id'] ?? '').toString(),
      studentNim: (json['student_nim'] ?? '').toString(),
      studentName: (json['student_name'] ?? 'Praktikan').toString(),
      assistantName: (json['assistant_name'] ?? 'Asisten Lab').toString(),
      followUpType: (json['followup_type'] ?? 'Konsultasi').toString(),
      message: (json['message'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Riwayat unduhan laporan Dosen yang tersinkron ke Supabase (`public.report_downloads`).
class ReportDownloadRecord {
  final String id;
  final String title;
  final String courseName;
  final String fileName;
  final String format;
  final String sizeLabel;
  final String localPath;
  final String downloadedBy;
  final DateTime createdAt;

  const ReportDownloadRecord({
    required this.id,
    required this.title,
    required this.courseName,
    required this.fileName,
    required this.format,
    required this.sizeLabel,
    required this.localPath,
    required this.downloadedBy,
    required this.createdAt,
  });

  bool get isSpreadsheet {
    final f = format.toLowerCase();
    final n = fileName.toLowerCase();
    return f == 'xlsx' || f == 'csv' || n.endsWith('.xlsx') || n.endsWith('.csv');
  }

  String get monthHeader {
    const monthsFull = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final local = createdAt.toLocal();
    return '${monthsFull[local.month - 1]} ${local.year}';
  }

  String get metaLabel {
    const monthsShort = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final local = createdAt.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    return '$dd ${monthsShort[local.month - 1]} ${local.year} • $sizeLabel';
  }

  DosenDownload toDosenDownload() =>
      DosenDownload(monthHeader, fileName, metaLabel, isSpreadsheet);

  factory ReportDownloadRecord.fromJson(Map<String, dynamic> json) {
    return ReportDownloadRecord(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Laporan Praktikum').toString(),
      courseName: (json['course_name'] ?? 'Semua Praktikum').toString(),
      fileName: (json['file_name'] ?? 'Laporan.pdf').toString(),
      format: (json['format'] ?? 'PDF').toString(),
      sizeLabel: (json['size_label'] ?? '120 KB').toString(),
      localPath: (json['local_path'] ?? '').toString(),
      downloadedBy: (json['downloaded_by'] ?? 'Dosen Pengampu').toString(),
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
  final List<AssistantFollowUpRecord> _followUps = [];
  final List<ReportDownloadRecord> _reportDownloads = [];
  String _selectedCourseId = 'pemob';

  String get selectedCourseId => _selectedCourseId;

  List<AssistantFollowUpRecord> get allFollowUps =>
      List.unmodifiable(_followUps);

  List<ReportDownloadRecord> get reportDownloads =>
      List.unmodifiable(_reportDownloads);

  /// Rincian nilai per modul berbasis data live [PraktikumSyncService] &
  /// [PresensiSyncService] untuk tampilan "Sheet Rincian Nilai per Modul" Dosen.
  List<({String label, int? tugasScore, int? kuisScore, bool hadir, int? finalScore})>
      moduleBreakdownForStudent({
    required String courseId,
    required String nim,
    int? fallbackBase,
  }) {
    final prak = PraktikumSyncService.instance;
    final pres = PresensiSyncService.instance;
    final course = prak.courseById(courseId);
    final isMainUser = nim == ProfilData.praktikan.idValue;
    final meetings = [...course.meetings]
      ..sort((a, b) => a.number.compareTo(b.number));
    final list =
        <({String label, int? tugasScore, int? kuisScore, bool hadir, int? finalScore})>[];

    for (final m in meetings) {
      final sub = prak.submissionFor(courseId, m.number, nim);
      final quiz = prak.quizAttemptFor(courseId, m.number, nim);
      final att = pres.recordFor(courseId, m.number, nim);

      int? tugas = (sub != null && sub.status == 'graded') ? sub.score : null;
      int? kuis = quiz?.score;

      // Untuk modul yang sudah lewat dan ada nilai seed course.grades bagi praktikan utama
      if (isMainUser && tugas == null) {
        for (final g in course.grades) {
          if (g.modul == m.number) {
            final parsedScore = int.tryParse((g.score ?? '').trim());
            tugas = parsedScore;
            if (kuis == null) {
              for (final comp in g.components) {
                if (comp.$1.toLowerCase().contains('kuis') ||
                    comp.$1.toLowerCase().contains('pre')) {
                  kuis = int.tryParse(comp.$2.trim());
                  break;
                }
              }
            }
            break;
          }
        }
      }

      // Jika mahasiswa lain belum punya row modul di DB, gunakan nilai tugas live/base untuk modul selesai
      final isDoneMeeting = m.status.name != 'upcoming';
      if (!isMainUser && tugas == null && isDoneMeeting && fallbackBase != null) {
        tugas = fallbackBase;
      }

      final hadir = att != null
          ? att.status.name == 'hadir'
          : m.status.name == 'hadir';

      int? avg;
      if (tugas != null && kuis != null) {
        avg = ((tugas + kuis) / 2).round();
      } else if (tugas != null) {
        avg = tugas;
      } else if (kuis != null) {
        avg = kuis;
      }

      list.add((
        label: 'Modul ${m.number}',
        tugasScore: tugas,
        kuisScore: kuis,
        hadir: hadir,
        finalScore: avg,
      ));
    }
    return list;
  }

  /// Simpan riwayat unduhan laporan Dosen ke Supabase (`public.report_downloads`).
  Future<ReportDownloadRecord> recordReportDownload({
    required String title,
    required String courseName,
    required String fileName,
    required String format,
    required String sizeLabel,
    required String localPath,
    required String downloadedBy,
  }) async {
    final now = DateTime.now();
    final rec = ReportDownloadRecord(
      id: 'local-dl-${now.millisecondsSinceEpoch}',
      title: title,
      courseName: courseName,
      fileName: fileName,
      format: format,
      sizeLabel: sizeLabel,
      localPath: localPath,
      downloadedBy: downloadedBy,
      createdAt: now,
    );
    _reportDownloads.insert(0, rec);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('report_downloads').insert({
          'title': title,
          'course_name': courseName,
          'file_name': fileName,
          'format': format,
          'size_label': sizeLabel,
          'local_path': localPath,
          'downloaded_by': downloadedBy,
          'created_at': now.toIso8601String(),
        });
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[NilaiSync] recordReportDownload error: $e');
      }
    }
    return rec;
  }

  List<AssistantFollowUpRecord> followUpsForStudent(String studentNim) {
    return _followUps.where((f) => f.studentNim == studentNim).toList();
  }

  AssistantFollowUpRecord? latestFollowUpForStudent(String studentNim) {
    for (final f in _followUps) {
      if (f.studentNim == studentNim) return f;
    }
    return null;
  }

  /// Gabungkan daftar praktikan berisiko dasar dengan nilai & presensi live BE.
  List<DosenStudent> liveAtRiskStudents(List<DosenStudent> baseStudents) {
    final prak = PraktikumSyncService.instance;
    final presensi = PresensiSyncService.instance;
    final pemob = prak.courseById('pemob');
    final result = <DosenStudent>[];

    for (final s in baseStudents) {
      final sub = prak.submissionFor('pemob', 4, s.nim);
      final liveScore =
          (sub != null && sub.status == 'graded' && sub.score != null)
              ? sub.score!
              : s.score;
      final liveHighRisk = s.attendance < 75 && liveScore < 70;
      result.add(
        DosenStudent(
          initials: s.initials,
          name: s.name,
          nim: s.nim,
          kelas: s.kelas,
          attendance: s.attendance,
          score: liveScore,
          highRisk: liveHighRisk || s.highRisk,
          hadir: s.hadir,
          izin: s.izin,
          alpa: s.alpa,
          meetings: s.meetings,
          asisten: s.asisten,
          asistenInitials: s.asistenInitials,
          followUp: s.followUp,
          message: s.message,
        ),
      );
    }

    // Jika praktikan utama yang login saat ini nilainya < 70 atau hadir < 75%,
    // otomatis muncul di Peringatan Dini Dosen secara real-time!
    final mainNim = ProfilData.praktikan.idValue;
    final mainName = ProfilData.praktikan.name;
    final mainAvg = double.tryParse(
            prak.effectiveAverageForCourse(pemob, mainNim).replaceAll(',', '.')) ??
        88.0;
    final mainSum = presensi.summaryForCourse(pemob, mainNim);
    final denom = mainSum.doneMeetings > 0 ? mainSum.doneMeetings : 4;
    final mainAtt = ((mainSum.hadir * 100) / denom).round().clamp(0, 100);
    if ((mainAtt < 75 || mainAvg < 70) &&
        !result.any((x) => x.nim == mainNim)) {
      final parts = mainName.trim().split(RegExp(r'\s+'));
      final init = parts.length >= 2
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : 'PR';
      result.insert(
        0,
        DosenStudent(
          initials: init,
          name: mainName,
          nim: mainNim,
          kelas: 'Kelas C',
          attendance: mainAtt,
          score: mainAvg.round(),
          highRisk: mainAtt < 75 && mainAvg < 70,
          hadir: mainSum.hadir,
          izin: mainSum.izin,
          alpa: mainSum.alpa,
          meetings: const [],
          asisten: pemob.asisten,
          asistenInitials: pemob.asistenInitials,
          followUp: mainAtt < 75 ? 0 : 2,
          message:
              'Halo ${pemob.asisten.split(' ').first}, mohon bantu tindak lanjut untuk $mainName ($mainNim) terkait capaian praktikum.',
        ),
      );
    }
    return result;
  }

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

  int get pendingAppealCount => _appeals.where((a) => a.isWaitingAslab).length;
  int get pendingDosenAppealCount =>
      _appeals.where((a) => a.isWaitingDosen).length;

  /// Rekomendasi sanggahan (Aslab) atau Keputusan akhir sanggahan (Dosen).
  /// Sesuai desain: Aslab hanya memberi rekomendasi; keputusan akhir & perubahan
  /// nilai resmi (+ log `public.grade_change_logs`) dilakukan oleh Dosen.
  Future<void> decideAppeal({
    required GradeAppealRecord appeal,
    required bool approve,
    int? newScore,
    String? rejectionReason,
    required String decidedBy,
    bool byDosen = false,
  }) async {
    final oldScore = appeal.currentScore;
    final finalScore = newScore ?? appeal.proposedScore;
    final cleanReason = rejectionReason?.trim() ?? '';
    final compLabel = appeal.components.isNotEmpty
        ? appeal.components.first
        : 'Modul ${appeal.modul}';

    if (!byDosen) {
      // Aslab hanya memberikan rekomendasi -> diteruskan ke Dosen untuk keputusan akhir
      appeal.status = approve ? 'recommended_approve' : 'recommended_reject';
      appeal.assistantRecommendation = approve
          ? 'Rekomendasi Asisten ($decidedBy): setujui ($finalScore), rubrik poin sudah terpenuhi.'
          : 'Rekomendasi Asisten ($decidedBy): tolak${cleanReason.isNotEmpty ? ' • $cleanReason' : ''}.';
      notifyListeners();

      NotificationSyncService.instance.push(
        role: 'dosen',
        icon: 'clipboard',
        title: 'Rekomendasi Sanggahan dari Asisten',
        body:
            '$decidedBy meninjau sanggahan ${appeal.userName} ($compLabel): ${approve ? 'rekomendasi setujui ($finalScore)' : 'rekomendasi tolak'}. Menunggu keputusan akhir Anda.',
        targetKey: 'validasi',
        courseId: appeal.courseId,
        meetingNumber: appeal.modul,
        important: true,
      );
    } else {
      // Dosen membuat keputusan akhir yang mengubah nilai resmi & mencatat log perubahan
      appeal.status = approve ? 'approved' : 'rejected';
      notifyListeners();

      if (approve) {
        await PraktikumSyncService.instance.gradeTugasSubmission(
          courseId: appeal.courseId,
          meetingNumber: appeal.modul,
          userIdentifier: appeal.userIdentifier,
          userName: appeal.userName,
          score: finalScore,
          feedback: 'Nilai diperbarui melalui keputusan sanggahan oleh $decidedBy',
        );
      }

      NotificationSyncService.instance.push(
        role: 'praktikan',
        icon: approve ? 'circle_check' : 'info',
        title:
            approve ? 'Sanggahan Nilai Disetujui' : 'Sanggahan Nilai Ditolak',
        body: approve
            ? 'Nilai $compLabel diperbarui menjadi $finalScore oleh $decidedBy.'
            : 'Sanggahan $compLabel ditolak oleh $decidedBy.${cleanReason.isNotEmpty ? ' Alasan: $cleanReason' : ''}',
        targetKey: 'detailNilai',
        courseId: appeal.courseId,
        meetingNumber: appeal.modul,
        important: true,
      );

      NotificationSyncService.instance.push(
        role: 'aslab',
        icon: 'circle_check',
        title: 'Keputusan Akhir Sanggahan oleh Dosen',
        body:
            '${appeal.userName} ($compLabel): ${approve ? 'Disetujui ($finalScore)' : 'Ditolak'} oleh $decidedBy.',
        targetKey: 'evaluasi',
        courseId: appeal.courseId,
        meetingNumber: appeal.modul,
        important: true,
      );
    }

    final client = SupabaseService.instance.client;
    if (client != null) {
      final nowIso = DateTime.now().toIso8601String();
      try {
        await client
            .from('grade_appeals')
            .update({
              'status': appeal.status,
              'proposed_score': finalScore,
              'assistant_recommendation': appeal.assistantRecommendation,
              if (cleanReason.isNotEmpty) 'rejection_reason': cleanReason,
              if (byDosen) 'decided_by': decidedBy,
              'updated_at': nowIso,
            })
            .eq('course_id', appeal.courseId)
            .eq('modul', appeal.modul)
            .eq('user_identifier', appeal.userIdentifier);

        if (byDosen && approve) {
          await client.from('grade_change_logs').insert({
            'course_id': appeal.courseId,
            'modul': appeal.modul,
            'user_identifier': appeal.userIdentifier,
            'user_name': appeal.userName,
            'old_score': oldScore,
            'new_score': finalScore,
            'changed_by': decidedBy,
            'reason': 'Keputusan akhir sanggahan nilai disetujui ($compLabel)',
            'created_at': nowIso,
          });
        }
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[NilaiSync] decideAppeal error: $e');
      }
    }
  }

  /// Ajukan ulang rekap nilai dari Aslab ke Dosen setelah revisi selesai.
  Future<void> resubmitValidation(String courseId,
      {required String submittedBy}) async {
    final now = DateTime.now();
    final rec = validationFor(courseId);
    rec.status = 'pending';
    rec.updatedAt = now;
    _validations[courseId] = rec;
    notifyListeners();

    final course = PraktikumSyncService.instance.courseById(courseId);
    NotificationSyncService.instance.push(
      role: 'dosen',
      icon: 'shield_check_outline',
      title: 'Rekap Nilai Diajukan Ulang',
      body:
          'Praktikum ${course.name} • diajukan ulang oleh $submittedBy untuk validasi.',
      targetKey: 'validasi',
      important: true,
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('grade_validations').upsert(
          {
            'course_id': courseId,
            'status': 'pending',
            'validated_by': submittedBy,
            'updated_at': now.toIso8601String(),
          },
          onConflict: 'course_id',
        );
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[NilaiSync] resubmitValidation error: $e');
      }
    }
  }

  /// Tandai arahan tindak lanjut dari Dosen sudah ditindaklanjuti oleh Aslab.
  Future<void> markFollowUpDone(String id, {required String byAslab}) async {
    AssistantFollowUpRecord? target;
    for (final f in _followUps) {
      if (f.id == id) {
        f.status = 'done';
        target = f;
        break;
      }
    }
    if (target == null) return;

    NotificationSyncService.instance.push(
      role: 'dosen',
      icon: 'circle_check',
      title: 'Arahan Ditindaklanjuti',
      body: '$byAslab menindaklanjuti arahan untuk ${target.studentName}.',
      targetKey: 'peringatan',
      important: false,
    );
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        if (!target.id.startsWith('local-') && !target.id.startsWith('fu-seed-')) {
          await client
              .from('assistant_followups')
              .update({'status': 'done'})
              .eq('id', target.id);
        } else {
          await client
              .from('assistant_followups')
              .update({'status': 'done'})
              .eq('student_nim', target.studentNim)
              .eq('message', target.message);
        }
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[NilaiSync] markFollowUpDone error: $e');
      }
    }
  }

  void _seedDefaults() {
    _validations
      ..clear()
      ..addAll({
        'pemob': GradeValidationRecord(
          courseId: 'pemob',
          status: 'revision_requested',
          revisionPart: 'Modul 3',
          revisionNote:
              'Tolong cek ulang nilai Modul 3. Ada 3 praktikan bernilai 0 padahal sudah mengumpulkan.',
        ),
        'desain': GradeValidationRecord(courseId: 'desain', status: 'pending'),
        'adj': GradeValidationRecord(courseId: 'adj', status: 'validated'),
        'ml': GradeValidationRecord(courseId: 'ml', status: 'validated'),
      });

    if (_appeals.isEmpty) {
      _appeals.addAll([
        GradeAppealRecord(
          id: 'app-seed-1',
          courseId: 'pemob',
          modul: 3,
          userIdentifier: '231402045',
          userName: 'Rina Novita',
          components: const ['Tugas 3'],
          reason:
              'Fitur login dan validasi form sudah sesuai rubrik poin 2 dan 3. Mohon dicek ulang.',
          attachmentName: 'bukti_tugas3.pdf',
          currentScore: 70,
          proposedScore: 85,
          assistantRecommendation:
              'Rekomendasi Asisten (Abbil Rizki): setujui, rubrik poin 2 sudah terpenuhi.',
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        GradeAppealRecord(
          id: 'app-seed-2',
          courseId: 'pemob',
          modul: 4,
          userIdentifier: '231402052',
          userName: 'Dimas Saputra',
          components: const ['Kuis Modul 4'],
          reason:
              'Soal nomor 7 punya dua jawaban benar menurut modul halaman 12.',
          attachmentName: 'screenshot_soal7.png',
          currentScore: 60,
          proposedScore: 75,
          assistantRecommendation:
              'Rekomendasi Asisten (Abbil Rizki): perlu peninjauan kunci soal nomor 7.',
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ]);
    }

    if (_followUps.isEmpty) {
      _followUps.addAll([
        AssistantFollowUpRecord(
          id: 'fu-seed-1',
          studentNim: '231402067',
          studentName: 'Yoga Siregar',
          assistantName: 'Abbil Rizki',
          followUpType: 'Kehadiran',
          message:
              'Mohon bantu ingatkan Yoga soal kehadiran dan jadwalkan konsultasi sebelum Pertemuan 6.',
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        AssistantFollowUpRecord(
          id: 'fu-seed-2',
          studentNim: '231402067',
          studentName: 'Yoga Siregar',
          assistantName: 'Feri Gunawan',
          followUpType: 'Remedial',
          message: 'Berikan tugas remedial Modul 2 sebelum pertemuan berikutnya.',
          status: 'done',
          createdAt: DateTime.now().subtract(const Duration(days: 6)),
        ),
      ]);
    }
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

      try {
        final followRows = await client
            .from('assistant_followups')
            .select()
            .order('created_at', ascending: false)
            .limit(50);
        if (followRows.isNotEmpty) {
          _followUps
            ..clear()
            ..addAll(followRows.map((r) =>
                AssistantFollowUpRecord.fromJson(Map<String, dynamic>.from(r))));
        }
      } catch (e) {
        debugPrint('[NilaiSync] Load assistant_followups dilewati: $e');
      }

      try {
        final dlRows = await client
            .from('report_downloads')
            .select()
            .order('created_at', ascending: false)
            .limit(50);
        if (dlRows.isNotEmpty) {
          _reportDownloads
            ..clear()
            ..addAll(dlRows.map((r) =>
                ReportDownloadRecord.fromJson(Map<String, dynamic>.from(r))));
        }
      } catch (e) {
        debugPrint('[NilaiSync] Load report_downloads dilewati: $e');
      }

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
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'assistant_followups',
            callback: (_) => refreshFromBackend(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'report_downloads',
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
    int currentScore = 70,
    int proposedScore = 85,
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
      currentScore: currentScore,
      proposedScore: proposedScore,
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
          'current_score': currentScore,
          'proposed_score': proposedScore,
          'status': 'pending',
          'created_at': now.toIso8601String(),
        });
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[NilaiSync] submitGradeAppeal error: $e');
      }
    }
  }

  Future<AssistantFollowUpRecord> sendAssistantFollowUp({
    required String studentNim,
    required String studentName,
    required String assistantName,
    required String followUpType,
    required String message,
  }) async {
    final now = DateTime.now();
    final rec = AssistantFollowUpRecord(
      id: 'local-fu-${now.millisecondsSinceEpoch}',
      studentNim: studentNim,
      studentName: studentName,
      assistantName: assistantName,
      followUpType: followUpType,
      message: message,
      createdAt: now,
    );
    _followUps.insert(0, rec);
    notifyListeners();

    final isAttendance = followUpType.toLowerCase().contains('hadir');
    NotificationSyncService.instance.push(
      role: 'aslab',
      icon: 'chat_bubble',
      title: 'Tindak Lanjut Dosen: $followUpType',
      body: 'Untuk $studentName ($studentNim) • ke $assistantName: $message',
      targetKey: isAttendance ? 'detailPresensi' : 'evaluasi',
      important: true,
    );
    NotificationSyncService.instance.push(
      role: 'praktikan',
      icon: 'chat_bubble',
      title: 'Arahan Dosen: $followUpType',
      body: 'Koordinasi dengan $assistantName: $message',
      targetKey: isAttendance ? 'detailAbsensi' : 'detailNilai',
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
          'status': 'pending',
          'created_at': now.toIso8601String(),
        });
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[NilaiSync] sendAssistantFollowUp error: $e');
      }
    }
    return rec;
  }
}
