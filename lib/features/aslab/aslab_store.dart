/// Data contoh & status tampilan peran Asisten Lab (tanpa backend).
///
/// Teks diambil dari Figma (section "02 Asisten Lab"). Isi praktikum kedua
/// (Basis Data) dibuat mengikuti pola yang sama karena Figma hanya memuat
/// contoh Pemrograman Mobile.

class AslabStudent {
  final String initials;
  final String name;
  final String nim;
  const AslabStudent(this.initials, this.name, this.nim);
}

const AslabStudent kRina = AslabStudent('RN', 'Rina Novita', '231402045');
const AslabStudent kDimas = AslabStudent('DS', 'Dimas Saputra', '231402051');
const AslabStudent kMaya = AslabStudent('MH', 'Maya Hutagalung', '231402063');
const AslabStudent kYoga = AslabStudent('YS', 'Yoga Siregar', '231402070');
const AslabStudent kLia = AslabStudent('LN', 'Lia Nasution', '231402082');

/// Satu kotak materi di kartu pertemuan Detail Praktikum Saya.
class AslabItem {
  /// 0 modul, 1 tugas, 2 kuis.
  final int kind;
  final String title;
  final String meta;
  const AslabItem(this.kind, this.title, this.meta);
}

class AslabMeeting {
  final int number;
  final String date;
  final String title;
  final List<AslabItem> items;
  const AslabMeeting(this.number, this.date, this.title, this.items);
}

/// Pertemuan di Detail Absensi Praktikum.
class AslabSession {
  final int number;
  final String module;
  final String date;

  /// 0 belum dibuat (bisa dibuat), 1 belum dibuat (terkunci), 2 selesai.
  final int state;
  final int hadir;
  final int izin;
  final int alpa;

  const AslabSession(
    this.number,
    this.module,
    this.date,
    this.state, {
    this.hadir = 0,
    this.izin = 0,
    this.alpa = 0,
  });
}

class AslabCourse {
  final String id;
  final String name;
  final String kelas;
  final String room;
  final String jadwal;
  final String rataHadir;
  final List<AslabMeeting> meetings;
  final List<AslabSession> sessions;

  const AslabCourse({
    this.id = 'pemob',
    required this.name,
    required this.kelas,
    required this.room,
    required this.jadwal,
    required this.rataHadir,
    required this.meetings,
    required this.sessions,
  });
}

/// Status presensi praktikan di Detail Presensi Pertemuan.
enum AslabAttend { hadir, izin, alpa }

class AslabPresence {
  final AslabStudent student;
  AslabAttend status;

  /// Bukti presensi (ikon + teks), null bila tidak ada.
  final List<(String, String)> proof;
  final bool proofLink;
  final String? changedTag;

  /// Izin: (jenis, keterangan, berkas).
  final (String, String, String)? izin;

  AslabPresence(
    this.student,
    this.status, {
    this.proof = const [],
    this.proofLink = false,
    this.changedTag,
    this.izin,
  });
}

/// Pengajuan izin di Persetujuan Izin.
class AslabLeave {
  final AslabStudent student;
  final String type;
  final String pertemuan;
  final String diajukan;
  final String note;
  final String? file;
  final String approveLabel;

  /// 0 menunggu, 1 disetujui, 2 ditolak.
  int status = 0;

  AslabLeave({
    required this.student,
    required this.type,
    required this.pertemuan,
    required this.diajukan,
    required this.note,
    required this.approveLabel,
    this.file,
  });
}

/// Riwayat tukar shift.
class AslabSwap {
  final String code;
  final bool approved;
  final bool mine;
  final (String, String) initials;
  final String names;
  final String meta;
  final (String, String) left;
  final (String, String) right;

  const AslabSwap({
    required this.code,
    required this.approved,
    required this.mine,
    required this.initials,
    required this.names,
    required this.meta,
    required this.left,
    required this.right,
  });
}

enum AslabNotifTarget {
  evaluasi,
  shiftJaga,
  persetujuanIzin,
  laporKendala,
  detailPresensi,
  hasilKuis,
}

class AslabNotif {
  final String icon;
  final String title;
  final String body;
  final String time;
  final bool today;
  final bool important;
  final AslabNotifTarget target;
  bool unread;

  AslabNotif({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.today,
    required this.important,
    required this.target,
    this.unread = false,
  });
}

class AslabReport {
  final String icon;
  final String title;
  final String meta;

  /// 0 Reported, 1 In Progress, 2 Resolved.
  final int status;
  const AslabReport(this.icon, this.title, this.meta, this.status);
}

class AslabStore {
  // ---------------------------------------------------------------------------
  // Praktikum yang diampu
  // ---------------------------------------------------------------------------

  final AslabCourse mobile = const AslabCourse(
    name: 'Pemrograman Mobile',
    kelas: 'TIF 3001 - Kelas C',
    room: 'Lab Komputer 1',
    jadwal: 'Sen, 08:00–09:40',
    rataHadir: '91%',
    meetings: [
      AslabMeeting(4, 'Sen, 28 September 2026',
          'Pertemuan 4 :\nState Management', [
        AslabItem(0, 'Modul 4 : Flutter State Management',
            'PDF • 3,2 MB • dilihat 21 / 24'),
        AslabItem(1, 'Tugas 4 : Aplikasi Counter',
            'Deadline 29 Sep, 10:30 • 20 / 24 terkumpul'),
        AslabItem(2, 'Pre-Test Modul 4',
            '10 soal • 10 menit • 22 / 24 mengerjakan'),
      ]),
      AslabMeeting(3, 'Sen, 21 September 2026',
          'Pertemuan 3 :\nLayout & Navigasi', [
        AslabItem(0, 'Modul 3 : Layout & Navigasi',
            'PDF • 2,6 MB • dilihat 24 / 24'),
        AslabItem(1, 'Tugas 3 : Halaman Login', 'Selesai dinilai 24 / 24'),
      ]),
    ],
    sessions: [
      AslabSession(5, 'Modul 5 • Navigasi & Routing',
          'Sen, 05 Okt 2026 • 08:00–09:40 WIB', 0),
      AslabSession(6, 'Modul 6 • Form & Validasi',
          'Sen, 12 Okt 2026 • 08:00–09:40 WIB', 1),
      AslabSession(4, 'Modul 4 • State Management',
          'Sen, 28 Sep 2026 • 08:00–09:40 WIB', 2,
          hadir: 21, izin: 2, alpa: 1),
      AslabSession(3, 'Modul 3 • Layout & Navigasi',
          'Sen, 21 Sep 2026 • 08:00–09:40 WIB', 2,
          hadir: 23, izin: 1, alpa: 0),
    ],
  );

  final AslabCourse basisData = const AslabCourse(
    name: 'Basis Data',
    kelas: 'TIF 2104 - Kelas C',
    room: 'Lab Jaringan 2',
    jadwal: 'Sen, 13:00–14:40',
    rataHadir: '88%',
    meetings: [
      AslabMeeting(4, 'Sen, 28 September 2026',
          'Pertemuan 4 :\nERD & Query SQL', [
        AslabItem(0, 'Modul 4 : Perancangan ERD & Query SQL',
            'PDF • 2,8 MB • dilihat 22 / 24'),
        AslabItem(1, 'Tugas 4 : Perancangan ERD & Query SQL',
            'Deadline 29 Sep, 10:30 • 20 / 24 terkumpul'),
        AslabItem(2, 'Pre-Test Modul 4',
            '10 soal • 10 menit • 21 / 24 mengerjakan'),
      ]),
      AslabMeeting(3, 'Sen, 21 September 2026',
          'Pertemuan 3 :\nNormalisasi Data', [
        AslabItem(0, 'Modul 3 : Normalisasi Data',
            'PDF • 2,1 MB • dilihat 24 / 24'),
        AslabItem(1, 'Tugas 3 : Normalisasi Tabel', 'Selesai dinilai 24 / 24'),
      ]),
    ],
    sessions: [
      AslabSession(5, 'Modul 5 • Join & Subquery',
          'Sen, 05 Okt 2026 • 13:00–14:40 WIB', 0),
      AslabSession(6, 'Modul 6 • View & Index',
          'Sen, 12 Okt 2026 • 13:00–14:40 WIB', 1),
      AslabSession(4, 'Modul 4 • ERD & Query SQL',
          'Sen, 28 Sep 2026 • 13:00–14:40 WIB', 2,
          hadir: 20, izin: 3, alpa: 1),
      AslabSession(3, 'Modul 3 • Normalisasi Data',
          'Sen, 21 Sep 2026 • 13:00–14:40 WIB', 2,
          hadir: 22, izin: 1, alpa: 1),
    ],
  );

  List<AslabCourse> get courses => [mobile, basisData];

  // ---------------------------------------------------------------------------
  // Shift jaga
  // ---------------------------------------------------------------------------

  /// null = belum dijawab, true = diterima, false = ditolak.
  bool? swapAnswer;

  final List<AslabSwap> swaps = const [
    AslabSwap(
      code: '#TS-014',
      approved: true,
      mine: true,
      initials: ('AP', 'FG'),
      names: 'Andi Pratama & Feri Gunawan',
      meta: 'Diajukan 27 Sep 2026 • Disetujui Feri',
      left: ('Shift Andi', 'Rab, 30 Sep • 13:00'),
      right: ('Shift Feri', 'Kam, 01 Okt • 08:00'),
    ),
    AslabSwap(
      code: '#TS-013',
      approved: true,
      mine: false,
      initials: ('SM', 'RH'),
      names: 'Sinta Marpaung & Rizky Harahap',
      meta: 'Diajukan 20 Sep 2026 • Disetujui Rizky',
      left: ('Shift Sinta', 'Sel, 22 Sep • 10:00'),
      right: ('Shift Rizky', 'Kam, 24 Sep • 13:00'),
    ),
    AslabSwap(
      code: '#TS-011',
      approved: false,
      mine: true,
      initials: ('AP', 'SM'),
      names: 'Andi Pratama & Sinta Marpaung',
      meta: 'Diajukan 16 Sep 2026 • Ditolak Sinta',
      left: ('Shift Andi', 'Jum, 18 Sep • 08:00'),
      right: ('Shift Sinta', 'Sen, 21 Sep • 13:00'),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Izin, presensi, laporan
  // ---------------------------------------------------------------------------

  final List<AslabLeave> leaves = [
    AslabLeave(
      student: kRina,
      type: 'Izin Sakit',
      pertemuan: '5 • Sen, 05 Okt',
      diajukan: '04 Okt, 19:20',
      note: 'Demam dan disarankan beristirahat oleh dokter klinik kampus.',
      file: 'surat_dokter.pdf',
      approveLabel: 'Setujui',
    ),
    AslabLeave(
      student: kDimas,
      type: 'Kendala Perangkat',
      pertemuan: '4 • Sen, 28 Sep',
      diajukan: '28 Sep, 08:06',
      note: 'Kamera ponsel rusak sehingga tidak dapat memindai QR. Saya hadir '
          'di Lab Komputer 1.',
      approveLabel: 'Tandai Hadir',
    ),
  ];

  int get pendingLeaves => leaves.where((l) => l.status == 0).length;

  final List<AslabPresence> presences = [
    AslabPresence(
      kRina,
      AslabAttend.hadir,
      proof: const [
        ('location', 'Tombol + Lokasi • 08:02'),
        ('signature_freehand', 'Bertanda tangan'),
      ],
      proofLink: true,
    ),
    AslabPresence(
      kDimas,
      AslabAttend.hadir,
      proof: const [
        ('pencil', 'Diubah manual oleh asisten • tanpa tanda tangan'),
      ],
      changedTag: 'Diubah dari Alpa',
    ),
    AslabPresence(
      kMaya,
      AslabAttend.izin,
      izin: (
        'Izin Sakit',
        'Demam dan disarankan beristirahat oleh dokter klinik kampus.',
        'surat_dokter.pdf',
      ),
    ),
    AslabPresence(kYoga, AslabAttend.alpa),
    AslabPresence(
      kLia,
      AslabAttend.izin,
      izin: (
        'Izin Keluarga',
        'Menghadiri acara keluarga di luar kota.',
        'surat_izin.pdf',
      ),
    ),
  ];

  final List<AslabReport> reports = [
    const AslabReport(
        'wifi', 'Koneksi jaringan putus', 'Lab Jaringan 2 • 27 Sep', 1),
    const AslabReport(
        'projector', 'Proyektor buram', 'Lab Komputer 1 • 24 Sep', 2),
  ];

  // ---------------------------------------------------------------------------
  // Sesi presensi berjalan (Figma: 00:24:18)
  // ---------------------------------------------------------------------------

  final DateTime sessionStart =
      DateTime.now().subtract(const Duration(minutes: 24, seconds: 18));

  // ---------------------------------------------------------------------------
  // Notifikasi
  // ---------------------------------------------------------------------------

  final List<AslabNotif> notifs = [
    AslabNotif(
      icon: 'clipboard',
      title: '6 tugas menunggu penilaian',
      body: 'Tugas 4 • Praktikum Basis Data Kelas C',
      time: '5 menit lalu',
      today: true,
      important: true,
      unread: true,
      target: AslabNotifTarget.evaluasi,
    ),
    AslabNotif(
      icon: 'arrow_right_left',
      title: 'Permintaan tukar shift',
      body: 'Feri Gunawan meminta bertukar shift Rabu, 30 Sep',
      time: '1 jam lalu',
      today: true,
      important: true,
      unread: true,
      target: AslabNotifTarget.shiftJaga,
    ),
    AslabNotif(
      icon: 'envelope',
      title: 'Pengajuan izin baru',
      body: 'Rina Novita • Pertemuan 5 • Sakit',
      time: '2 jam lalu',
      today: true,
      important: true,
      unread: true,
      target: AslabNotifTarget.persetujuanIzin,
    ),
    AslabNotif(
      icon: 'ticket',
      title: 'Laporan kendala diproses',
      body: 'Koneksi jaringan putus kini berstatus In Progress',
      time: 'Kemarin, 15:10',
      today: false,
      important: false,
      target: AslabNotifTarget.laporKendala,
    ),
    AslabNotif(
      icon: 'circle_check',
      title: 'Sesi presensi Pertemuan 4 selesai',
      body: '21 dari 24 praktikan hadir • Lab Komputer 1',
      time: 'Kemarin, 11:42',
      today: false,
      important: false,
      target: AslabNotifTarget.detailPresensi,
    ),
    AslabNotif(
      icon: 'statistic_up',
      title: 'Hasil Pre-Test Modul 4 masuk',
      body: '22 dari 24 praktikan sudah mengerjakan',
      time: 'Kemarin, 09:05',
      today: false,
      important: false,
      target: AslabNotifTarget.hasilKuis,
    ),
  ];

  int get unreadCount => notifs.where((n) => n.unread).length;

  // ---------------------------------------------------------------------------
  // Profil
  // ---------------------------------------------------------------------------

  bool pushOn = true;
}
