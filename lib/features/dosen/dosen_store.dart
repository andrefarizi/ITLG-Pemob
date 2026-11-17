/// Data contoh untuk tampilan Dosen Pengampu (belum terhubung ke backend).
/// Isinya sama dengan teks pada desain Figma "04 Dosen Pengampu".

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

  const DosenStudent({
    required this.initials,
    required this.name,
    required this.nim,
    required this.kelas,
    required this.attendance,
    required this.score,
    required this.highRisk,
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
    'Pemrograman Mobile • TIF 3001 - Kelas A',
    'Basis Data • TIF 2104 - Kelas B',
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
    ),
    DosenStudent(
      initials: 'LN',
      name: 'Lia Nasution',
      nim: '231402082',
      kelas: 'Kelas C',
      attendance: 67,
      score: 82,
      highRisk: false,
    ),
    DosenStudent(
      initials: 'BT',
      name: 'Bagas Tarigan',
      nim: '231402091',
      kelas: 'Kelas A',
      attendance: 92,
      score: 61,
      highRisk: false,
    ),
  ];

  final List<DosenGrade> grades = const [
    DosenGrade('Rina Novita', '231402045', '88', '100%', '90', 'A'),
    DosenGrade('Dimas Saputra', '231402051', '82', '92%', '84', 'B+'),
    DosenGrade('Maya Hutagalung', '231402063', '91', '100%', '93', 'A'),
    DosenGrade('Yoga Siregar', '231402070', '76', '83%', '78', 'B'),
    DosenGrade('Lia Nasution', '231402082', '85', '92%', '86', 'A-'),
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
