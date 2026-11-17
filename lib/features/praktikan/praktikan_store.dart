/// Data contoh & status tampilan peran Praktikan (tanpa backend).
///
/// Semua teks diambil dari Figma (section "01 Praktikan"). Data yang tidak
/// ada di Figma (misalnya isi praktikum kedua) dibuat mengikuti pola yang sama.

enum PrakAttend { upcoming, hadir, izin, pending }

class PrakMeeting {
  final int number;
  final String module;
  final String date;
  PrakAttend status;

  /// Baris hijau di bawah tanggal (ikon + teks), untuk status hadir.
  final String? noteIcon;
  final String? note;

  /// Lampiran izin yang sudah disetujui.
  final String? izinFile;

  PrakMeeting({
    required this.number,
    required this.module,
    required this.date,
    required this.status,
    this.noteIcon,
    this.note,
    this.izinFile,
  });
}

class PrakGrade {
  final int modul;
  final String title;
  final String date;

  /// null = menunggu penilaian.
  final String? score;
  final String? note;

  /// Komponen nilai untuk halaman Sanggah: (nama, nilai, maksimum).
  final List<(String, String, String)> components;

  const PrakGrade({
    required this.modul,
    required this.title,
    required this.date,
    this.score,
    this.note,
    this.components = const [],
  });
}

class PrakCourse {
  final String name;
  final String asisten;
  final String asistenInitials;
  final String kelas;
  final String room;

  /// "Sen, 08:00–09:40" (Daftar Praktikum), "Sen, 08:00-09:40" (Detail).
  final String jadwalDaftar;
  final String jadwalDetail;
  final String jadwalAbsensi;

  /// Untuk tanggal di kartu Detail Absensi ("08:00–09:40 WIB").
  final String jam;

  // Isi kartu pertemuan di Detail Praktikum.
  final String modulTitle;
  final String modulDesc;
  final String materiTitle;
  final String tugasTitle;
  final String preTest;
  final String postTest;

  // Absensi.
  final int hadir;
  final int izin;
  final int alpa;
  final List<PrakMeeting> meetings;

  // Nilai.
  final String nilaiRata;
  final String akumulasi;
  final List<PrakGrade> grades;

  PrakCourse({
    required this.name,
    required this.asisten,
    required this.asistenInitials,
    required this.kelas,
    required this.room,
    required this.jadwalDaftar,
    required this.jadwalDetail,
    required this.jadwalAbsensi,
    required this.jam,
    required this.modulTitle,
    required this.modulDesc,
    required this.materiTitle,
    required this.tugasTitle,
    required this.preTest,
    required this.postTest,
    required this.hadir,
    required this.izin,
    required this.alpa,
    required this.meetings,
    required this.nilaiRata,
    required this.akumulasi,
    required this.grades,
  });
}

enum PrakNotifTarget {
  editTugas,
  presensi,
  pengumuman,
  detailAbsensi,
  kuis,
  detailNilai,
}

class PrakNotif {
  final String icon;
  final String title;
  final String body;
  final String time;
  final bool today;
  final bool important;
  final PrakNotifTarget target;
  bool unread;

  PrakNotif({
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

class PrakAnnouncement {
  final String tag;
  final bool tagRed;

  /// 1 = Perubahan Jadwal, 2 = Umum (indeks tab di halaman Pengumuman).
  final int category;
  final String time;
  final String title;
  final String body;
  final bool scheduleBox;
  final String author;

  const PrakAnnouncement({
    required this.tag,
    required this.tagRed,
    required this.category,
    required this.time,
    required this.title,
    required this.body,
    required this.author,
    this.scheduleBox = false,
  });
}

class PrakQuestion {
  final String text;
  final List<String> options;
  final int answer;
  const PrakQuestion(this.text, this.options, this.answer);
}

class PrakFile {
  final String name;
  final String meta;
  const PrakFile(this.name, this.meta);
}

/// Status meja di denah Pilih Meja.
enum PrakDesk { available, taken, broken }

class PrakReport {
  final String icon;
  final String title;
  final String meta;

  /// 0 Reported, 1 In Progress, 2 Resolved.
  final int status;
  const PrakReport(this.icon, this.title, this.meta, this.status);
}

class PraktikanStore {
  // ---------------------------------------------------------------------------
  // Praktikum
  // ---------------------------------------------------------------------------

  late final PrakCourse mobile = PrakCourse(
    name: 'Pemrograman Mobile',
    asisten: 'Andi Pratama',
    asistenInitials: 'AP',
    kelas: 'TIF 3001 - Kelas C',
    room: 'Lab Komputer 1',
    jadwalDaftar: 'Sen, 08:00–09:40',
    jadwalDetail: 'Sen, 08:00-09:40',
    jadwalAbsensi: 'Sen, 08:00–09:40',
    jam: '08:00–09:40 WIB',
    modulTitle: 'State Management',
    modulDesc: 'Pembahasan State Management Flutter secara mendalam.',
    materiTitle: 'Panduan State Management Flutter',
    tugasTitle: 'Tugas 4 : Implementasi State Management',
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
        note: 'Struktur widget sudah rapi dan navigasi berjalan baik. '
            'Perbaiki penamaan route dan tambahkan validasi form pada '
            'halaman login.',
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
        note: 'Instalasi dan proyek pertama berhasil. Lengkapi tangkapan '
            'layar pada laporan.',
        components: [
          ('Kebenaran Program', '35', '40'),
          ('Tampilan & Navigasi', '34', '40'),
          ('Laporan Praktikum', '16', '20'),
        ],
      ),
    ],
  );

  late final PrakCourse desain = PrakCourse(
    name: 'Desain Interaksi',
    asisten: 'Feri Gunawan',
    asistenInitials: 'FG',
    kelas: 'TIF 3001 - Kelas C',
    room: 'Lab Jaringan 2',
    jadwalDaftar: 'Sen, 08:00–09:40',
    jadwalDetail: 'Sen, 08:00-09:40',
    jadwalAbsensi: 'Sen, 13:00–14:40',
    jam: '13:00–14:40 WIB',
    modulTitle: 'Figma Management',
    modulDesc: 'Pembahasan Materi Figma secara mendalam.',
    materiTitle: 'Panduan Pengguanan Figma',
    tugasTitle: 'Tugas 4 : Pembuatan Prototype Figma',
    preTest: 'Pre-Test Modul 4 : Figma Management',
    postTest: 'Post-Test Modul 4 : Figma Management',
    hadir: 4,
    izin: 0,
    alpa: 0,
    meetings: [
      PrakMeeting(
        number: 5,
        module: 'Modul 5 • Design System',
        date: 'Sen, 05 Okt 2026 • 13:00–14:40 WIB',
        status: PrakAttend.upcoming,
      ),
      PrakMeeting(
        number: 4,
        module: 'Modul 4 • Figma Management',
        date: 'Sen, 28 Sep 2026 • 13:00–14:40 WIB',
        status: PrakAttend.hadir,
        noteIcon: 'qrcode',
        note: 'Tercatat 13:02 WIB melalui pindai QR',
      ),
      PrakMeeting(
        number: 3,
        module: 'Modul 3 • Prototyping Dasar',
        date: 'Sen, 21 Sep 2026 • 13:00–14:40 WIB',
        status: PrakAttend.hadir,
        noteIcon: 'location',
        note: 'Tercatat 13:00 WIB melalui tombol hadir & lokasi',
      ),
      PrakMeeting(
        number: 2,
        module: 'Modul 2 • Wireframing',
        date: 'Sen, 14 Sep 2026 • 13:00–14:40 WIB',
        status: PrakAttend.hadir,
        noteIcon: 'qrcode',
        note: 'Tercatat 12:58 WIB melalui pindai QR',
      ),
      PrakMeeting(
        number: 1,
        module: 'Modul 1 • Pengenalan Figma',
        date: 'Sen, 07 Sep 2026 • 13:00–14:40 WIB',
        status: PrakAttend.hadir,
        noteIcon: 'qrcode',
        note: 'Tercatat 13:01 WIB melalui pindai QR',
      ),
    ],
    nilaiRata: '84,5',
    akumulasi: '253,5 / 300',
    grades: const [
      PrakGrade(
        modul: 4,
        title: 'Figma Management',
        date: 'Sen, 28 September 2026',
      ),
      PrakGrade(
        modul: 3,
        title: 'Prototyping Dasar',
        date: 'Sen, 21 September 2026',
        score: '85',
        note: 'Alur prototipe sudah jelas. Rapikan penamaan frame dan '
            'konsistensi komponen.',
        components: [
          ('Kebenaran Prototipe', '34', '40'),
          ('Tampilan & Navigasi', '35', '40'),
          ('Laporan Praktikum', '16', '20'),
        ],
      ),
      PrakGrade(
        modul: 2,
        title: 'Wireframing',
        date: 'Sen, 14 September 2026',
        score: '82',
        note: 'Wireframe lengkap, namun hierarki konten di halaman utama '
            'perlu diperjelas.',
        components: [
          ('Kebenaran Prototipe', '33', '40'),
          ('Tampilan & Navigasi', '33', '40'),
          ('Laporan Praktikum', '16', '20'),
        ],
      ),
      PrakGrade(
        modul: 1,
        title: 'Pengenalan Figma',
        date: 'Sen, 07 September 2026',
        score: '86,5',
        note: 'Eksplorasi tools sudah baik. Lengkapi dokumentasi pada '
            'laporan.',
        components: [
          ('Kebenaran Prototipe', '35', '40'),
          ('Tampilan & Navigasi', '34,5', '40'),
          ('Laporan Praktikum', '17', '20'),
        ],
      ),
    ],
  );

  List<PrakCourse> get courses => [mobile, desain];

  // ---------------------------------------------------------------------------
  // Pengumuman & notifikasi
  // ---------------------------------------------------------------------------

  final List<PrakAnnouncement> announcements = const [
    PrakAnnouncement(
      tag: 'Perubahan Jadwal',
      tagRed: true,
      category: 1,
      time: '2 jam lalu',
      title: 'Praktikum pengganti Pertemuan 3',
      body: 'Praktikum Basis Data Kelas B dipindahkan karena bertepatan '
          'dengan libur nasional.',
      scheduleBox: true,
      author: 'Sinta Marpaung • Asisten Lab',
    ),
    PrakAnnouncement(
      tag: 'Umum',
      tagRed: false,
      category: 2,
      time: 'Kemarin, 16:20',
      title: 'Modul 5 sudah dapat diunduh',
      body: 'Materi Navigasi & Routing tersedia di halaman Detail Praktikum. '
          'Pelajari sebelum pertemuan.',
      author: 'Andi Pratama • Asisten Lab',
    ),
    PrakAnnouncement(
      tag: 'Penting',
      tagRed: true,
      category: 2,
      time: 'Kemarin, 09:10',
      title: 'Lab Komputer 1 ditutup sementara',
      body: 'Perbaikan proyektor pada Jumat, 02 Okt 2026 pukul 10:00–12:00.',
      author: 'Budi Santoso • Laboran',
    ),
  ];

  bool announcementUnread = true;

  final List<PrakNotif> notifs = [
    PrakNotif(
      icon: 'clock',
      title: 'Deadline Tugas 4 besok',
      body: 'Praktikum Desain Interaksi • kumpulkan sebelum Senin 29 Sep, '
          '10:30 WIB',
      time: '5 menit lalu',
      today: true,
      important: true,
      unread: true,
      target: PrakNotifTarget.editTugas,
    ),
    PrakNotif(
      icon: 'qrcode',
      title: 'Sesi presensi dibuka',
      body: 'Pemrograman Mobile Kelas C • Lab Komputer 1',
      time: '1 jam lalu',
      today: true,
      important: true,
      unread: true,
      target: PrakNotifTarget.presensi,
    ),
    PrakNotif(
      icon: 'bullhorn_outline',
      title: 'Perubahan jadwal praktikum',
      body: 'Praktikum pengganti Pertemuan 3 • Kam, 01 Okt 13:00',
      time: '2 jam lalu',
      today: true,
      important: true,
      unread: true,
      target: PrakNotifTarget.pengumuman,
    ),
    PrakNotif(
      icon: 'circle_check',
      title: 'Izin Pertemuan 2 disetujui',
      body: 'Andi Pratama menyetujui izin sakit anda',
      time: 'Kemarin, 15:10',
      today: false,
      important: false,
      target: PrakNotifTarget.detailAbsensi,
    ),
    PrakNotif(
      icon: 'clipboard',
      title: 'Kuis Pre-Test Modul 4 tersedia',
      body: 'Praktikum Desain Interaksi • 10 soal, 10 menit',
      time: 'Kemarin, 11:42',
      today: false,
      important: false,
      target: PrakNotifTarget.kuis,
    ),
    PrakNotif(
      icon: 'trophy',
      title: 'Nilai Modul 3 sudah keluar',
      body: 'Praktikum Pemrograman Mobile • 88 / 100 dengan catatan asisten',
      time: 'Kemarin, 09:05',
      today: false,
      important: false,
      target: PrakNotifTarget.detailNilai,
    ),
  ];

  int get unreadCount => notifs.where((n) => n.unread).length;

  // ---------------------------------------------------------------------------
  // Kuis (Figma: posisi di Soal 3, soal 1–2 sudah dijawab, B dipilih)
  // ---------------------------------------------------------------------------

  final List<PrakQuestion> questions = const [
    PrakQuestion(
      'Fitur Flutter yang menampilkan perubahan kode tanpa menghilangkan '
          'state aplikasi adalah...',
      ['Hot Restart', 'Flutter Doctor', 'Hot Reload', 'Build Runner'],
      2,
    ),
    PrakQuestion(
      'Method yang dipanggil untuk memberi tahu framework bahwa nilai state '
          'berubah adalah...',
      ['setState()', 'initState()', 'dispose()', 'build()'],
      0,
    ),
    PrakQuestion(
      'Widget manakah yang digunakan untuk membangun ulang tampilan ketika '
          'nilai state berubah?',
      ['StatelessWidget', 'StatefulWidget', 'InheritedWidget', 'Container'],
      1,
    ),
    PrakQuestion(
      'Package state management yang direkomendasikan tim Flutter untuk '
          'berbagi state antar-widget adalah...',
      ['GetX', 'Provider', 'Redux', 'MobX'],
      1,
    ),
    PrakQuestion(
      'Method yang dipanggil sekali saat State pertama kali dibuat adalah...',
      ['build()', 'didUpdateWidget()', 'initState()', 'deactivate()'],
      2,
    ),
    PrakQuestion(
      'Kelas pada Provider yang memberi tahu listener ketika data berubah '
          'adalah...',
      ['ChangeNotifier', 'StreamBuilder', 'FutureBuilder', 'BuildContext'],
      0,
    ),
    PrakQuestion(
      'Method ChangeNotifier untuk memperbarui widget yang mendengarkan '
          'adalah...',
      ['refresh()', 'notifyListeners()', 'setState()', 'update()'],
      1,
    ),
    PrakQuestion(
      'Widget yang membaca nilai Provider dan membangun ulang hanya '
          'bagiannya sendiri adalah...',
      ['Builder', 'Consumer', 'Container', 'Scaffold'],
      1,
    ),
    PrakQuestion(
      'State yang hanya dipakai oleh satu widget disebut...',
      ['App state', 'Global state', 'Ephemeral state', 'Shared state'],
      2,
    ),
    PrakQuestion(
      'Method untuk membersihkan controller saat widget dihapus dari tree '
          'adalah...',
      ['dispose()', 'reassemble()', 'initState()', 'build()'],
      0,
    ),
  ];

  /// Jawaban yang sudah dikirim (indeks soal → indeks opsi).
  final Map<int, int> quizAnswers = {0: 2, 1: 0};

  /// Pilihan pada soal yang sedang dibuka (belum dihitung "terjawab").
  final Map<int, int> quizDraft = {2: 1};
  int quizIndex = 2;
  int quizSecondsLeft = 4 * 60 + 32;

  // ---------------------------------------------------------------------------
  // Tugas, izin, penilaian, presensi
  // ---------------------------------------------------------------------------

  final List<PrakFile> tugasFiles = [
    const PrakFile('MidFidelity Tugas', 'Diunggah 27 Sep, 20:14'),
    const PrakFile('Laporan Tugas', 'Diunggah 27 Sep, 20:15'),
  ];

  /// Nilai bintang di Penilaian Asisten (Figma: 5, 4, 5, 4).
  final List<int> ratings = [5, 4, 5, 4];

  int presensiSecondsLeft = 12 * 60 + 40;

  // ---------------------------------------------------------------------------
  // Meja & laporan kerusakan
  // ---------------------------------------------------------------------------

  /// Denah 30 meja: tersedia 3, 8, 14, 17, 25, 27, 30; rusak 23.
  final Map<int, PrakDesk> desks = {
    for (var i = 1; i <= 30; i++)
      i: const {3, 8, 14, 17, 25, 27, 30}.contains(i)
          ? PrakDesk.available
          : (i == 23 ? PrakDesk.broken : PrakDesk.taken),
  };
  int selectedDesk = 14;

  final List<PrakReport> reports = [
    const PrakReport(
        'wifi', 'Koneksi jaringan putus', 'Lab Jaringan 2 • 27 Sep', 1),
    const PrakReport(
        'projector', 'Proyektor buram', 'Lab Komputer 1 • 24 Sep', 2),
  ];

  // ---------------------------------------------------------------------------
  // Profil
  // ---------------------------------------------------------------------------

  bool pushOn = true;
}
