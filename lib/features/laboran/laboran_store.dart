/// Data contoh untuk tampilan Laboran (belum terhubung ke backend). Isinya
/// sama dengan teks pada desain Figma "03 Laboran".

class LabTicket {
  final String id;
  final String icon;
  final String title;

  /// Judul di halaman detail (bisa memuat ganti baris seperti di Figma).
  final String detailTitle;
  final String place;
  final String summary;
  final String detail;
  final String reporter;
  final String initials;
  final String time;
  final String reportedAt;
  final String lokasi;
  final String kategori;
  final String photo;

  /// 0 = Reported, 1 = In Progress, 2 = Resolved.
  final int status;
  final String handlingNote;
  final int? deskNumber;

  const LabTicket({
    required this.id,
    required this.icon,
    required this.title,
    required this.detailTitle,
    required this.place,
    required this.summary,
    required this.detail,
    required this.reporter,
    required this.initials,
    required this.time,
    required this.reportedAt,
    required this.lokasi,
    required this.kategori,
    required this.photo,
    this.status = 0,
    this.handlingNote = '',
    this.deskNumber,
  });
}

enum RoomStatus { menunggu, disetujui, ditolak }

class RoomRequest {
  final String tag;
  final String lab;
  final String title;
  final String date;
  final String time;
  final String initials;
  final String name;
  final String role;
  final String reason;
  RoomStatus status;

  RoomRequest({
    required this.tag,
    required this.lab,
    required this.title,
    required this.date,
    required this.time,
    required this.initials,
    required this.name,
    required this.role,
    required this.reason,
    this.status = RoomStatus.menunggu,
  });
}

enum LabNotifTarget { tiket, ruangan, presensi, detailTiket, inventaris }

class LabNotif {
  final String icon;
  final String title;
  final String body;
  final String time;
  final bool today;
  final bool important;
  final LabNotifTarget target;
  bool unread;

  LabNotif({
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

/// Satu meja + PC di halaman Data Inventaris.
class LabDesk {
  final String name;
  final String spec;
  bool ready;

  LabDesk(this.name, this.spec, this.ready);
}

class LaboranStore {
  String accessCode = 'ITLG-4821';
  bool pushOn = true;

  static const String defaultSpec = 'Core i5-12400 • 16 GB • SSD 512 GB';

  /// Nama lab di Data Inventaris (urutan = urutan tab).
  static const List<String> inventoryLabs = [
    'Lab Komputer 1',
    'Lab Jaringan 2',
    'Lab Multimedia',
  ];

  /// Daftar meja & PC per lab (indeks sama dengan [inventoryLabs]).
  final List<List<LabDesk>> desks = [
    for (var i = 0; i < 3; i++)
      [
        LabDesk('Meja 01 • PC-01', defaultSpec, true),
        LabDesk('Meja 02 • PC-02', defaultSpec, true),
        LabDesk('Meja 12 • PC-12', defaultSpec, false),
      ],
  ];

  final List<LabTicket> tickets = const [
    LabTicket(
      id: '#TK-0921',
      icon: 'desktop_device',
      title: 'PC-12 tidak dapat menyala',
      detailTitle: 'PC-12 tidak dapat\nmenyala',
      place: 'Lab Komputer 1 • PC',
      summary: 'Layar tetap hitam setelah tombol power ditekan, lampu '
          'indikator tidak menyala.',
      detail: 'Layar tetap hitam setelah tombol power ditekan dan lampu '
          'indikator tidak menyala. Kabel daya sudah dicoba di stopkontak '
          'lain.',
      reporter: 'Andi Pratama',
      initials: 'AP',
      time: 'Hari ini, 08:15',
      reportedAt: 'Dilaporkan hari ini 08:15 WIB',
      lokasi: 'Lab Komputer 1',
      kategori: 'PC • Meja 12',
      photo: 'foto_pc12.jpg',
    ),
    LabTicket(
      id: '#TK-0920',
      icon: 'projector',
      title: 'Proyektor buram',
      detailTitle: 'Proyektor buram',
      place: 'Lab Jaringan 2 • Proyektor',
      summary: 'Tampilan proyektor tidak fokus dan warna pudar saat '
          'presentasi modul.',
      detail: 'Tampilan proyektor tidak fokus dan warna pudar saat '
          'presentasi modul.',
      reporter: 'Feri Gunawan',
      initials: 'FG',
      time: 'Hari ini, 08:02',
      reportedAt: 'Dilaporkan hari ini 08:02 WIB',
      lokasi: 'Lab Jaringan 2',
      kategori: 'Proyektor',
      photo: 'foto_proyektor.jpg',
    ),
    LabTicket(
      id: '#TK-0918',
      icon: 'wifi',
      title: 'Koneksi jaringan putus',
      detailTitle: 'Koneksi jaringan putus',
      place: 'Lab Multimedia • Jaringan',
      summary: 'Tiga PC di baris belakang tidak mendapat alamat IP.',
      detail: 'Tiga PC di baris belakang tidak mendapat alamat IP.',
      reporter: 'Sinta Marpaung',
      initials: 'SM',
      time: 'Kemarin, 14:20',
      reportedAt: 'Dilaporkan kemarin 14:20 WIB',
      lokasi: 'Lab Multimedia',
      kategori: 'Jaringan',
      photo: 'foto_jaringan.jpg',
    ),
  ];

  final List<RoomRequest> requests = [
    RoomRequest(
      tag: 'Praktikum Pengganti',
      lab: 'Lab Komputer 1',
      title: 'Praktikum Basis Data • Kelas B',
      date: 'Kam, 01 Okt 2026',
      time: '13:00–14:40',
      initials: 'SM',
      name: 'Sinta Marpaung',
      role: 'Asisten Lab',
      reason: 'Pengganti pertemuan 3 yang bertepatan dengan libur nasional.',
    ),
    RoomRequest(
      tag: 'Kelas Pengganti',
      lab: 'Lab Multimedia',
      title: 'Pemrograman Mobile • Kelas A',
      date: 'Jum, 02 Okt 2026',
      time: '10:00–11:40',
      initials: 'AP',
      name: 'Andi Pratama',
      role: 'Asisten Lab',
      reason: 'Kelas pengganti karena perbaikan proyektor di Lab Komputer 1.',
    ),
  ];

  final List<LabNotif> notifs = [
    LabNotif(
      icon: 'triangle_alert',
      title: 'Laporan kendala baru',
      body: 'Andi Pratama • Lab Komputer 1, PC-12 tidak menyala',
      time: '5 menit lalu',
      today: true,
      important: true,
      unread: true,
      target: LabNotifTarget.tiket,
    ),
    LabNotif(
      icon: 'door',
      title: 'Permintaan peminjaman ruangan',
      body: 'Sinta Marpaung • Lab Komputer 1, Kam 01 Okt',
      time: '1 jam lalu',
      today: true,
      unread: true,
      target: LabNotifTarget.ruangan,
    ),
    LabNotif(
      icon: 'person_cross',
      title: 'Asisten belum presensi',
      body: 'Shift Pagi • Lab Jaringan 2, mulai 08:00',
      time: '2 jam lalu',
      today: true,
      important: true,
      unread: true,
      target: LabNotifTarget.presensi,
    ),
    LabNotif(
      icon: 'ticket',
      title: 'Tiket #TK-0918 diperbarui',
      body: 'Status penanganan berubah menjadi In Progress',
      time: 'Kemarin, 15:10',
      today: false,
      target: LabNotifTarget.detailTiket,
    ),
    LabNotif(
      icon: 'wrench_outline',
      title: 'Kerusakan meja dilaporkan',
      body: 'Meja 14 • PC-14, Lab Komputer 1',
      time: 'Kemarin, 11:42',
      today: false,
      target: LabNotifTarget.tiket,
    ),
    LabNotif(
      icon: 'desktop_device',
      title: 'Pemeriksaan inventaris',
      body: 'Lab Komputer 1 • 3 PC perlu perawatan',
      time: 'Kemarin, 09:05',
      today: false,
      target: LabNotifTarget.inventaris,
    ),
  ];

  int get unreadCount => notifs.where((n) => n.unread).length;
}
