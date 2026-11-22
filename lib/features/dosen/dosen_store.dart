/// Data contoh untuk tampilan Dosen Pengampu (belum terhubung ke backend).
/// Isinya sama dengan teks pada desain Figma "04 Dosen Pengampu".

enum MeetingStatus { upcoming, hadir, terlambat, izin, alpa }

class DosenMeeting {
  final int number;
  final String module;
  final String date;
  final MeetingStatus status;

  /// Chip "Alpa" yang disertai catatan memakai Bold + bayangan di Figma.
  final bool emphasis;
  final String? noteIcon;
  final String? note;

  const DosenMeeting({
    required this.number,
    required this.module,
    required this.date,
    required this.status,
    this.emphasis = false,
    this.noteIcon,
    this.note,
  });
}

class DosenStudent {
  final String initials;
  final String name;
  final String nim;
  final String kelas;

  /// Persentase kehadiran (batas minimal 75).
  final int attendance;

  /// Rata-rata nilai (batas minimal 70).
  final int score;
  final bool highRisk;

  // Detail Peringatan
  final int hadir;
  final int izin;
  final int alpa;
  final List<DosenMeeting> meetings;

  // Hubungi Asisten
  final String asisten;
  final String asistenInitials;

  /// 0 Kehadiran, 1 Konsultasi, 2 Remedial.
  final int followUp;
  final String message;

  const DosenStudent({
    required this.initials,
    required this.name,
    required this.nim,
    required this.kelas,
    required this.attendance,
    required this.score,
    required this.highRisk,
    required this.hadir,
    required this.izin,
    required this.alpa,
    required this.meetings,
    required this.asisten,
    required this.asistenInitials,
    required this.followUp,
    required this.message,
  });

  bool get lowAttendance => attendance < 75;
  bool get lowScore => score < 70;
}

class DosenGrade {
  final String name;
  final String nim;
  final String tugas;
  final String presensi;
  final String akhir;
  final String huruf;

  const DosenGrade(
      this.name, this.nim, this.tugas, this.presensi, this.akhir, this.huruf);

  bool get lulus => int.parse(akhir) >= 60;
}

class DosenDownload {
  final String month;
  final String name;
  final String meta;
  final bool spreadsheet;

  const DosenDownload(this.month, this.name, this.meta, this.spreadsheet);
}

enum DosenNotifTarget { peringatan, validasi, laporan, detailPeringatan }

class DosenNotif {
  final String icon;
  final String title;
  final String body;
  final String time;
  final bool today;
  final bool important;
  final DosenNotifTarget target;
  bool unread;

  DosenNotif({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.today,
    required this.target,
    this.important = false,
    this.unread = false,
  });
}

// Jadwal Kelas C (Senin 08:00) dan Kelas A (Selasa 10:00).
const String _modul5 = 'Modul 5 • Navigasi & Routing';
const String _modul4 = 'Modul 4 • State Management';
const String _modul3 = 'Modul 3 • Layout & Navigasi';
const String _modul2 = 'Modul 2 • Widget Dasar';
const String _modul1 = 'Modul 1 • Pengenalan Flutter';

class DosenStore {
  bool pushOn = true;

  /// Validasi Nilai Akhir: sudah disinkronkan atau belum.
  bool validated = false;

  // Pengaturan Generate Laporan (disimpan supaya tidak hilang saat pindah tab).
  int praktikumIndex = 0;
  int periodeIndex = 0;
  final Set<int> isiLaporan = {0, 1};

  /// 0 = Spreadsheet (.xlsx), 1 = PDF.
  int format = 0;

  final List<String> praktikumOptions = const [
    'Pemrograman Mobile • TIF 3001 - Kelas C',
    'Desain Interaksi • TIF 3002 - Kelas C',
    'Analisis Desain Jaringan • TIF 3003 - Kelas C',
    'Machine Learning • TIF 3004 - Kelas C',
  ];

  final List<String> periodeOptions = const [
    'Semester Ganjil 2026/2027',
    'Semester Genap 2025/2026',
  ];

  final List<DosenStudent> students = const [
    DosenStudent(
      initials: 'YS',
      name: 'Yoga Siregar',
      nim: '231402070',
      kelas: 'Kelas C',
      attendance: 50,
      score: 64,
      highRisk: true,
      hadir: 2,
      izin: 0,
      alpa: 2,
      meetings: [
        DosenMeeting(
            number: 5,
            module: _modul5,
            date: 'Sen, 05 Okt 2026 • 08:00–09:40 WIB',
            status: MeetingStatus.upcoming),
        DosenMeeting(
            number: 4,
            module: _modul4,
            date: 'Sen, 28 Sep 2026 • 08:00–09:40 WIB',
            status: MeetingStatus.alpa,
            emphasis: true,
            noteIcon: 'cross',
            note: 'Tidak ada presensi tercatat'),
        DosenMeeting(
            number: 3,
            module: _modul3,
            date: 'Sen, 21 Sep 2026 • 08:00–09:40 WIB',
            status: MeetingStatus.hadir,
            noteIcon: 'location',
            note: 'Tercatat 08:01 WIB melalui tombol hadir & lokasi'),
        DosenMeeting(
            number: 2,
            module: _modul2,
            date: 'Sen, 14 Sep 2026 • 08:00–09:40 WIB',
            status: MeetingStatus.alpa),
        DosenMeeting(
            number: 1,
            module: _modul1,
            date: 'Sen, 07 Sep 2026 • 08:00–09:40 WIB',
            status: MeetingStatus.hadir,
            noteIcon: 'qrcode',
            note: 'Tercatat 07:58 WIB melalui pindai QR'),
      ],
      asisten: 'Andi Pratama',
      asistenInitials: 'AP',
      followUp: 0,
      message: 'Mohon bantu ingatkan Yoga Siregar soal kehadiran (50%) dan '
          'jadwalkan konsultasi sebelum Pertemuan 5.',
    ),
    DosenStudent(
      initials: 'LN',
      name: 'Lia Nasution',
      nim: '231402082',
      kelas: 'Kelas C',
      attendance: 67,
      score: 82,
      highRisk: false,
      hadir: 2,
      izin: 1,
      alpa: 1,
      meetings: [
        DosenMeeting(
            number: 5,
            module: _modul5,
            date: 'Sen, 05 Okt 2026 • 08:00–09:40 WIB',
            status: MeetingStatus.upcoming),
        DosenMeeting(
            number: 4,
            module: _modul4,
            date: 'Sen, 28 Sep 2026 • 08:00–09:40 WIB',
            status: MeetingStatus.hadir,
            noteIcon: 'location',
            note: 'Tercatat 08:05 WIB melalui tombol hadir & lokasi'),
        DosenMeeting(
            number: 3,
            module: _modul3,
            date: 'Sen, 21 Sep 2026 • 08:00–09:40 WIB',
            status: MeetingStatus.alpa,
            emphasis: true,
            noteIcon: 'cross',
            note: 'Tidak ada presensi tercatat'),
        DosenMeeting(
            number: 2,
            module: _modul2,
            date: 'Sen, 14 Sep 2026 • 08:00–09:40 WIB',
            status: MeetingStatus.izin,
            noteIcon: 'file',
            note: 'Izin sakit disetujui Andi Pratama'),
        DosenMeeting(
            number: 1,
            module: _modul1,
            date: 'Sen, 07 Sep 2026 • 08:00–09:40 WIB',
            status: MeetingStatus.hadir,
            noteIcon: 'qrcode',
            note: 'Tercatat 07:55 WIB melalui pindai QR'),
      ],
      asisten: 'Andi Pratama',
      asistenInitials: 'AP',
      followUp: 0,
      message: 'Mohon bantu ingatkan Lia Nasution soal kehadiran (67%) agar '
          'tidak tertinggal materi Modul 5.',
    ),
    DosenStudent(
      initials: 'BT',
      name: 'Bagas Tarigan',
      nim: '231402091',
      kelas: 'Kelas A',
      attendance: 92,
      score: 61,
      highRisk: false,
      hadir: 4,
      izin: 0,
      alpa: 0,
      meetings: [
        DosenMeeting(
            number: 5,
            module: _modul5,
            date: 'Sel, 06 Okt 2026 • 10:00–11:40 WIB',
            status: MeetingStatus.upcoming),
        DosenMeeting(
            number: 4,
            module: _modul4,
            date: 'Sel, 29 Sep 2026 • 10:00–11:40 WIB',
            status: MeetingStatus.hadir,
            noteIcon: 'qrcode',
            note: 'Tercatat 09:57 WIB melalui pindai QR'),
        DosenMeeting(
            number: 3,
            module: _modul3,
            date: 'Sel, 22 Sep 2026 • 10:00–11:40 WIB',
            status: MeetingStatus.hadir,
            noteIcon: 'location',
            note: 'Tercatat 09:59 WIB melalui tombol hadir & lokasi'),
        DosenMeeting(
            number: 2,
            module: _modul2,
            date: 'Sel, 15 Sep 2026 • 10:00–11:40 WIB',
            status: MeetingStatus.terlambat,
            noteIcon: 'clock',
            note: 'Tercatat 10:31 WIB • terlambat 31 menit'),
        DosenMeeting(
            number: 1,
            module: _modul1,
            date: 'Sel, 08 Sep 2026 • 10:00–11:40 WIB',
            status: MeetingStatus.hadir,
            noteIcon: 'qrcode',
            note: 'Tercatat 09:55 WIB melalui pindai QR'),
      ],
      asisten: 'Feri Gunawan',
      asistenInitials: 'FG',
      followUp: 2,
      message: 'Mohon siapkan tugas remedial untuk Bagas Tarigan karena '
          'rata-rata nilainya 61, di bawah batas 70.',
    ),
  ];

  /// Lima baris yang tampil di halaman Validasi Nilai Akhir.
  final List<DosenGrade> previewGrades = const [
    DosenGrade('Rina Novita', '231402045', '88', '100%', '90', 'A'),
    DosenGrade('Dimas Saputra', '231402051', '82', '92%', '84', 'B+'),
    DosenGrade('Maya Hutagalung', '231402063', '91', '100%', '93', 'A'),
    DosenGrade('Yoga Siregar', '231402070', '76', '83%', '78', 'B'),
    DosenGrade('Lia Nasution', '231402082', '85', '92%', '86', 'A-'),
  ];

  /// Seluruh 24 praktikan Kelas C (halaman Rekap Nilai Akhir).
  final List<DosenGrade> grades = const [
    DosenGrade('Ahmad Fauzi', '231402003', '84', '100%', '88', 'A'),
    DosenGrade('Bella Sitompul', '231402007', '90', '100%', '91', 'A'),
    DosenGrade('Citra Lestari', '231402011', '79', '92%', '81', 'B+'),
    DosenGrade('Daniel Simanjuntak', '231402014', '85', '92%', '87', 'A-'),
    DosenGrade('Elisa Purba', '231402018', '92', '100%', '94', 'A'),
    DosenGrade('Fikri Ramadhan', '231402022', '74', '83%', '76', 'B'),
    DosenGrade('Grace Hutapea', '231402025', '88', '100%', '89', 'A'),
    DosenGrade('Hendra Ginting', '231402029', '81', '92%', '84', 'B+'),
    DosenGrade('Indah Permata', '231402036', '86', '100%', '87', 'A-'),
    DosenGrade('Joshua Sembiring', '231402040', '77', '83%', '79', 'B'),
    DosenGrade('Rina Novita', '231402045', '88', '100%', '90', 'A'),
    DosenGrade('Kevin Manurung', '231402048', '83', '92%', '84', 'B+'),
    DosenGrade('Dimas Saputra', '231402051', '82', '92%', '84', 'B+'),
    DosenGrade('Larasati Putri', '231402055', '89', '100%', '90', 'A'),
    DosenGrade('Michael Tambunan', '231402059', '72', '75%', '74', 'B-'),
    DosenGrade('Maya Hutagalung', '231402063', '91', '100%', '93', 'A'),
    DosenGrade('Nadia Harahap', '231402066', '87', '92%', '88', 'A'),
    DosenGrade('Yoga Siregar', '231402070', '76', '83%', '78', 'B'),
    DosenGrade('Omar Lubis', '231402074', '80', '92%', '81', 'B+'),
    DosenGrade('Putri Damanik', '231402078', '91', '100%', '92', 'A'),
    DosenGrade('Lia Nasution', '231402082', '85', '92%', '86', 'A-'),
    DosenGrade('Rafi Sinaga', '231402086', '52', '58%', '55', 'D'),
    DosenGrade('Sarah Siahaan', '231402089', '84', '92%', '85', 'A-'),
    DosenGrade('Teguh Situmorang', '231402094', '82', '92%', '85', 'A-'),
  ];

  final List<DosenDownload> downloads = [
    const DosenDownload('September 2026', 'Rekap_PemMobile_C.xlsx',
        '21 Sep 2026 • 248 KB', true),
    const DosenDownload('September 2026', 'Kehadiran_PemMobile_A.xlsx',
        '18 Sep 2026 • 196 KB', true),
    const DosenDownload('September 2026', 'Nilai_BasisData_B.pdf',
        '14 Sep 2026 • 1,1 MB', false),
    const DosenDownload('September 2026', 'Kedisiplinan_Asisten_Sep.pdf',
        '10 Sep 2026 • 860 KB', false),
    const DosenDownload('September 2026', 'Rekap_BasisData_B.xlsx',
        '07 Sep 2026 • 231 KB', true),
    const DosenDownload('Agustus 2026', 'Nilai_PemMobile_A.pdf',
        '31 Agu 2026 • 1,0 MB', false),
  ];

  final List<DosenNotif> notifs = [
    DosenNotif(
      icon: 'triangle_alert',
      title: 'Peringatan dini: 3 praktikan',
      body: 'Kehadiran atau nilai di bawah batas minimal',
      time: '5 menit lalu',
      today: true,
      important: true,
      unread: true,
      target: DosenNotifTarget.peringatan,
    ),
    DosenNotif(
      icon: 'circle_check',
      title: 'Modul 4 selesai dinilai',
      body: 'Pemrograman Mobile Kelas C • Andi Pratama',
      time: '1 jam lalu',
      today: true,
      unread: true,
      target: DosenNotifTarget.validasi,
    ),
    DosenNotif(
      icon: 'chart_bar',
      title: 'Rekap kehadiran minggu ke-4',
      body: 'Rata-rata kehadiran 91% dari 4 grup praktikum',
      time: '2 jam lalu',
      today: true,
      unread: true,
      target: DosenNotifTarget.laporan,
    ),
    DosenNotif(
      icon: 'file',
      title: 'Laporan nilai Basis Data B',
      body: 'Nilai_BasisData_B.pdf • dari Sinta Marpaung',
      time: 'Kemarin, 15:10',
      today: false,
      target: DosenNotifTarget.laporan,
    ),
    DosenNotif(
      icon: 'clipboard',
      title: 'Nilai akhir siap divalidasi',
      body: 'Pemrograman Mobile Kelas C • Asisten Lab',
      time: 'Kemarin, 11:42',
      today: false,
      important: true,
      target: DosenNotifTarget.validasi,
    ),
    DosenNotif(
      icon: 'statistic_down',
      title: 'Kehadiran Yoga Siregar 50%',
      body: 'Risiko tinggi • Pemrograman Mobile Kelas C',
      time: 'Kemarin, 09:05',
      today: false,
      important: true,
      target: DosenNotifTarget.detailPeringatan,
    ),
  ];

  int get unreadCount => notifs.where((n) => n.unread).length;
}
