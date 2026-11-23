import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/aslab/aslab_store.dart';
import '../../features/praktikan/praktikan_store.dart';
import 'notification_sync_service.dart';
import 'supabase_service.dart';

/// Data pengumpulan tugas praktikan yang tersinkron ke Supabase & Aslab.
class TugasSubmissionRecord {
  final String courseId;
  final int meetingNumber;
  final String userIdentifier;
  final String userName;
  final List<PrakFile> files;
  final String repoUrl;
  final String note;

  /// 'submitted' | 'graded' | 'cancelled'
  final String status;
  final int? score;
  final String? feedback;
  final DateTime updatedAt;

  const TugasSubmissionRecord({
    required this.courseId,
    required this.meetingNumber,
    required this.userIdentifier,
    required this.userName,
    required this.files,
    required this.repoUrl,
    required this.note,
    this.status = 'submitted',
    this.score,
    this.feedback,
    required this.updatedAt,
  });

  bool get isSubmitted => status == 'submitted' || status == 'graded';

  factory TugasSubmissionRecord.fromJson(Map<String, dynamic> json) {
    final rawFiles = (json['files_json'] as List?) ?? const [];
    final files = <PrakFile>[];
    for (final f in rawFiles) {
      if (f is Map) {
        files.add(PrakFile(
          (f['name'] ?? 'Berkas Tugas').toString(),
          (f['meta'] ?? 'Diunggah').toString(),
        ));
      }
    }
    return TugasSubmissionRecord(
      courseId: (json['course_id'] ?? 'pemob').toString(),
      meetingNumber: (json['meeting_number'] as num?)?.toInt() ?? 4,
      userIdentifier: (json['user_identifier'] ?? '').toString(),
      userName: (json['user_name'] ?? 'Praktikan').toString(),
      files: files,
      repoUrl: (json['repo_url'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      status: (json['status'] ?? 'submitted').toString(),
      score: (json['score'] as num?)?.toInt(),
      feedback: json['feedback'] as String?,
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Hasil pengerjaan Kuis Pre-Test oleh praktikan (tersinkron ke Supabase).
class KuisAttemptRecord {
  final String courseId;
  final int meetingNumber;
  final String userIdentifier;
  final String userName;
  final Map<int, int> answers;
  final int score;
  final int correctCount;
  final int wrongCount;
  final int durationSeconds;
  final DateTime submittedAt;

  const KuisAttemptRecord({
    required this.courseId,
    required this.meetingNumber,
    required this.userIdentifier,
    required this.userName,
    required this.answers,
    required this.score,
    required this.correctCount,
    required this.wrongCount,
    required this.durationSeconds,
    required this.submittedAt,
  });

  factory KuisAttemptRecord.fromJson(Map<String, dynamic> json) {
    final rawAns = json['answers_json'];
    final map = <int, int>{};
    if (rawAns is Map) {
      rawAns.forEach((k, v) {
        final ik = int.tryParse(k.toString());
        final iv = (v as num?)?.toInt();
        if (ik != null && iv != null) map[ik] = iv;
      });
    }
    return KuisAttemptRecord(
      courseId: (json['course_id'] ?? 'pemob').toString(),
      meetingNumber: (json['meeting_number'] as num?)?.toInt() ?? 4,
      userIdentifier: (json['user_identifier'] ?? '').toString(),
      userName: (json['user_name'] ?? 'Praktikan').toString(),
      answers: map,
      score: (json['score'] as num?)?.toInt() ?? 0,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      wrongCount: (json['wrong_count'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      submittedAt: json['submitted_at'] != null
          ? (DateTime.tryParse(json['submitted_at'].toString()) ??
              DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Penilaian kinerja asisten oleh praktikan (tersinkron ke Supabase).
class AsistenRatingRecord {
  final String courseId;
  final String asistenName;
  final String userIdentifier;
  final List<int> ratings; // [materi, penjelasan, waktu, kesigapan]
  final String comment;
  final DateTime createdAt;

  const AsistenRatingRecord({
    required this.courseId,
    required this.asistenName,
    required this.userIdentifier,
    required this.ratings,
    required this.comment,
    required this.createdAt,
  });

  double get average {
    if (ratings.isEmpty) return 0;
    final sum = ratings.fold<int>(0, (a, b) => a + b);
    return sum / ratings.length;
  }

  String get averageLabel => average.toStringAsFixed(1).replaceAll('.', ',');

  factory AsistenRatingRecord.fromJson(Map<String, dynamic> json) {
    return AsistenRatingRecord(
      courseId: (json['course_id'] ?? 'pemob').toString(),
      asistenName: (json['asisten_name'] ?? 'Asisten Lab').toString(),
      userIdentifier: (json['user_identifier'] ?? '').toString(),
      ratings: [
        ((json['rating_materi'] as num?)?.toInt() ?? 5).clamp(1, 5),
        ((json['rating_penjelasan'] as num?)?.toInt() ?? 4).clamp(1, 5),
        ((json['rating_waktu'] as num?)?.toInt() ?? 5).clamp(1, 5),
        ((json['rating_kesigapan'] as num?)?.toInt() ?? 4).clamp(1, 5),
      ],
      comment: (json['comment'] ?? '').toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Service backend & sinkronisasi real-time untuk fitur Praktikum (4 mata
/// kuliah Semester Ganjil 2026/2027: Pemrograman Mobile, Desain Interaksi,
/// Analisis Desain Jaringan, dan Machine Learning) antar Praktikan & Aslab.
class PraktikumSyncService extends ChangeNotifier {
  static final PraktikumSyncService instance = PraktikumSyncService._internal();
  PraktikumSyncService._internal() {
    _seedDefaults();
  }

  final List<PrakCourse> _courses = [];
  final Map<String, TugasSubmissionRecord> _submissions = {};
  final Map<String, KuisAttemptRecord> _quizAttempts = {};
  final Map<String, List<int>> _ratingsByCourse = {};
  final Map<String, AsistenRatingRecord> _ratingRecords = {};
  final Map<String, List<PrakQuestion>> _customQuestionsByCourse = {};

  RealtimeChannel? _channel;
  bool _initialized = false;
  bool _backendAvailable = false;
  bool get isBackendAvailable => _backendAvailable;

  List<PrakCourse> get courses => List.unmodifiable(_courses);

  List<KuisAttemptRecord> get allQuizAttempts =>
      List.unmodifiable(_quizAttempts.values.toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt)));

  List<TugasSubmissionRecord> get allSubmissions =>
      List.unmodifiable(_submissions.values
          .where((s) => s.isSubmitted)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)));

  /// Daftar nilai efektif praktikan per mata kuliah (menggabungkan nilai
  /// terbaru dari Aslab untuk semua modul 1..4 termasuk hasil revisi sanggahan).
  List<PrakGrade> effectiveGradesForCourse(
      PrakCourse course, String userIdentifier) {
    return [
      for (final g in course.grades)
        () {
          final sub = submissionFor(course.id, g.modul, userIdentifier);
          if (sub != null && sub.status == 'graded' && sub.score != null) {
            return PrakGrade(
              modul: g.modul,
              title: g.title,
              date: g.date,
              score: '${sub.score}',
              note: (sub.feedback != null && sub.feedback!.isNotEmpty)
                  ? sub.feedback
                  : (g.note ?? 'Penilaian telah diperbarui oleh asisten.'),
              components: g.components,
            );
          }
          return g;
        }(),
    ];
  }

  /// Nilai rata-rata efektif (termasuk nilai baru dari Aslab jika ada).
  String effectiveAverageForCourse(PrakCourse course, String userIdentifier) {
    final grades = effectiveGradesForCourse(course, userIdentifier);
    final nums = <double>[];
    for (final g in grades) {
      if (g.score != null) {
        final v = double.tryParse(g.score!.replaceAll(',', '.'));
        if (v != null) nums.add(v);
      }
    }
    if (nums.isEmpty) return course.nilaiRata;
    final avg = nums.reduce((a, b) => a + b) / nums.length;
    return avg.toStringAsFixed(1).replaceAll('.', ',');
  }

  /// Konversi 4 praktikum sinkron ke model [AslabCourse] agar halaman
  /// Praktikum Saya & Absensi milik Aslab memakai sumber data yang sama.
  List<AslabCourse> get aslabCourses {
    return [
      for (final c in _courses)
        () {
          final sortedMeetings = List<PrakMeeting>.from(c.meetings)
            ..sort((a, b) => b.number.compareTo(a.number));
          final activeMeetings = sortedMeetings
              .where((m) =>
                  m.materiTitle.isNotEmpty ||
                  m.tugasTitle.isNotEmpty ||
                  m.kuisTitle.isNotEmpty)
              .toList();
          return AslabCourse(
            id: c.id,
            name: c.name,
            kelas: c.kelas,
            room: c.room,
            jadwal: c.jadwalDaftar,
            rataHadir:
                '${((c.hadir / (c.hadir + c.izin + c.alpa == 0 ? 4 : c.hadir + c.izin + c.alpa)) * 100).round()}%',
            meetings: [
              for (final m in activeMeetings)
                AslabMeeting(
                  m.number,
                  m.date.split(' • ').first,
                  'Pertemuan ${m.number} :\n${m.module.split(' • ').last}',
                  [
                    if (m.materiTitle.isNotEmpty)
                      AslabItem(
                        0,
                        m.materiTitle,
                        '${m.materiFile.isNotEmpty ? m.materiFile : 'PDF • 3,2 MB'} • dilihat 21 / 24',
                      ),
                    if (m.tugasTitle.isNotEmpty)
                      AslabItem(
                        1,
                        m.tugasTitle,
                        '${m.tugasDeadline.isNotEmpty ? m.tugasDeadline : c.tugasDeadline} • ${(20 + submissionsForCourse(c.id, m.number).length).clamp(0, 24)} / 24 terkumpul',
                      ),
                    if (m.kuisTitle.isNotEmpty)
                      AslabItem(
                        2,
                        m.kuisTitle,
                        '${questionsForCourse(c.id).length} soal • 10 menit • ${(22 + _quizAttempts.values.where((q) => q.courseId == c.id && q.meetingNumber == m.number).length).clamp(0, 24)} / 24 mengerjakan',
                      ),
                  ],
                ),
            ],
            sessions: [
              for (final m in sortedMeetings)
                AslabSession(
                  m.number,
                  m.module,
                  m.date,
                  m.number == 5 ? 0 : (m.number > 5 ? 1 : 2),
                  hadir: m.number < 5 ? 21 : 0,
                  izin: m.number < 5 ? 2 : 0,
                  alpa: m.number < 5 ? 1 : 0,
                ),
            ],
          );
        }(),
    ];
  }

  /// Cari pertemuan tertentu di sebuah praktikum.
  PrakMeeting? meetingFor(String courseId, int meetingNumber) {
    final c = courseById(courseId);
    for (final m in c.meetings) {
      if (m.number == meetingNumber) return m;
    }
    return null;
  }

  /// Simpan nilai & feedback dari Aslab (Penilaian Tugas) ke Supabase dan
  /// sinkronkan langsung ke sisi Praktikan & Dosen.
  Future<void> gradeTugasSubmission({
    required String courseId,
    required int meetingNumber,
    required String userIdentifier,
    required String userName,
    required int score,
    required String feedback,
  }) async {
    final now = DateTime.now();
    final key = _subKey(courseId, meetingNumber, userIdentifier);
    final old = _submissions[key];
    _submissions[key] = TugasSubmissionRecord(
      courseId: courseId,
      meetingNumber: meetingNumber,
      userIdentifier: userIdentifier,
      userName: userName,
      files: old?.files ?? const [PrakFile('laporan_tugas.pdf', 'PDF • 1,2 MB')],
      repoUrl: old?.repoUrl ?? '',
      note: old?.note ?? '',
      status: 'graded',
      score: score,
      feedback: feedback,
      updatedAt: now,
    );
    notifyListeners();

    final cName = courseById(courseId).name;
    NotificationSyncService.instance.push(
      role: 'praktikan',
      icon: 'trophy',
      title: 'Nilai Modul $meetingNumber Tersedia',
      body: 'Praktikum $cName: nilai anda $score / 100 telah dipublikasikan',
      targetKey: 'detailNilai',
      important: true,
    );
    NotificationSyncService.instance.push(
      role: 'dosen',
      icon: 'circle_check',
      title: 'Penilaian Modul $meetingNumber Diperbarui',
      body: '$userName ($cName) dinilai $score / 100 oleh asisten',
      targetKey: 'validasi',
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('tugas_submissions').upsert(
          {
            'course_id': courseId,
            'meeting_number': meetingNumber,
            'user_identifier': userIdentifier,
            'user_name': userName,
            'status': 'graded',
            'score': score,
            'feedback': feedback,
            'updated_at': now.toIso8601String(),
          },
          onConflict: 'course_id,meeting_number,user_identifier',
        );
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[PraktikumSync] gradeTugasSubmission error: $e');
      }
    }
  }

  PrakCourse courseById(String id) {
    return _courses.firstWhere(
      (c) => c.id == id,
      orElse: () => _courses.first,
    );
  }

  String _subKey(String courseId, int meetingNumber, String userId) =>
      '$courseId:$meetingNumber:$userId';

  TugasSubmissionRecord? submissionFor(
      String courseId, int meetingNumber, String userId) {
    return _submissions[_subKey(courseId, meetingNumber, userId)];
  }

  List<TugasSubmissionRecord> submissionsForCourse(
      String courseId, int meetingNumber) {
    return _submissions.values
        .where((s) =>
            s.courseId == courseId &&
            s.meetingNumber == meetingNumber &&
            s.isSubmitted)
        .toList();
  }

  KuisAttemptRecord? quizAttemptFor(
      String courseId, int meetingNumber, String userId) {
    return _quizAttempts[_subKey(courseId, meetingNumber, userId)];
  }

  List<int> ratingsForCourse(String courseId) {
    return _ratingsByCourse[courseId] ?? [5, 4, 5, 4];
  }

  String _ratingKey(String courseId, String userIdentifier) =>
      '$courseId:$userIdentifier';

  AsistenRatingRecord? ratingFor(String courseId, String userIdentifier) {
    return _ratingRecords[_ratingKey(courseId, userIdentifier)];
  }

  List<AsistenRatingRecord> allRatingsForCourse(String courseId) {
    return _ratingRecords.values
        .where((r) => r.courseId == courseId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int ratingCountForCourse(String courseId) =>
      allRatingsForCourse(courseId).length;

  double averageRatingForCourse(String courseId) {
    final list = allRatingsForCourse(courseId);
    if (list.isEmpty) return 0;
    final sum = list.fold<double>(0, (acc, r) => acc + r.average);
    return sum / list.length;
  }

  String averageRatingLabelForCourse(String courseId) {
    final avg = averageRatingForCourse(courseId);
    if (avg <= 0) return '4,8';
    return avg.toStringAsFixed(1).replaceAll('.', ',');
  }

  /// Rata-rata penilaian seluruh praktikum yang diterima asisten.
  String overallAsistenRatingLabel() {
    if (_ratingRecords.isEmpty) return '4,8';
    final sum = _ratingRecords.values
        .fold<double>(0, (acc, r) => acc + r.average);
    return (sum / _ratingRecords.length).toStringAsFixed(1).replaceAll('.', ',');
  }

  /// Jumlah item yang belum selesai pada pertemuan aktif (Tugas + Kuis).
  int pendingItemsCount(String courseId, int meetingNumber, String userId) {
    if (meetingNumber < 4) return 0;
    var pending = 0;
    final sub = submissionFor(courseId, meetingNumber, userId);
    if (sub == null || !sub.isSubmitted) pending++;
    final attempt = quizAttemptFor(courseId, meetingNumber, userId);
    if (attempt == null) pending++;
    return pending;
  }

  /// Soal kuis spesifik untuk masing-masing dari 4 praktikum (termasuk soal
  /// baru yang diterbitkan Aslab).
  List<PrakQuestion> questionsForCourse(String courseId) {
    final custom = _customQuestionsByCourse[courseId];
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    switch (courseId) {
      case 'desain':
        return const [
          PrakQuestion(
            'Fitur Figma yang memungkinkan elemen menyesuaikan ukuran secara dinamis saat kontennya berubah adalah...',
            ['Constraints', 'Auto Layout', 'Slice Tool', 'Masking'],
            1,
          ),
          PrakQuestion(
            'Kumpulan variasi dari satu komponen utama (misalnya state Default, Hover, Disabled) disebut...',
            ['Variants', 'Styles', 'Frames', 'Sections'],
            0,
          ),
          PrakQuestion(
            'Untuk menjaga konsistensi warna dan tipografi di seluruh desain, desainer menggunakan...',
            ['Design Tokens / Styles', 'Export PNG', 'Rasterize', 'Flatten'],
            0,
          ),
          PrakQuestion(
            'Transisi animasi halus antar dua frame dengan nama layer yang sama di Figma disebut...',
            ['Instant', 'Dissolve', 'Smart Animate', 'Move Out'],
            2,
          ),
          PrakQuestion(
            'Salinan komponen utama yang tetap mengikuti perubahan master component disebut...',
            ['Group', 'Instance', 'Vector', 'Boolean'],
            1,
          ),
          PrakQuestion(
            'Perbedaan utama Frame dan Group di Figma adalah...',
            [
              'Frame mendukung layout grid, clipping, dan constraints',
              'Group memiliki background warna sendiri',
              'Frame tidak bisa diberi Auto Layout',
              'Group hanya untuk teks',
            ],
            0,
          ),
          PrakQuestion(
            'Tahapan sketsa struktur tata letak tanpa warna/detail visual tinggi disebut...',
            ['High-Fidelity', 'Wireframing', 'Usability Test', 'Handoff'],
            1,
          ),
          PrakQuestion(
            'Shortcut untuk membuat Auto Layout pada layer terpilih di Figma adalah...',
            ['Ctrl + G', 'Shift + A', 'Alt + D', 'Ctrl + K'],
            1,
          ),
          PrakQuestion(
            'Prinsip desain yang memastikan elemen paling penting langsung menarik perhatian pengguna adalah...',
            ['Visual Hierarchy', 'Lorem Ipsum', 'Pixelation', 'Clipping'],
            0,
          ),
          PrakQuestion(
            'Fitur untuk membagikan spesifikasi CSS/spacing dari Figma kepada developer disebut...',
            ['Dev Mode / Inspect', 'FigJam', 'Outline View', 'Comments'],
            0,
          ),
        ];
      case 'adj':
        return const [
          PrakQuestion(
            'Standar IEEE yang digunakan untuk VLAN tagging pada link trunk antar switch adalah...',
            ['IEEE 802.11', 'IEEE 802.1Q', 'IEEE 802.3af', 'IEEE 802.15'],
            1,
          ),
          PrakQuestion(
            'Tujuan utama pemisahan jaringan menggunakan VLAN pada switch adalah...',
            [
              'Memperbesar broadcast domain',
              'Memisahkan broadcast domain secara logis',
              'Menghapus kebutuhan alamat IP',
              'Mengganti kabel fiber optik',
            ],
            1,
          ),
          PrakQuestion(
            'Metode menghubungkan beberapa VLAN melalui satu interface fisik router dengan sub-interface disebut...',
            ['Port Security', 'Router-on-a-Stick', 'Spanning Tree', 'NAT Overload'],
            1,
          ),
          PrakQuestion(
            'Prefix /26 pada IPv4 menyediakan jumlah host usable sebanyak...',
            ['30 host', '62 host', '126 host', '254 host'],
            1,
          ),
          PrakQuestion(
            'Protokol yang mencegah terjadinya switching loop pada jaringan Layer 2 adalah...',
            ['OSPF', 'DHCP', 'STP (Spanning Tree Protocol)', 'ARP'],
            2,
          ),
          PrakQuestion(
            'Perangkat jaringan yang bekerja pada Layer 3 (Network Layer) model OSI adalah...',
            ['Hub', 'Repeater', 'Router', 'Bridge'],
            2,
          ),
          PrakQuestion(
            'Keunggulan utama teknik VLSM dibandingkan subnetting ukuran tetap adalah...',
            [
              'Efisiensi pemakaian alamat IP sesuai kebutuhan tiap subnet',
              'Tidak memerlukan subnet mask',
              'Hanya bekerja pada kelas A',
              'Menghilangkan default gateway',
            ],
            0,
          ),
          PrakQuestion(
            'Perintah Cisco IOS untuk melihat daftar VLAN yang aktif pada switch adalah...',
            ['show ip route', 'show vlan brief', 'show arp', 'show version'],
            1,
          ),
          PrakQuestion(
            'Port switch yang dihubungkan langsung ke PC praktikan dikonfigurasi dalam mode...',
            ['Trunk', 'Access', 'Dynamic Auto', 'Loopback'],
            1,
          ),
          PrakQuestion(
            'Tools yang umum digunakan untuk menangkap dan menganalisis paket trafik jaringan secara mendalam adalah...',
            ['Wireshark', 'Figma', 'Blender', 'Audacity'],
            0,
          ),
        ];
      case 'ml':
        return const [
          PrakQuestion(
            'Jenis pembelajaran mesin yang dilatih menggunakan data berlabel (input dan target diketahui) disebut...',
            ['Unsupervised Learning', 'Supervised Learning', 'Reinforcement Only', 'Clustering'],
            1,
          ),
          PrakQuestion(
            'Algoritma ensemble yang menggabungkan banyak Decision Tree untuk meningkatkan akurasi dan mengurangi overfitting adalah...',
            ['K-Means', 'Random Forest', 'PCA', 'DBSCAN'],
            1,
          ),
          PrakQuestion(
            'Kondisi ketika model sangat akurat pada data latih tetapi buruk pada data uji disebut...',
            ['Underfitting', 'Overfitting', 'Normalization', 'Tokenization'],
            1,
          ),
          PrakQuestion(
            'Metrik yang merangkum True Positive, False Positive, True Negative, dan False Negative adalah...',
            ['Elbow Curve', 'Confusion Matrix', 'Learning Rate', 'Dendrogram'],
            1,
          ),
          PrakQuestion(
            'Library Python yang paling umum digunakan untuk algoritma klasifikasi & regresi klasik adalah...',
            ['scikit-learn', 'Flask', 'PyGame', 'BeautifulSoup'],
            0,
          ),
          PrakQuestion(
            'Fungsi train_test_split() digunakan untuk...',
            [
              'Menghapus seluruh kolom numerik',
              'Membagi dataset menjadi data latih dan data uji',
              'Memvisualisasikan grafik batang',
              'Menyimpan model ke PDF',
            ],
            1,
          ),
          PrakQuestion(
            'Teknik mengubah fitur kategorikal menjadi kolom biner (0/1) disebut...',
            ['One-Hot Encoding', 'Gradient Descent', 'Dropout', 'Pruning'],
            0,
          ),
          PrakQuestion(
            'Pada Decision Tree, kriteria yang umum dipakai untuk mengukur kemurnian split adalah...',
            ['Gini Impurity / Entropy', 'Euclidean Mean', 'Cosine Only', 'Batch Size'],
            0,
          ),
          PrakQuestion(
            'Metrik evaluasi yang merupakan rata-rata harmonik dari Precision dan Recall adalah...',
            ['R-Squared', 'MSE', 'F1-Score', 'Variance'],
            2,
          ),
          PrakQuestion(
            'Tahapan menangani missing values dan scaling fitur sebelum melatih model termasuk proses...',
            ['Data Preprocessing', 'Deployment', 'Hyperparameter Only', 'Inference'],
            0,
          ),
        ];
      default:
        return const [
          PrakQuestion(
            'Fitur Flutter yang menampilkan perubahan kode tanpa menghilangkan state aplikasi adalah...',
            ['Hot Restart', 'Flutter Doctor', 'Hot Reload', 'Build Runner'],
            2,
          ),
          PrakQuestion(
            'Method yang dipanggil untuk memberi tahu framework bahwa nilai state berubah adalah...',
            ['setState()', 'initState()', 'dispose()', 'build()'],
            0,
          ),
          PrakQuestion(
            'Widget manakah yang digunakan untuk membangun ulang tampilan ketika nilai state berubah?',
            ['StatelessWidget', 'StatefulWidget', 'InheritedWidget', 'Container'],
            1,
          ),
          PrakQuestion(
            'Package state management yang direkomendasikan tim Flutter untuk berbagi state antar-widget adalah...',
            ['GetX', 'Provider', 'Redux', 'MobX'],
            1,
          ),
          PrakQuestion(
            'Method yang dipanggil sekali saat State pertama kali dibuat adalah...',
            ['build()', 'didUpdateWidget()', 'initState()', 'deactivate()'],
            2,
          ),
          PrakQuestion(
            'Kelas pada Provider yang memberi tahu listener ketika data berubah adalah...',
            ['ChangeNotifier', 'StreamBuilder', 'FutureBuilder', 'BuildContext'],
            0,
          ),
          PrakQuestion(
            'Method ChangeNotifier untuk memperbarui widget yang mendengarkan adalah...',
            ['refresh()', 'notifyListeners()', 'setState()', 'update()'],
            1,
          ),
          PrakQuestion(
            'Widget yang membaca nilai Provider dan membangun ulang hanya bagiannya sendiri adalah...',
            ['Builder', 'Consumer', 'Container', 'Scaffold'],
            1,
          ),
          PrakQuestion(
            'State yang hanya dipakai oleh satu widget disebut...',
            ['App state', 'Global state', 'Ephemeral state', 'Shared state'],
            2,
          ),
          PrakQuestion(
            'Method untuk membersihkan controller saat widget dihapus dari tree adalah...',
            ['dispose()', 'reassemble()', 'initState()', 'build()'],
            0,
          ),
        ];
    }
  }

  void _seedDefaults() {
    _courses
      ..clear()
      ..addAll([
        PrakCourse(
          id: 'pemob',
          name: 'Pemrograman Mobile',
          asisten: 'Andi Pratama',
          asistenInitials: 'AP',
          kelas: 'TIF 3001 - Kom C (C1 & C2)',
          room: 'Lab Komputer 1',
          jadwalDaftar: 'Sen • C1 08:00 | C2 10:00',
          jadwalDetail: 'Sen, C1 08:00–09:40 • C2 10:00–11:40',
          jadwalAbsensi: 'Sen, C1 08:00–09:40 | C2 10:00–11:40',
          jam: 'C1 08:00–09:40 • C2 10:00–11:40 WIB',
          modulTitle: 'State Management',
          modulDesc:
              'Pembahasan State Management Flutter secara mendalam: setState, ChangeNotifier, dan Provider.',
          materiTitle: 'Panduan State Management Flutter',
          materiFile: 'Panduan_State_Management_Flutter.pdf',
          tugasTitle: 'Tugas 4 : Implementasi State Management',
          tugasDeadline: 'Batas 10:30 WIB, 29 Sep 2026',
          preTest: 'Pre-Test Modul 4 : State Management',
          postTest: 'Post-Test Modul 4 : State Management',
          hadir: 3,
          izin: 1,
          alpa: 0,
          meetings: [
            PrakMeeting(
              number: 5,
              module: 'Modul 5 • Navigasi & Routing',
              date: 'Sen, 05 Okt 2026 • 08:00–09:40 WIB',
              status: PrakAttend.upcoming,
            ),
            PrakMeeting(
              number: 4,
              module: 'Modul 4 • State Management',
              date: 'Sen, 28 Sep 2026 • 08:00–09:40 WIB',
              status: PrakAttend.hadir,
              noteIcon: 'qrcode',
              note: 'Tercatat 08:03 WIB melalui pindai QR',
            ),
            PrakMeeting(
              number: 3,
              module: 'Modul 3 • Layout & Navigasi',
              date: 'Sen, 21 Sep 2026 • 08:00–09:40 WIB',
              status: PrakAttend.hadir,
              noteIcon: 'location',
              note: 'Tercatat 08:01 WIB melalui tombol hadir & lokasi',
            ),
            PrakMeeting(
              number: 2,
              module: 'Modul 2 • Widget Dasar',
              date: 'Sen, 14 Sep 2026 • 08:00–09:40 WIB',
              status: PrakAttend.izin,
              izinFile: 'surat_dokter.pdf',
            ),
            PrakMeeting(
              number: 1,
              module: 'Modul 1 • Pengenalan Flutter',
              date: 'Sen, 07 Sep 2026 • 08:00–09:40 WIB',
              status: PrakAttend.hadir,
              noteIcon: 'qrcode',
              note: 'Tercatat 07:58 WIB melalui pindai QR',
            ),
          ],
          nilaiRata: '88,3',
          akumulasi: '265 / 300',
          grades: const [
            PrakGrade(
              modul: 4,
              title: 'Flutter State Management',
              date: 'Sen, 28 September 2026',
            ),
            PrakGrade(
              modul: 3,
              title: 'Layout & Navigasi',
              date: 'Sen, 21 September 2026',
              score: '88',
              note:
                  'Struktur widget sudah rapi dan navigasi berjalan baik. Perbaiki penamaan route dan tambahkan validasi form pada halaman login.',
              components: [
                ('Kebenaran Program', '38', '40'),
                ('Tampilan & Navigasi', '35', '40'),
                ('Laporan Praktikum', '15', '20'),
              ],
            ),
            PrakGrade(
              modul: 2,
              title: 'Widget Dasar Flutter',
              date: 'Sen, 14 September 2026',
              score: '92',
              note: 'Laporan lengkap dan kode berjalan tanpa error. Pertahankan!',
              components: [
                ('Kebenaran Program', '38', '40'),
                ('Tampilan & Navigasi', '36', '40'),
                ('Laporan Praktikum', '18', '20'),
              ],
            ),
            PrakGrade(
              modul: 1,
              title: 'Pengenalan Flutter',
              date: 'Sen, 07 September 2026',
              score: '85',
              note: 'Instalasi dan proyek pertama berhasil. Lengkapi tangkapan layar pada laporan.',
              components: [
                ('Kebenaran Program', '35', '40'),
                ('Tampilan & Navigasi', '34', '40'),
                ('Laporan Praktikum', '16', '20'),
              ],
            ),
          ],
        ),
        PrakCourse(
          id: 'desain',
          name: 'Desain Interaksi',
          asisten: 'Feri Gunawan',
          asistenInitials: 'FG',
          kelas: 'TIF 3002 - Kom C (C1 & C2)',
          room: 'Lab Jaringan 2',
          jadwalDaftar: 'Sel • C1 08:00 | C2 10:00',
          jadwalDetail: 'Sel, C1 08:00–09:40 • C2 10:00–11:40',
          jadwalAbsensi: 'Sel, C1 08:00–09:40 | C2 10:00–11:40',
          jam: 'C1 08:00–09:40 • C2 10:00–11:40 WIB',
          modulTitle: 'Figma Management',
          modulDesc:
              'Pembahasan materi Figma secara mendalam: komponen, variant, dan auto layout.',
          materiTitle: 'Panduan Penggunaan Figma',
          materiFile: 'Panduan_Penggunaan_Figma.pdf',
          tugasTitle: 'Tugas 4 : Pembuatan Prototype Figma',
          tugasDeadline: 'Batas 10:30 WIB, 30 Sep 2026',
          preTest: 'Pre-Test Modul 4 : Figma Management',
          postTest: 'Post-Test Modul 4 : Figma Management',
          hadir: 4,
          izin: 0,
          alpa: 0,
          meetings: [
            PrakMeeting(
              number: 5,
              module: 'Modul 5 • Design System',
              date: 'Sel, 06 Okt 2026 • 08:00–09:40 WIB',
              status: PrakAttend.upcoming,
            ),
            PrakMeeting(
              number: 4,
              module: 'Modul 4 • Figma Management',
              date: 'Sel, 29 Sep 2026 • 08:00–09:40 WIB',
              status: PrakAttend.hadir,
              noteIcon: 'qrcode',
              note: 'Tercatat 08:02 WIB melalui pindai QR',
            ),
            PrakMeeting(
              number: 3,
              module: 'Modul 3 • Prototyping Dasar',
              date: 'Sel, 22 Sep 2026 • 08:00–09:40 WIB',
              status: PrakAttend.hadir,
              noteIcon: 'location',
              note: 'Tercatat 08:00 WIB melalui tombol hadir & lokasi',
            ),
            PrakMeeting(
              number: 2,
              module: 'Modul 2 • Wireframing',
              date: 'Sel, 15 Sep 2026 • 08:00–09:40 WIB',
              status: PrakAttend.hadir,
              noteIcon: 'qrcode',
              note: 'Tercatat 07:58 WIB melalui pindai QR',
            ),
            PrakMeeting(
              number: 1,
              module: 'Modul 1 • Pengenalan Figma',
              date: 'Sel, 08 Sep 2026 • 08:00–09:40 WIB',
              status: PrakAttend.hadir,
              noteIcon: 'qrcode',
              note: 'Tercatat 08:01 WIB melalui pindai QR',
            ),
          ],
          nilaiRata: '84,5',
          akumulasi: '253,5 / 300',
          grades: const [
            PrakGrade(
              modul: 4,
              title: 'Figma Management',
              date: 'Sel, 29 September 2026',
            ),
            PrakGrade(
              modul: 3,
              title: 'Prototyping Dasar',
              date: 'Sel, 22 September 2026',
              score: '85',
              note: 'Alur prototipe sudah jelas. Rapikan penamaan frame dan konsistensi komponen.',
              components: [
                ('Kebenaran Prototipe', '34', '40'),
                ('Tampilan & Navigasi', '35', '40'),
                ('Laporan Praktikum', '16', '20'),
              ],
            ),
            PrakGrade(
              modul: 2,
              title: 'Wireframing',
              date: 'Sel, 15 September 2026',
              score: '82',
              note: 'Wireframe lengkap, namun hierarki konten di halaman utama perlu diperjelas.',
              components: [
                ('Kebenaran Prototipe', '33', '40'),
                ('Tampilan & Navigasi', '33', '40'),
                ('Laporan Praktikum', '16', '20'),
              ],
            ),
            PrakGrade(
              modul: 1,
              title: 'Pengenalan Figma',
              date: 'Sel, 08 September 2026',
              score: '86,5',
              note: 'Eksplorasi tools sudah baik. Lengkapi dokumentasi pada laporan.',
              components: [
                ('Kebenaran Prototipe', '35', '40'),
                ('Tampilan & Navigasi', '34,5', '40'),
                ('Laporan Praktikum', '17', '20'),
              ],
            ),
          ],
        ),
        PrakCourse(
          id: 'adj',
          name: 'Analisis Desain Jaringan',
          asisten: 'Sinta Marpaung',
          asistenInitials: 'SM',
          kelas: 'TIF 3003 - Kom C (C1 & C2)',
          room: 'Lab Jaringan 1',
          jadwalDaftar: 'Rab • C1 10:00 | C2 13:00',
          jadwalDetail: 'Rab, C1 10:00–11:40 • C2 13:00–14:40',
          jadwalAbsensi: 'Rab, C1 10:00–11:40 | C2 13:00–14:40',
          jam: 'C1 10:00–11:40 • C2 13:00–14:40 WIB',
          modulTitle: 'VLAN & Inter-VLAN Routing',
          modulDesc:
              'Perancangan segmentasi VLAN, trunking 802.1Q, dan konfigurasi Router-on-a-Stick pada Cisco Packet Tracer.',
          materiTitle: 'Panduan Konfigurasi VLAN & Trunking',
          materiFile: 'Panduan_VLAN_InterVLAN_Routing.pdf',
          tugasTitle: 'Tugas 4 : Topologi Multi-VLAN Kampus',
          tugasDeadline: 'Batas 10:30 WIB, 01 Okt 2026',
          preTest: 'Pre-Test Modul 4 : VLAN & Routing',
          postTest: 'Post-Test Modul 4 : VLAN & Routing',
          hadir: 4,
          izin: 0,
          alpa: 0,
          meetings: [
            PrakMeeting(
              number: 5,
              module: 'Modul 5 • Dynamic Routing OSPF',
              date: 'Rab, 07 Okt 2026 • 10:00–11:40 WIB',
              status: PrakAttend.upcoming,
            ),
            PrakMeeting(
              number: 4,
              module: 'Modul 4 • VLAN & Inter-VLAN Routing',
              date: 'Rab, 30 Sep 2026 • 10:00–11:40 WIB',
              status: PrakAttend.hadir,
              noteIcon: 'qrcode',
              note: 'Tercatat 10:02 WIB melalui pindai QR',
            ),
            PrakMeeting(
              number: 3,
              module: 'Modul 3 • Subnetting & VLSM',
              date: 'Rab, 23 Sep 2026 • 10:00–11:40 WIB',
              status: PrakAttend.hadir,
              noteIcon: 'location',
              note: 'Tercatat 10:01 WIB melalui tombol hadir & lokasi',
            ),
            PrakMeeting(
              number: 2,
              module: 'Modul 2 • Topologi & Analisis Trafik',
              date: 'Rab, 16 Sep 2026 • 10:00–11:40 WIB',
              status: PrakAttend.hadir,
              noteIcon: 'qrcode',
              note: 'Tercatat 09:59 WIB melalui pindai QR',
            ),
            PrakMeeting(
              number: 1,
              module: 'Modul 1 • Pengenalan Desain Jaringan',
              date: 'Rab, 09 Sep 2026 • 10:00–11:40 WIB',
              status: PrakAttend.hadir,
              noteIcon: 'qrcode',
              note: 'Tercatat 10:00 WIB melalui pindai QR',
            ),
          ],
          nilaiRata: '87,0',
          akumulasi: '261 / 300',
          grades: const [
            PrakGrade(
              modul: 4,
              title: 'VLAN & Inter-VLAN Routing',
              date: 'Rab, 30 September 2026',
            ),
            PrakGrade(
              modul: 3,
              title: 'Subnetting & VLSM',
              date: 'Rab, 23 September 2026',
              score: '88',
              note: 'Perhitungan blok VLSM tepat dan pengujian ping antar subnet berhasil.',
              components: [
                ('Kebenaran Topologi', '36', '40'),
                ('Konfigurasi & Pengujian', '35', '40'),
                ('Laporan Praktikum', '17', '20'),
              ],
            ),
            PrakGrade(
              modul: 2,
              title: 'Topologi & Analisis Trafik',
              date: 'Rab, 16 September 2026',
              score: '86',
              note: 'Analisis paket Wireshark sudah jelas.',
              components: [
                ('Kebenaran Topologi', '35', '40'),
                ('Konfigurasi & Pengujian', '34', '40'),
                ('Laporan Praktikum', '17', '20'),
              ],
            ),
            PrakGrade(
              modul: 1,
              title: 'Pengenalan Desain Jaringan',
              date: 'Rab, 09 September 2026',
              score: '87',
              note: 'Simulasi LAN dasar berjalan baik.',
              components: [
                ('Kebenaran Topologi', '35', '40'),
                ('Konfigurasi & Pengujian', '35', '40'),
                ('Laporan Praktikum', '17', '20'),
              ],
            ),
          ],
        ),
        PrakCourse(
          id: 'ml',
          name: 'Machine Learning',
          asisten: 'Rizky Harahap',
          asistenInitials: 'RH',
          kelas: 'TIF 3004 - Kom C (C1 & C2)',
          room: 'Lab AI & Data',
          jadwalDaftar: 'Kam • C1 13:00 | C2 15:00',
          jadwalDetail: 'Kam, C1 13:00–14:40 • C2 15:00–16:40',
          jadwalAbsensi: 'Kam, C1 13:00–14:40 | C2 15:00–16:40',
          jam: 'C1 13:00–14:40 • C2 15:00–16:40 WIB',
          modulTitle: 'Klasifikasi Supervised Learning',
          modulDesc:
              'Implementasi algoritma Decision Tree, Random Forest, dan evaluasi confusion matrix menggunakan scikit-learn.',
          materiTitle: 'Panduan Klasifikasi Supervised ML',
          materiFile: 'Panduan_Klasifikasi_ScikitLearn.pdf',
          tugasTitle: 'Tugas 4 : Model Klasifikasi Dataset Medis',
          tugasDeadline: 'Batas 10:30 WIB, 02 Okt 2026',
          preTest: 'Pre-Test Modul 4 : Klasifikasi ML',
          postTest: 'Post-Test Modul 4 : Klasifikasi ML',
          hadir: 4,
          izin: 0,
          alpa: 0,
          meetings: [
            PrakMeeting(
              number: 5,
              module: 'Modul 5 • Clustering & Unsupervised',
              date: 'Kam, 08 Okt 2026 • 13:00–14:40 WIB',
              status: PrakAttend.upcoming,
            ),
            PrakMeeting(
              number: 4,
              module: 'Modul 4 • Klasifikasi Supervised Learning',
              date: 'Kam, 01 Okt 2026 • 13:00–14:40 WIB',
              status: PrakAttend.hadir,
              noteIcon: 'qrcode',
              note: 'Tercatat 13:03 WIB melalui pindai QR',
            ),
            PrakMeeting(
              number: 3,
              module: 'Modul 3 • Regresi Linear & Logistik',
              date: 'Kam, 24 Sep 2026 • 13:00–14:40 WIB',
              status: PrakAttend.hadir,
              noteIcon: 'location',
              note: 'Tercatat 13:01 WIB melalui tombol hadir & lokasi',
            ),
            PrakMeeting(
              number: 2,
              module: 'Modul 2 • Preprocessing & EDA',
              date: 'Kam, 17 Sep 2026 • 13:00–14:40 WIB',
              status: PrakAttend.hadir,
              noteIcon: 'qrcode',
              note: 'Tercatat 12:59 WIB melalui pindai QR',
            ),
            PrakMeeting(
              number: 1,
              module: 'Modul 1 • Pengenalan Python & NumPy',
              date: 'Kam, 10 Sep 2026 • 13:00–14:40 WIB',
              status: PrakAttend.hadir,
              noteIcon: 'qrcode',
              note: 'Tercatat 13:00 WIB melalui pindai QR',
            ),
          ],
          nilaiRata: '90,0',
          akumulasi: '270 / 300',
          grades: const [
            PrakGrade(
              modul: 4,
              title: 'Klasifikasi Supervised Learning',
              date: 'Kam, 01 Oktober 2026',
            ),
            PrakGrade(
              modul: 3,
              title: 'Regresi Linear & Logistik',
              date: 'Kam, 24 September 2026',
              score: '91',
              note: 'Evaluasi MSE dan visualisasi kurva regresi sangat rapi.',
              components: [
                ('Pemodelan & Kode', '37', '40'),
                ('Analisis Evaluasi', '36', '40'),
                ('Laporan Praktikum', '18', '20'),
              ],
            ),
            PrakGrade(
              modul: 2,
              title: 'Preprocessing & EDA',
              date: 'Kam, 17 September 2026',
              score: '89',
              note: 'Penanganan missing values dan normalisasi sudah tepat.',
              components: [
                ('Pemodelan & Kode', '36', '40'),
                ('Analisis Evaluasi', '36', '40'),
                ('Laporan Praktikum', '17', '20'),
              ],
            ),
            PrakGrade(
              modul: 1,
              title: 'Pengenalan Python & NumPy',
              date: 'Kam, 10 September 2026',
              score: '90',
              note: 'Eksplorasi Pandas dan Matplotlib berjalan sangat baik.',
              components: [
                ('Pemodelan & Kode', '36', '40'),
                ('Analisis Evaluasi', '36', '40'),
                ('Laporan Praktikum', '18', '20'),
              ],
            ),
          ],
        ),
      ]);
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refreshFromBackend();
    _subscribeRealtime();
  }

  PrakAttend _parseAttend(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'upcoming':
        return PrakAttend.upcoming;
      case 'izin':
        return PrakAttend.izin;
      case 'pending':
        return PrakAttend.pending;
      default:
        return PrakAttend.hadir;
    }
  }

  Future<void> refreshFromBackend() async {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    try {
      final courseRows = await client
          .from('praktikum_courses')
          .select()
          .order('sort_order', ascending: true);

      final meetingRows = await client
          .from('praktikum_meetings')
          .select()
          .order('meeting_number', ascending: false);

      if (courseRows.isNotEmpty) {
        final meetingsByCourse = <String, List<PrakMeeting>>{};
        for (final r in meetingRows) {
          final m = Map<String, dynamic>.from(r);
          final cid = (m['course_id'] ?? '').toString();
          meetingsByCourse.putIfAbsent(cid, () => []).add(
                PrakMeeting(
                  number: (m['meeting_number'] as num?)?.toInt() ?? 1,
                  module: (m['module_title'] ?? '').toString(),
                  date: (m['date_label'] ?? '').toString(),
                  status: _parseAttend(m['attend_status'] as String?),
                  noteIcon: m['attend_note_icon'] as String?,
                  note: m['attend_note'] as String?,
                  izinFile: m['izin_file'] as String?,
                  description: (m['description'] ?? '').toString(),
                  materiTitle: (m['materi_title'] ?? '').toString(),
                  materiFile: (m['materi_file'] ?? '').toString(),
                  tugasTitle: (m['tugas_title'] ?? '').toString(),
                  tugasDeadline: (m['tugas_deadline'] ?? '').toString(),
                  kuisTitle: (m['kuis_title'] ?? '').toString(),
                ),
              );
        }

        final existingById = {for (final c in _courses) c.id: c};
        final updated = <PrakCourse>[];
        for (final r in courseRows) {
          final row = Map<String, dynamic>.from(r);
          final id = (row['id'] ?? '').toString();
          final fallback = existingById[id];
          final meetings = meetingsByCourse[id] ?? fallback?.meetings ?? [];
          final hadir =
              meetings.where((x) => x.status == PrakAttend.hadir).length;
          final izin =
              meetings.where((x) => x.status == PrakAttend.izin).length;

          updated.add(
            PrakCourse(
              id: id,
              name: (row['name'] ?? fallback?.name ?? '').toString(),
              asisten: (row['asisten_name'] ?? fallback?.asisten ?? '').toString(),
              asistenInitials: (row['asisten_initials'] ??
                      fallback?.asistenInitials ??
                      'AS')
                  .toString(),
              kelas: (row['code'] ?? fallback?.kelas ?? '').toString(),
              room: (row['room'] ?? fallback?.room ?? '').toString(),
              jadwalDaftar:
                  (row['jadwal_daftar'] ?? fallback?.jadwalDaftar ?? '')
                      .toString(),
              jadwalDetail:
                  (row['jadwal_detail'] ?? fallback?.jadwalDetail ?? '')
                      .toString(),
              jadwalAbsensi:
                  (row['jadwal_absensi'] ?? fallback?.jadwalAbsensi ?? '')
                      .toString(),
              jam: (row['jam'] ?? fallback?.jam ?? '').toString(),
              modulTitle:
                  (row['modul_title'] ?? fallback?.modulTitle ?? '').toString(),
              modulDesc:
                  (row['modul_desc'] ?? fallback?.modulDesc ?? '').toString(),
              materiTitle:
                  (row['materi_title'] ?? fallback?.materiTitle ?? '')
                      .toString(),
              materiFile:
                  (row['materi_file'] ?? fallback?.materiFile ?? '').toString(),
              tugasTitle:
                  (row['tugas_title'] ?? fallback?.tugasTitle ?? '').toString(),
              tugasDeadline: (row['tugas_deadline'] ??
                      fallback?.tugasDeadline ??
                      'Batas 10:30 WIB, 29 Sep 2026')
                  .toString(),
              preTest:
                  (row['pre_test_title'] ?? fallback?.preTest ?? '').toString(),
              postTest: (row['post_test_title'] ?? fallback?.postTest ?? '')
                  .toString(),
              hadir: hadir > 0 ? hadir : (fallback?.hadir ?? 3),
              izin: izin,
              alpa: fallback?.alpa ?? 0,
              meetings: meetings,
              nilaiRata: fallback?.nilaiRata ?? '88,0',
              akumulasi: fallback?.akumulasi ?? '264 / 300',
              grades: fallback?.grades ?? const [],
            ),
          );
        }
        if (updated.isNotEmpty) {
          final needsKomCMigration = updated.any((c) =>
              !c.kelas.contains('Kom C') ||
              (c.id == 'desain' && c.jadwalDaftar.startsWith('Sen')));
          if (needsKomCMigration) {
            // Migrasi otomatis data lama (Kelas C / Desain Senin) ke Kom C (C1 & C2) beda hari
            _seedDefaults();
            try {
              final nowIso = DateTime.now().toIso8601String();
              for (final c in _courses) {
                await client.from('praktikum_courses').update({
                  'code': c.kelas,
                  'jadwal_daftar': c.jadwalDaftar,
                  'jadwal_detail': c.jadwalDetail,
                  'jadwal_absensi': c.jadwalAbsensi,
                  'jam': c.jam,
                  'updated_at': nowIso,
                }).eq('id', c.id);
              }
              final desainCourse = courseById('desain');
              for (final m in desainCourse.meetings) {
                await client.from('praktikum_meetings').update({
                  'date_label': m.date,
                  'updated_at': nowIso,
                }).eq('id', 'desain-m${m.number}');
              }
            } catch (e) {
              debugPrint('[PraktikumSync] Migrasi Kom C C1/C2 gagal: $e');
            }
          } else {
            _courses
              ..clear()
              ..addAll(updated);
          }
        }
        _backendAvailable = true;
      }

      // Ambil pengumpulan tugas
      final subRows = await client.from('tugas_submissions').select();
      for (final r in subRows) {
        final rec =
            TugasSubmissionRecord.fromJson(Map<String, dynamic>.from(r));
        _submissions[_subKey(rec.courseId, rec.meetingNumber, rec.userIdentifier)] =
            rec;
      }

      // Ambil riwayat kuis
      final quizRows = await client.from('kuis_attempts').select();
      for (final r in quizRows) {
        final rec = KuisAttemptRecord.fromJson(Map<String, dynamic>.from(r));
        _quizAttempts[
            _subKey(rec.courseId, rec.meetingNumber, rec.userIdentifier)] = rec;
      }

      // Ambil penilaian asisten dari praktikan
      final ratingRows = await client.from('asisten_ratings').select();
      for (final r in ratingRows) {
        final rec = AsistenRatingRecord.fromJson(Map<String, dynamic>.from(r));
        _ratingRecords[_ratingKey(rec.courseId, rec.userIdentifier)] = rec;
        _ratingsByCourse[rec.courseId] = rec.ratings;
      }

      notifyListeners();
      debugPrint(
          '[PraktikumSync] Berhasil sinkronisasi ${_courses.length} praktikum dari Supabase.');
    } catch (e) {
      _backendAvailable = false;
      debugPrint(
          '[PraktikumSync] Menggunakan 4 praktikum lokal (Supabase belum dijalankan / offline): $e');
    }
  }

  void _subscribeRealtime() {
    final client = SupabaseService.instance.client;
    if (client == null) return;
    try {
      _channel?.unsubscribe();
      _channel = client
          .channel('itlg-praktikum-sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'praktikum_courses',
            callback: (_) => refreshFromBackend(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'praktikum_meetings',
            callback: (_) => refreshFromBackend(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tugas_submissions',
            callback: (_) => refreshFromBackend(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'kuis_attempts',
            callback: (_) => refreshFromBackend(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'asisten_ratings',
            callback: (_) => refreshFromBackend(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('[PraktikumSync] Gagal pasang realtime channel: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Aksi Backend: Pengumpulan Tugas, Kuis, Rating Asisten, & Materi Aslab
  // ---------------------------------------------------------------------------

  Future<void> saveTugasSubmission({
    required String courseId,
    required int meetingNumber,
    required String userIdentifier,
    required String userName,
    required List<PrakFile> files,
    required String repoUrl,
    required String note,
  }) async {
    final now = DateTime.now();
    final rec = TugasSubmissionRecord(
      courseId: courseId,
      meetingNumber: meetingNumber,
      userIdentifier: userIdentifier,
      userName: userName,
      files: List<PrakFile>.from(files),
      repoUrl: repoUrl,
      note: note,
      status: 'submitted',
      updatedAt: now,
    );
    _submissions[_subKey(courseId, meetingNumber, userIdentifier)] = rec;
    notifyListeners();

    final cName = courseById(courseId).name;
    NotificationSyncService.instance.push(
      role: 'aslab',
      icon: 'clipboard',
      title: 'Tugas Baru Dikumpulkan',
      body: '$userName ($userIdentifier) mengunggah Tugas $meetingNumber • $cName',
      targetKey: 'evaluasi',
      important: true,
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('tugas_submissions').upsert(
          {
            'course_id': courseId,
            'meeting_number': meetingNumber,
            'user_identifier': userIdentifier,
            'user_name': userName,
            'files_json': [
              for (final f in files) {'name': f.name, 'meta': f.meta}
            ],
            'repo_url': repoUrl,
            'note': note,
            'status': 'submitted',
            'updated_at': now.toIso8601String(),
          },
          onConflict: 'course_id,meeting_number,user_identifier',
        );
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[PraktikumSync] saveTugasSubmission error: $e');
      }
    }
  }

  Future<void> cancelTugasSubmission({
    required String courseId,
    required int meetingNumber,
    required String userIdentifier,
  }) async {
    _submissions.remove(_subKey(courseId, meetingNumber, userIdentifier));
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client
            .from('tugas_submissions')
            .update({'status': 'cancelled', 'updated_at': DateTime.now().toIso8601String()})
            .eq('course_id', courseId)
            .eq('meeting_number', meetingNumber)
            .eq('user_identifier', userIdentifier);
      } catch (e) {
        debugPrint('[PraktikumSync] cancelTugasSubmission error: $e');
      }
    }
  }

  Future<KuisAttemptRecord> submitKuisAttempt({
    required String courseId,
    required int meetingNumber,
    required String userIdentifier,
    required String userName,
    required Map<int, int> answers,
    required int durationSeconds,
  }) async {
    // Idempotent: jika praktikan sudah pernah mengirim kuis untuk modul ini,
    // kembalikan hasil sebelumnya tanpa menimpa.
    final key = _subKey(courseId, meetingNumber, userIdentifier);
    final existing = _quizAttempts[key];
    if (existing != null) {
      return existing;
    }

    final questions = questionsForCourse(courseId);
    var correct = 0;
    for (var i = 0; i < questions.length; i++) {
      if (answers[i] == questions[i].answer) correct++;
    }
    final wrong = questions.length - correct;
    final score = questions.isEmpty ? 0 : ((correct * 100) / questions.length).round();
    final now = DateTime.now();

    final rec = KuisAttemptRecord(
      courseId: courseId,
      meetingNumber: meetingNumber,
      userIdentifier: userIdentifier,
      userName: userName,
      answers: Map<int, int>.from(answers),
      score: score,
      correctCount: correct,
      wrongCount: wrong,
      durationSeconds: durationSeconds,
      submittedAt: now,
    );
    _quizAttempts[_subKey(courseId, meetingNumber, userIdentifier)] = rec;
    notifyListeners();

    final cName = courseById(courseId).name;
    NotificationSyncService.instance.push(
      role: 'aslab',
      icon: 'question',
      title: 'Kuis Diselesaikan • $userName',
      body: '$cName Modul $meetingNumber • Skor $score ($correct/${questions.length} benar)',
      targetKey: 'hasilKuis',
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('kuis_attempts').upsert(
          {
            'course_id': courseId,
            'meeting_number': meetingNumber,
            'user_identifier': userIdentifier,
            'user_name': userName,
            'answers_json': {
              for (final e in answers.entries) e.key.toString(): e.value
            },
            'score': score,
            'correct_count': correct,
            'wrong_count': wrong,
            'duration_seconds': durationSeconds,
            'submitted_at': now.toIso8601String(),
          },
          onConflict: 'course_id,meeting_number,user_identifier',
        );
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[PraktikumSync] submitKuisAttempt error: $e');
      }
    }
    return rec;
  }

  Future<AsistenRatingRecord> submitAsistenRating({
    required String courseId,
    required String asistenName,
    required String userIdentifier,
    required List<int> ratings,
    required String comment,
  }) async {
    final normalized = [
      ratings.isNotEmpty ? ratings[0].clamp(1, 5) : 5,
      ratings.length > 1 ? ratings[1].clamp(1, 5) : 4,
      ratings.length > 2 ? ratings[2].clamp(1, 5) : 5,
      ratings.length > 3 ? ratings[3].clamp(1, 5) : 4,
    ];
    final now = DateTime.now();
    final rec = AsistenRatingRecord(
      courseId: courseId,
      asistenName: asistenName,
      userIdentifier: userIdentifier,
      ratings: normalized,
      comment: comment,
      createdAt: now,
    );
    _ratingsByCourse[courseId] = normalized;
    _ratingRecords[_ratingKey(courseId, userIdentifier)] = rec;
    notifyListeners();

    final cName = courseById(courseId).name;
    final avgLabel = rec.averageLabel;
    NotificationSyncService.instance.push(
      role: 'aslab',
      icon: 'star',
      title: 'Evaluasi Kinerja Baru ($avgLabel/5 ★)',
      body:
          'Praktikum $cName menerima penilaian anonim baru${comment.isNotEmpty ? ' • "$comment"' : ''}',
      targetKey: 'evaluasi',
      important: false,
    );
    NotificationSyncService.instance.push(
      role: 'dosen',
      icon: 'star',
      title: 'Evaluasi Asisten: $asistenName ($avgLabel/5 ★)',
      body:
          'Praktikum $cName${comment.isNotEmpty ? ' • $comment' : ' • Penilaian kinerja asisten diperbarui'}',
      targetKey: 'laporan',
      important: false,
    );

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('asisten_ratings').upsert(
          {
            'course_id': courseId,
            'asisten_name': asistenName,
            'user_identifier': userIdentifier,
            'rating_materi': normalized[0],
            'rating_penjelasan': normalized[1],
            'rating_waktu': normalized[2],
            'rating_kesigapan': normalized[3],
            'comment': comment,
            'created_at': now.toIso8601String(),
          },
          onConflict: 'course_id,user_identifier',
        );
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[PraktikumSync] submitAsistenRating error: $e');
      }
    }
    return rec;
  }

  /// Simpan soal kuis kustom yang dibuat Aslab agar langsung muncul di sisi
  /// Praktikan saat mengerjakan kuis.
  void saveQuizQuestionsFromAslab({
    required String courseId,
    required List<PrakQuestion> questions,
  }) {
    if (questions.isEmpty) return;
    _customQuestionsByCourse[courseId] = List<PrakQuestion>.from(questions);
    notifyListeners();
  }

  /// Sinkronisasi dari Aslab: Tambah / perbarui materi, tugas, atau kuis pada
  /// suatu pertemuan agar langsung terlihat di halaman Praktikan.
  Future<void> upsertMeetingContentFromAslab({
    required String courseId,
    required int meetingNumber,
    required String dateLabel,
    required int kind, // 0 modul, 1 tugas, 2 kuis
    required String title,
    required String description,
    String? fileName,
    String? deadline,
  }) async {
    final idx = _courses.indexWhere((c) => c.id == courseId);
    if (idx != -1) {
      final c = _courses[idx];
      final mIdx = c.meetings.indexWhere((m) => m.number == meetingNumber);
      if (mIdx != -1) {
        final old = c.meetings[mIdx];
        c.meetings[mIdx] = PrakMeeting(
          number: old.number,
          module: kind == 0 && title.isNotEmpty
              ? 'Modul $meetingNumber • $title'
              : old.module,
          date: old.date,
          status: old.status,
          noteIcon: old.noteIcon,
          note: old.note,
          izinFile: old.izinFile,
          description: description.isNotEmpty ? description : old.description,
          materiTitle: kind == 0 && title.isNotEmpty ? title : old.materiTitle,
          materiFile: kind == 0 && fileName != null && fileName.isNotEmpty
              ? fileName
              : old.materiFile,
          tugasTitle: kind == 1 && title.isNotEmpty ? title : old.tugasTitle,
          tugasDeadline: kind == 1 && deadline != null && deadline.isNotEmpty
              ? deadline
              : old.tugasDeadline,
          kuisTitle: kind == 2 && title.isNotEmpty ? title : old.kuisTitle,
        );
      } else {
        c.meetings.insert(
          0,
          PrakMeeting(
            number: meetingNumber,
            module:
                'Modul $meetingNumber • ${title.isNotEmpty ? title : 'Materi Baru'}',
            date: dateLabel,
            status: PrakAttend.upcoming,
            description: description,
            materiTitle: kind == 0 ? title : '',
            materiFile: fileName ?? '',
            tugasTitle: kind == 1 ? title : '',
            tugasDeadline: deadline ?? '',
            kuisTitle: kind == 2 ? title : '',
          ),
        );
      }

      // Ikut perbarui ringkasan mata kuliah bila yang diedit adalah pertemuan 4
      // (pertemuan aktif) agar semua layar Praktikan & Aslab langsung sinkron.
      if (meetingNumber == 4) {
        _courses[idx] = PrakCourse(
          id: c.id,
          name: c.name,
          asisten: c.asisten,
          asistenInitials: c.asistenInitials,
          kelas: c.kelas,
          room: c.room,
          jadwalDaftar: c.jadwalDaftar,
          jadwalDetail: c.jadwalDetail,
          jadwalAbsensi: c.jadwalAbsensi,
          jam: c.jam,
          modulTitle: kind == 0 && title.isNotEmpty ? title : c.modulTitle,
          modulDesc: description.isNotEmpty ? description : c.modulDesc,
          materiTitle: kind == 0 && title.isNotEmpty ? title : c.materiTitle,
          materiFile: kind == 0 && fileName != null && fileName.isNotEmpty
              ? fileName
              : c.materiFile,
          tugasTitle: kind == 1 && title.isNotEmpty ? title : c.tugasTitle,
          tugasDeadline: kind == 1 && deadline != null && deadline.isNotEmpty
              ? deadline
              : c.tugasDeadline,
          preTest: kind == 2 && title.isNotEmpty ? title : c.preTest,
          postTest: c.postTest,
          hadir: c.hadir,
          izin: c.izin,
          alpa: c.alpa,
          meetings: c.meetings,
          nilaiRata: c.nilaiRata,
          akumulasi: c.akumulasi,
          grades: c.grades,
        );
      }

      notifyListeners();

      final cName = _courses[idx].name;
      final kindLabel = const ['Modul', 'Tugas', 'Kuis'][kind.clamp(0, 2)];
      NotificationSyncService.instance.push(
        role: 'praktikan',
        icon: kind == 2 ? 'question' : (kind == 1 ? 'clipboard' : 'book_open'),
        title: '$kindLabel Diperbarui: $title',
        body:
            'Praktikum $cName • Pertemuan $meetingNumber telah diperbarui asisten',
        targetKey: kind == 2 ? 'kuis' : 'editTugas',
        important: true,
      );
    }

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        final nowIso = DateTime.now().toIso8601String();
        final payload = <String, dynamic>{
          'id': '$courseId-m$meetingNumber',
          'course_id': courseId,
          'meeting_number': meetingNumber,
          'date_label': dateLabel,
          'updated_at': nowIso,
        };
        if (kind == 0) {
          payload['module_title'] = 'Modul $meetingNumber • $title';
          payload['materi_title'] = title;
          if (description.isNotEmpty) payload['description'] = description;
          if (fileName != null && fileName.isNotEmpty) {
            payload['materi_file'] = fileName;
          }
        } else if (kind == 1) {
          payload['tugas_title'] = title;
          if (description.isNotEmpty) payload['description'] = description;
          if (deadline != null && deadline.isNotEmpty) {
            payload['tugas_deadline'] = deadline;
          }
        } else {
          payload['kuis_title'] = title;
          if (description.isNotEmpty) payload['description'] = description;
        }
        await client.from('praktikum_meetings').upsert(
          payload,
          onConflict: 'course_id,meeting_number',
        );

        if (meetingNumber == 4) {
          final coursePatch = <String, dynamic>{'updated_at': nowIso};
          if (kind == 0) {
            coursePatch['modul_title'] = title;
            coursePatch['materi_title'] = title;
            if (description.isNotEmpty) coursePatch['modul_desc'] = description;
            if (fileName != null && fileName.isNotEmpty) {
              coursePatch['materi_file'] = fileName;
            }
          } else if (kind == 1) {
            coursePatch['tugas_title'] = title;
            if (deadline != null && deadline.isNotEmpty) {
              coursePatch['tugas_deadline'] = deadline;
            }
          } else {
            coursePatch['pre_test_title'] = title;
          }
          await client
              .from('praktikum_courses')
              .update(coursePatch)
              .eq('id', courseId);
        }

        _backendAvailable = true;
      } catch (e) {
        debugPrint('[PraktikumSync] upsertMeetingContentFromAslab error: $e');
      }
    }
  }

  /// Hapus modul / tugas / kuis pada suatu pertemuan dari sisi Aslab dan
  /// sinkronkan penghapusan ke Supabase + Praktikan.
  Future<void> deleteMeetingContentFromAslab({
    required String courseId,
    required int meetingNumber,
    required int kind, // 0 modul, 1 tugas, 2 kuis
  }) async {
    final idx = _courses.indexWhere((c) => c.id == courseId);
    if (idx != -1) {
      final c = _courses[idx];
      final mIdx = c.meetings.indexWhere((m) => m.number == meetingNumber);
      if (mIdx != -1) {
        final old = c.meetings[mIdx];
        c.meetings[mIdx] = PrakMeeting(
          number: old.number,
          module: old.module,
          date: old.date,
          status: old.status,
          noteIcon: old.noteIcon,
          note: old.note,
          izinFile: old.izinFile,
          description: old.description,
          materiTitle: kind == 0 ? '' : old.materiTitle,
          materiFile: kind == 0 ? '' : old.materiFile,
          tugasTitle: kind == 1 ? '' : old.tugasTitle,
          tugasDeadline: kind == 1 ? '' : old.tugasDeadline,
          kuisTitle: kind == 2 ? '' : old.kuisTitle,
        );
      }
      notifyListeners();
    }

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        final patch = <String, dynamic>{
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (kind == 0) {
          patch['materi_title'] = '';
          patch['materi_file'] = '';
        } else if (kind == 1) {
          patch['tugas_title'] = '';
          patch['tugas_deadline'] = '';
        } else {
          patch['kuis_title'] = '';
        }
        await client
            .from('praktikum_meetings')
            .update(patch)
            .eq('course_id', courseId)
            .eq('meeting_number', meetingNumber);
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[PraktikumSync] deleteMeetingContentFromAslab error: $e');
      }
    }
  }
}
