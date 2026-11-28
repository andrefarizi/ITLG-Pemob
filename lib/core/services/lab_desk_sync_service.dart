import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/aslab/aslab_store.dart';
import '../../features/laboran/laboran_store.dart';
import '../../features/praktikan/praktikan_store.dart';
import 'notification_sync_service.dart';
import 'presensi_sync_service.dart';
import 'file_upload_service.dart';
import 'supabase_service.dart';

/// Model data meja dan PC laboratorium.
class LabDeskRecord {
  final String labName;
  final int deskNumber;
  final String pcCode;
  final int rowNum;
  final int colNum;
  String spec;
  PrakDesk status;
  String? bookedByUserId;
  String? bookedByName;
  DateTime? bookedAt;

  LabDeskRecord({
    required this.labName,
    required this.deskNumber,
    required this.pcCode,
    int? rowNum,
    int? colNum,
    required this.spec,
    required this.status,
    this.bookedByUserId,
    this.bookedByName,
    this.bookedAt,
  }) : rowNum = rowNum ?? ((deskNumber - 1) ~/ 5) + 1,
       colNum = colNum ?? ((deskNumber - 1) % 5) + 1;

  String get displayName =>
      'Meja ${deskNumber.toString().padLeft(2, '0')} • $pcCode';

  bool get isReady => status != PrakDesk.broken;

  static PrakDesk parseStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'available':
        return PrakDesk.available;
      case 'broken':
        return PrakDesk.broken;
      default:
        return PrakDesk.taken;
    }
  }

  static String serializeStatus(PrakDesk status) {
    switch (status) {
      case PrakDesk.available:
        return 'available';
      case PrakDesk.broken:
        return 'broken';
      case PrakDesk.taken:
        return 'taken';
    }
  }

  factory LabDeskRecord.fromJson(Map<String, dynamic> json) {
    final numVal = (json['desk_number'] as num?)?.toInt() ?? 1;
    return LabDeskRecord(
      labName: (json['lab_name'] as String?) ?? LabDeskSyncService.defaultLab,
      deskNumber: numVal,
      pcCode:
          (json['pc_code'] as String?) ??
          'PC-${numVal.toString().padLeft(2, '0')}',
      spec: (json['spec'] as String?) ?? LaboranStore.defaultSpec,
      status: parseStatus(json['status'] as String?),
      bookedByUserId: json['booked_by_user_id'] as String?,
      bookedByName: json['booked_by_name'] as String?,
      bookedAt: json['booked_at'] != null
          ? DateTime.tryParse(json['booked_at'].toString())
          : null,
    );
  }
}

/// Model data tiket laporan kendala laboratorium.
class LabTicketRecord {
  final String ticketCode;
  final String labName;
  final int? deskNumber;
  final String? pcCode;
  final String icon;
  final String category;
  final String title;
  final String description;
  final String? reporterId;
  final String reporterName;
  final String reporterRole;
  final String photoName;
  final String? photoUrl;

  /// 0 = Baru, 1 = Ditangani, 2 = Selesai.
  int status;
  String handlingNote;
  final List<Map<String, dynamic>> statusHistory;
  final DateTime createdAt;

  LabTicketRecord({
    required this.ticketCode,
    required this.labName,
    this.deskNumber,
    this.pcCode,
    required this.icon,
    required this.category,
    required this.title,
    required this.description,
    this.reporterId,
    required this.reporterName,
    required this.reporterRole,
    this.photoName = 'foto_kendala.jpg',
    this.photoUrl,
    this.status = 0,
    this.handlingNote = '',
    List<Map<String, dynamic>>? statusHistory,
    DateTime? createdAt,
  }) : statusHistory = statusHistory ?? <Map<String, dynamic>>[],
       createdAt = createdAt ?? DateTime.now();

  String get initials {
    final parts = reporterName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'US';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  /// Waktu laporan dalam WIB (UTC+7), tidak bergantung zona waktu HP.
  DateTime get _wib => createdAt.toUtc().add(const Duration(hours: 7));

  /// "Hari ini" / "Kemarin" / "23 Nov" sesuai tanggal laporan (WIB).
  String get _dayWord {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(_wib.year, _wib.month, _wib.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return formattedDateShort;
  }

  String get formattedClock {
    final local = _wib;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String get formattedDateShort {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final local = _wib;
    final dd = local.day.toString().padLeft(2, '0');
    return '$dd ${months[local.month - 1]}';
  }

  String get timeLabel => '$_dayWord, $formattedClock';
  String get reportedAtLabel {
    final w = _dayWord;
    final word = (w == 'Hari ini' || w == 'Kemarin') ? w.toLowerCase() : w;
    return 'Dilaporkan $word $formattedClock WIB';
  }

  String get placeLabel {
    final shortCat = category.split('•').first.trim();
    return '$labName • $shortCat';
  }

  LabTicket toLabTicket() {
    return LabTicket(
      id: ticketCode,
      icon: icon,
      title: title,
      detailTitle: title,
      place: placeLabel,
      summary: description,
      detail: description,
      reporter: reporterName,
      reporterRole: reporterRole,
      initials: initials,
      time: timeLabel,
      reportedAt: reportedAtLabel,
      lokasi: labName,
      kategori: category,
      photo: photoName,
      status: status,
      handlingNote: handlingNote,
      deskNumber: deskNumber,
    );
  }

  PrakReport toPrakReport() => PrakReport(
    icon,
    title,
    '$labName • $formattedDateShort',
    status,
    ticketCode: ticketCode,
    description: description,
    photoName: photoName,
    handlingNote: handlingNote,
  );

  AslabReport toAslabReport() =>
      AslabReport(icon, title, '$labName • $formattedDateShort', status);

  factory LabTicketRecord.fromJson(Map<String, dynamic> json) {
    final rawHist = (json['status_history_json'] as List?) ?? const [];
    // Daftarkan path Storage foto agar perangkat lain (Laboran) bisa
    final photoPath = json['photo_url'] as String?;
    if (photoPath != null &&
        photoPath.isNotEmpty &&
        !photoPath.startsWith('http')) {
      FileUploadService.instance
          .registerRemote((json['photo_name'] as String?) ?? '', photoPath);
    }
    return LabTicketRecord(
      ticketCode: (json['ticket_code'] as String?) ?? '#LK-0000',
      labName: (json['lab_name'] as String?) ?? LabDeskSyncService.defaultLab,
      deskNumber: (json['desk_number'] as num?)?.toInt(),
      pcCode: json['pc_code'] as String?,
      icon: (json['icon'] as String?) ?? 'desktop_device',
      category: (json['category'] as String?) ?? 'PC / Monitor',
      title: (json['title'] as String?) ?? 'Kendala Perangkat',
      description: (json['description'] as String?) ?? '',
      reporterId: json['reporter_id'] as String?,
      reporterName: (json['reporter_name'] as String?) ?? 'Pengguna',
      reporterRole: (json['reporter_role'] as String?) ?? 'praktikan',
      photoName: (json['photo_name'] as String?) ?? 'foto_kendala.jpg',
      photoUrl: json['photo_url'] as String?,
      status: (json['status'] as num?)?.toInt() ?? 0,
      handlingNote: (json['handling_note'] as String?) ?? '',
      statusHistory: rawHist
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : DateTime.now(),
    );
  }
}

/// Status kesiapan satu software di sebuah laboratorium (Inventaris Laboran).
class LabSoftwareRecord {
  final String labName;
  final String name;
  String version;
  String targetScope;
  final String icon;
  bool installed;

  LabSoftwareRecord({
    required this.labName,
    required this.name,
    this.version = '',
    this.targetScope = 'Semua PC',
    required this.icon,
    required this.installed,
  });

  factory LabSoftwareRecord.fromJson(Map<String, dynamic> json) {
    return LabSoftwareRecord(
      labName: (json['lab_name'] as String?) ?? LabDeskSyncService.defaultLab,
      name: (json['software_name'] as String?) ?? 'Software',
      version: (json['version'] as String?) ?? '',
      targetScope: (json['target_scope'] as String?) ?? 'Semua PC',
      icon: (json['icon'] as String?) ?? 'code_tags',
      installed: (json['is_installed'] as bool?) ?? true,
    );
  }
}

/// Hasil operasi booking meja.
class DeskBookingResult {
  final bool success;
  final String? errorMessage;
  final bool syncedToBackend;

  const DeskBookingResult({
    required this.success,
    this.errorMessage,
    this.syncedToBackend = false,
  });
}

/// Layanan sinkronisasi meja, inventaris, dan tiket kerusakan.
class LabDeskSyncService extends ChangeNotifier {
  static final LabDeskSyncService instance = LabDeskSyncService._internal();
  LabDeskSyncService._internal() {
    _seedDefaults();
  }

  /// Lab cadangan bila belum ada sesi presensi (data lokal/offline).
  static const String defaultLab = 'Lab Jaringan 1';

  /// Kunci sesi pemakaian meja = praktikum + pertemuan dari sesi presensi
  static String get currentSessionKey {
    final s = PresensiSyncService.instance.activeSession;
    return '${s.courseId.toUpperCase()}-PERTEMUAN-${s.meetingNumber}';
  }

  final Map<String, Map<int, LabDeskRecord>> _desksByLab = {};
  final Map<String, List<LabSoftwareRecord>> _softwareByLab = {};
  final List<LabTicketRecord> _tickets = [];

  /// Riwayat laporan bawaan (ditampilkan bersama laporan baru dari DB).
  final List<PrakReport> _seedPraktikanReports = const [
    PrakReport('wifi', 'Koneksi jaringan putus', 'Lab Jaringan 2 • 27 Sep', 1),
    PrakReport('projector', 'Proyektor buram', 'Lab Komputer 1 • 24 Sep', 2),
  ];

  final List<AslabReport> _seedAslabReports = const [
    AslabReport('wifi', 'Koneksi jaringan putus', 'Lab Jaringan 2 • 27 Sep', 1),
    AslabReport('projector', 'Proyektor buram', 'Lab Komputer 1 • 24 Sep', 2),
  ];

  /// Map userId/identifier -> nomor meja yang dibooking user tersebut di sesi ini.
  final Map<String, int> _bookedDeskByUser = {};

  RealtimeChannel? _channel;
  bool _initialized = false;
  bool _backendAvailable = false;
  bool get isBackendAvailable => _backendAvailable;

  void _seedDefaults() {
    _desksByLab.clear();
    const availableDesks = {3, 8, 14, 17, 25, 27, 30};

    // 30 meja untuk Lab Komputer 1
    _desksByLab[defaultLab] = {
      for (var i = 1; i <= 30; i++)
        i: LabDeskRecord(
          labName: defaultLab,
          deskNumber: i,
          pcCode: 'PC-${i.toString().padLeft(2, '0')}',
          spec: LaboranStore.defaultSpec,
          status: availableDesks.contains(i)
              ? PrakDesk.available
              : (i == 23 ? PrakDesk.broken : PrakDesk.taken),
          bookedByUserId: i == 12 ? '231402045' : null,
          bookedByName: i == 12
              ? 'Rina Novita'
              : (!availableDesks.contains(i) && i != 23
                    ? 'Praktikan Sesi Aktif'
                    : null),
        ),
    };

    // Lab lain (30 meja masing-masing) untuk Denah Meja & Data Inventaris Laboran
    final labConfigs = <String, ({int broken, int takenCount, String spec})>{
      'Lab Jaringan 1': (
        broken: 23,
        takenCount: 22,
        spec: LaboranStore.defaultSpec,
      ),
      'Lab Jaringan 2': (
        broken: 12,
        takenCount: 16,
        spec: LaboranStore.defaultSpec,
      ),
      'Lab Jaringan 3': (
        broken: 7,
        takenCount: 12,
        spec: 'Core i7-12700 • 16 GB • SSD 512 GB',
      ),
      'Lab Jaringan 4': (
        broken: 19,
        takenCount: 10,
        spec: 'Core i7-12700 • 16 GB • SSD 512 GB',
      ),
      'Lab Multimedia': (
        broken: 12,
        takenCount: 8,
        spec: LaboranStore.defaultSpec,
      ),
    };
    for (final entry in labConfigs.entries) {
      final lab = entry.key;
      final cfg = entry.value;
      _desksByLab[lab] = {
        for (var i = 1; i <= 30; i++)
          i: LabDeskRecord(
            labName: lab,
            deskNumber: i,
            pcCode: 'PC-${i.toString().padLeft(2, '0')}',
            spec: cfg.spec,
            status: i == cfg.broken
                ? PrakDesk.broken
                : (i <= cfg.takenCount ? PrakDesk.taken : PrakDesk.available),
            bookedByName: (i != cfg.broken && i <= cfg.takenCount)
                ? 'Praktikan Sesi Aktif'
                : null,
          ),
      };
    }

    _softwareByLab
      ..clear()
      ..addAll({
        defaultLab: [
          LabSoftwareRecord(
            labName: defaultLab,
            name: 'MySQL 8.0',
            icon: 'database_outline',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: defaultLab,
            name: 'PostgreSQL 16',
            icon: 'database_outline',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: defaultLab,
            name: 'Android Studio',
            icon: 'code_tags',
            installed: false,
          ),
          LabSoftwareRecord(
            labName: defaultLab,
            name: 'Visual Studio Code',
            icon: 'code_tags',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: defaultLab,
            name: 'Figma Desktop',
            icon: 'pencil',
            installed: true,
          ),
        ],
        'Lab Jaringan 2': [
          LabSoftwareRecord(
            labName: 'Lab Jaringan 2',
            name: 'Cisco Packet Tracer',
            icon: 'wifi',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: 'Lab Jaringan 2',
            name: 'Wireshark',
            icon: 'wifi',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: 'Lab Jaringan 2',
            name: 'PuTTY / OpenSSH',
            icon: 'code_tags',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: 'Lab Jaringan 2',
            name: 'VirtualBox',
            icon: 'desktop_device',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: 'Lab Jaringan 2',
            name: 'GNS3',
            icon: 'wifi',
            installed: false,
          ),
        ],
        'Lab Jaringan 3': [
          LabSoftwareRecord(
            labName: 'Lab Jaringan 3',
            name: 'Figma Desktop',
            icon: 'pencil',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: 'Lab Jaringan 3',
            name: 'Blender 4.2',
            icon: 'desktop_device',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: 'Lab Jaringan 3',
            name: 'Visual Studio Code',
            icon: 'code_tags',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: 'Lab Jaringan 3',
            name: 'Unity Hub',
            icon: 'code_tags',
            installed: false,
          ),
          LabSoftwareRecord(
            labName: 'Lab Jaringan 3',
            name: 'OBS Studio',
            icon: 'camera',
            installed: true,
          ),
        ],
        'Lab Jaringan 4': [
          LabSoftwareRecord(
            labName: 'Lab Jaringan 4',
            name: 'Python 3.12 & Anaconda',
            icon: 'code_tags',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: 'Lab Jaringan 4',
            name: 'JupyterLab',
            icon: 'code_tags',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: 'Lab Jaringan 4',
            name: 'Docker Desktop',
            icon: 'database_outline',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: 'Lab Jaringan 4',
            name: 'Visual Studio Code',
            icon: 'code_tags',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: 'Lab Jaringan 4',
            name: 'CUDA Toolkit 12',
            icon: 'desktop_device',
            installed: false,
          ),
        ],
        'Lab Multimedia': [
          LabSoftwareRecord(
            labName: 'Lab Multimedia',
            name: 'Figma Desktop',
            icon: 'pencil',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: 'Lab Multimedia',
            name: 'Blender 4.2',
            icon: 'desktop_device',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: 'Lab Multimedia',
            name: 'Visual Studio Code',
            icon: 'code_tags',
            installed: true,
          ),
          LabSoftwareRecord(
            labName: 'Lab Multimedia',
            name: 'Unity Hub',
            icon: 'code_tags',
            installed: false,
          ),
          LabSoftwareRecord(
            labName: 'Lab Multimedia',
            name: 'OBS Studio',
            icon: 'camera',
            installed: true,
          ),
        ],
      });

    _tickets
      ..clear()
      ..addAll([
        LabTicketRecord(
          ticketCode: '#TK-0921',
          labName: defaultLab,
          deskNumber: 12,
          pcCode: 'PC-12',
          icon: 'desktop_device',
          category: 'PC • Meja 12',
          title: 'PC-12 tidak dapat menyala',
          description:
              'Layar tetap hitam setelah tombol power ditekan dan lampu '
              'indikator tidak menyala. Kabel daya sudah dicoba di stopkontak '
              'lain.',
          reporterName: 'Andi Pratama',
          reporterRole: 'aslab',
          photoName: 'foto_pc12.jpg',
          status: 0,
          handlingNote: 'Power supply diganti, menunggu pengujian ulang.',
        ),
        LabTicketRecord(
          ticketCode: '#TK-0920',
          labName: 'Lab Jaringan 2',
          icon: 'projector',
          category: 'Proyektor',
          title: 'Proyektor buram',
          description:
              'Tampilan proyektor tidak fokus dan warna pudar saat '
              'presentasi modul.',
          reporterName: 'Feri Gunawan',
          reporterRole: 'aslab',
          photoName: 'foto_proyektor.jpg',
          status: 0,
        ),
        LabTicketRecord(
          ticketCode: '#TK-0918',
          labName: 'Lab Multimedia',
          icon: 'wifi',
          category: 'Jaringan',
          title: 'Koneksi jaringan putus',
          description: 'Tiga PC di baris belakang tidak mendapat alamat IP.',
          reporterName: 'Sinta Marpaung',
          reporterRole: 'aslab',
          photoName: 'foto_jaringan.jpg',
          status: 0,
        ),
      ]);
  }

  /// Inisialisasi sinkronisasi dari Supabase dan pasang listener Realtime.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refreshFromBackend();
    _subscribeRealtime();
  }

  /// Ambil data meja dan tiket terbaru dari Supabase.
  Future<void> refreshFromBackend() async {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    try {
      final deskRows = await client
          .from('lab_desks')
          .select()
          .order('desk_number', ascending: true);

      if (deskRows.isNotEmpty) {
        final loadedByLab = <String, Map<int, LabDeskRecord>>{};
        _bookedDeskByUser.clear();
        for (final row in deskRows) {
          final rec = LabDeskRecord.fromJson(Map<String, dynamic>.from(row));
          loadedByLab.putIfAbsent(rec.labName, () => {})[rec.deskNumber] = rec;
          if (rec.labName == defaultLab &&
              (rec.status == PrakDesk.taken || rec.status == PrakDesk.broken) &&
              rec.bookedByUserId != null &&
              rec.bookedByUserId!.isNotEmpty) {
            _bookedDeskByUser[rec.bookedByUserId!] = rec.deskNumber;
          }
        }
        // Gabungkan lab dari DB ke state (pastikan lab default selalu tersedia)
        for (final entry in loadedByLab.entries) {
          _desksByLab[entry.key] = entry.value;
        }
        _backendAvailable = true;
      }

      final ticketRows = await client
          .from('lab_tickets')
          .select()
          .order('created_at', ascending: false);

      if (ticketRows.isNotEmpty) {
        _tickets
          ..clear()
          ..addAll(
            ticketRows.map(
              (r) => LabTicketRecord.fromJson(Map<String, dynamic>.from(r)),
            ),
          );
        _backendAvailable = true;
      }

      try {
        final swRows = await client
            .from('lab_software')
            .select()
            .order('id', ascending: true);
        if (swRows.isNotEmpty) {
          final grouped = <String, List<LabSoftwareRecord>>{};
          for (final r in swRows) {
            final rec = LabSoftwareRecord.fromJson(
              Map<String, dynamic>.from(r),
            );
            grouped.putIfAbsent(rec.labName, () => []).add(rec);
          }
          for (final entry in grouped.entries) {
            _softwareByLab[entry.key] = entry.value;
          }
        }
      } catch (e) {
        debugPrint('[LabDeskSync] Tabel lab_software belum tersedia: $e');
      }

      notifyListeners();
      debugPrint(
        '[LabDeskSync] Berhasil sinkronisasi dari Supabase (${deskRows.length} meja, ${ticketRows.length} tiket).',
      );
    } catch (e) {
      _backendAvailable = false;
      debugPrint(
        '[LabDeskSync] Tabel Supabase belum tersedia / offline, menggunakan sinkronisasi memori bersama: $e',
      );
    }
  }

  void _subscribeRealtime() {
    final client = SupabaseService.instance.client;
    if (client == null) return;
    try {
      _channel?.unsubscribe();
      _channel = client
          .channel('itlg-lab-desk-sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'lab_desks',
            callback: (_) => refreshFromBackend(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'lab_tickets',
            callback: (_) => refreshFromBackend(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'lab_software',
            callback: (_) => refreshFromBackend(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('[LabDeskSync] Gagal pasang realtime channel: $e');
    }
  }

  // Getter untuk Praktikan, Aslab, dan Laboran

  Map<int, PrakDesk> deskStatusMap({String labName = defaultLab}) {
    final map = _desksByLab[labName] ?? const {};
    return {for (var i = 1; i <= 30; i++) i: map[i]?.status ?? PrakDesk.taken};
  }

  LabDeskRecord? deskRecord(int deskNumber, {String labName = defaultLab}) {
    return _desksByLab[labName]?[deskNumber];
  }

  int takenCount({String labName = defaultLab}) {
    return deskStatusMap(labName: labName).values
        .where((s) => s == PrakDesk.taken)
        .length;
  }

  int? bookedDeskForUser(String userKey, {String labName = defaultLab}) {
    if (labName == defaultLab && _bookedDeskByUser.containsKey(userKey)) {
      return _bookedDeskByUser[userKey];
    }
    final map = _desksByLab[labName];
    if (map == null) return null;
    for (final d in map.values) {
      if ((d.status == PrakDesk.taken || d.status == PrakDesk.broken) &&
          d.bookedByUserId == userKey) {
        return d.deskNumber;
      }
    }
    return null;
  }

  /// Cari meja pertama yang tersedia (untuk default pilihan jika 14 sudah terisi).
  int firstAvailableDesk({String labName = defaultLab, int preferred = 14}) {
    final map = deskStatusMap(labName: labName);
    if (map[preferred] == PrakDesk.available) return preferred;
    for (var i = 1; i <= 30; i++) {
      if (map[i] == PrakDesk.available) return i;
    }
    return preferred;
  }

  /// Daftar meja untuk halaman Data Inventaris Laboran.
  List<LabDeskRecord> inventoryDesks(String labName) {
    final map = _desksByLab[labName] ?? const {};
    final list = map.values.toList()
      ..sort((a, b) => a.deskNumber.compareTo(b.deskNumber));
    return list;
  }

  int get totalLabCount => _desksByLab.length;

  int get totalDeviceCount =>
      _desksByLab.values.fold<int>(0, (sum, m) => sum + m.length);

  List<LabSoftwareRecord> softwareForLab(String labName) {
    return List.unmodifiable(_softwareByLab[labName] ?? const []);
  }

  int softwareReadinessPct(String labName) {
    final list = _softwareByLab[labName] ?? const [];
    if (list.isEmpty) return 100;
    final ok = list.where((s) => s.installed).length;
    return ((ok * 100) / list.length).round();
  }

  /// Bottom sheet Tambah Software (Laboran).
  Future<void> addSoftware({
    required String labName,
    required String softwareName,
    required bool installed,
    String version = '',
    String targetScope = 'Semua PC',
    String icon = 'code_tags',
  }) async {
    final list = _softwareByLab.putIfAbsent(labName, () => []);
    list.add(
      LabSoftwareRecord(
        labName: labName,
        name: softwareName,
        version: version,
        targetScope: targetScope,
        icon: icon,
        installed: installed,
      ),
    );
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('lab_software').upsert({
          'lab_name': labName,
          'software_name': softwareName,
          'version': version,
          'target_scope': targetScope,
          'icon': icon,
          'is_installed': installed,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'lab_name,software_name');
      } catch (e) {
        debugPrint('[LabDeskSync] addSoftware error: $e');
        await refreshFromBackend();
        throw StateError(
            'Perubahan inventaris gagal disimpan. Periksa koneksi lalu coba lagi.');
      }
    }
  }

  /// Hapus software dari inventaris lab di memori & Supabase.
  Future<void> deleteSoftware({
    required String labName,
    required String softwareName,
  }) async {
    _softwareByLab[labName]?.removeWhere((s) => s.name == softwareName);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client
            .from('lab_software')
            .delete()
            .eq('lab_name', labName)
            .eq('software_name', softwareName);
      } catch (e) {
        debugPrint('[LabDeskSync] deleteSoftware error: $e');
        await refreshFromBackend();
        throw StateError(
            'Perubahan inventaris gagal disimpan. Periksa koneksi lalu coba lagi.');
      }
    }
  }

  /// Nomor meja yang memiliki tiket aktif (Reported / In Progress) di lab.
  Set<int> activeReportedDesks({String labName = defaultLab}) {
    final set = <int>{};
    for (final t in _tickets) {
      if (t.labName == labName && t.deskNumber != null && t.status < 2) {
        set.add(t.deskNumber!);
      }
    }
    return set;
  }

  /// Tiket aktif terbaru untuk nomor meja tertentu (jika ada).
  LabTicketRecord? activeTicketForDesk(
    int deskNumber, {
    String labName = defaultLab,
  }) {
    for (final t in _tickets) {
      if (t.labName == labName && t.deskNumber == deskNumber && t.status < 2) {
        return t;
      }
    }
    return null;
  }

  List<LabTicketRecord> get allTickets => List.unmodifiable(_tickets);

  LabTicketRecord? ticketByCode(String code) {
    for (final t in _tickets) {
      if (t.ticketCode == code) return t;
    }
    return null;
  }

  /// Daftar tiket mentah milik Aslab (untuk menampilkan detail & catatan live).
  List<LabTicketRecord> ticketRecordsForAslab() {
    return _tickets.where((t) => t.reporterRole == 'aslab').toList();
  }

  List<LabTicket> ticketsByStatus(int status) {
    return _tickets
        .where((t) => t.status == status)
        .map((t) => t.toLabTicket())
        .toList();
  }

  int ticketCountByStatus(int status) =>
      _tickets.where((t) => t.status == status).length;

  /// Laporan untuk Praktikan (laporan dari praktikan + riwayat bawaan).
  List<PrakReport> reportsForPraktikan({String? reporterId}) {
    final mine = _tickets
        .where(
          (t) =>
              t.reporterRole == 'praktikan' &&
              (reporterId == null ||
                  t.reporterId == null ||
                  t.reporterId == reporterId),
        )
        .map((t) => t.toPrakReport())
        .toList();
    return [...mine, ..._seedPraktikanReports];
  }

  /// Laporan untuk Aslab (laporan dari aslab + riwayat bawaan).
  List<AslabReport> reportsForAslab() {
    final aslabTickets = _tickets
        .where((t) => t.reporterRole == 'aslab')
        .map((t) => t.toAslabReport())
        .toList();
    return [...aslabTickets, ..._seedAslabReports];
  }

  // Aksi lintas role (menulis ke Supabase + update memori + notifyListeners)

  /// Booking meja oleh Praktikan. Sinkron ke Praktikan Meja Kamu
  Future<DeskBookingResult> bookDesk({
    String labName = defaultLab,
    required int deskNumber,
    required String userKey,
    required String userName,
  }) async {
    final labMap = _desksByLab.putIfAbsent(labName, () => {});
    final target = labMap[deskNumber];
    if (target == null) {
      return const DeskBookingResult(
        success: false,
        errorMessage: 'Meja tidak ditemukan',
      );
    }
    if (target.status == PrakDesk.broken) {
      return DeskBookingResult(
        success: false,
        errorMessage:
            'Meja ${deskNumber.toString().padLeft(2, '0')} sedang rusak',
      );
    }
    if (target.status == PrakDesk.taken && target.bookedByUserId != userKey) {
      return DeskBookingResult(
        success: false,
        errorMessage:
            'Meja ${deskNumber.toString().padLeft(2, '0')} sudah terisi',
      );
    }

    final client = SupabaseService.instance.client;
    bool synced = false;

    // Cek ulang status terbaru di Supabase untuk mencegah bentrok antar perangkat
    if (client != null) {
      try {
        final fresh = await client
            .from('lab_desks')
            .select()
            .eq('lab_name', labName)
            .eq('desk_number', deskNumber)
            .maybeSingle();

        if (fresh != null) {
          final freshStatus = LabDeskRecord.parseStatus(
            fresh['status'] as String?,
          );
          final freshUser = fresh['booked_by_user_id'] as String?;
          if (freshStatus == PrakDesk.broken) {
            target.status = PrakDesk.broken;
            notifyListeners();
            return DeskBookingResult(
              success: false,
              errorMessage:
                  'Meja ${deskNumber.toString().padLeft(2, '0')} baru saja ditandai rusak oleh Laboran',
            );
          }
          if (freshStatus == PrakDesk.taken && freshUser != userKey) {
            target.status = PrakDesk.taken;
            target.bookedByUserId = freshUser;
            target.bookedByName = fresh['booked_by_name'] as String?;
            notifyListeners();
            return DeskBookingResult(
              success: false,
              errorMessage:
                  'Meja ${deskNumber.toString().padLeft(2, '0')} baru saja dibooking praktikan lain',
            );
          }
        }
      } catch (e) {
        debugPrint('[LabDeskSync] Pre-check booking dilewati: $e');
      }
    }

    // Simpan state lama untuk rollback jika update atomik di DB mendeteksi bentrok
    final prevTargetStatus = target.status;
    final prevTargetUserId = target.bookedByUserId;
    final prevTargetUserName = target.bookedByName;
    final prevTargetBookedAt = target.bookedAt;

    // Jika user sebelumnya sudah booking meja lain di lab ini, lepaskan dulu
    final prevDeskNum = bookedDeskForUser(userKey, labName: labName);
    final prevWasBroken =
        prevDeskNum != null && labMap[prevDeskNum]?.status == PrakDesk.broken;
    if (prevDeskNum != null && prevDeskNum != deskNumber) {
      final prev = labMap[prevDeskNum];
      if (prev != null) {
        if (prev.status == PrakDesk.taken) {
          prev.status = PrakDesk.available;
        }
        prev.bookedByUserId = null;
        prev.bookedByName = null;
        prev.bookedAt = null;
      }
    }

    final now = DateTime.now();
    target.status = PrakDesk.taken;
    target.bookedByUserId = userKey;
    target.bookedByName = userName;
    target.bookedAt = now;
    if (labName == defaultLab) {
      _bookedDeskByUser[userKey] = deskNumber;
    }
    notifyListeners();

    if (client != null) {
      try {
        bool rpcHandled = false;
        try {
          final rpcRes = await client.rpc(
            'claim_or_move_desk',
            params: {
              'p_lab_name': labName,
              'p_desk_number': deskNumber,
              'p_user_id': userKey,
              'p_user_name': userName,
              'p_session_key': currentSessionKey,
            },
          );
          if (rpcRes is Map) {
            rpcHandled = true;
            final ok = rpcRes['success'] == true;
            if (!ok) {
              target.status = prevTargetStatus;
              target.bookedByUserId = prevTargetUserId;
              target.bookedByName = prevTargetUserName;
              target.bookedAt = prevTargetBookedAt;
              await refreshFromBackend();
              return DeskBookingResult(
                success: false,
                errorMessage:
                    (rpcRes['error'] ??
                            'Meja ${deskNumber.toString().padLeft(2, '0')} sudah ditempati praktikan lain')
                        .toString(),
              );
            }
            synced = true;
            _backendAvailable = true;
          }
        } catch (e) {
          debugPrint(
            '[LabDeskSync] RPC claim_or_move_desk fallback conditional update: $e',
          );
        }

        if (!rpcHandled) {
          // 2. Fallback: Update atomik kondisional di `lab_desks`
          final claimed = await client
              .from('lab_desks')
              .update({
                'status': 'taken',
                'booked_by_user_id': userKey,
                'booked_by_name': userName,
                'booked_at': now.toUtc().toIso8601String(),
                'session_key': currentSessionKey,
                'updated_at': now.toUtc().toIso8601String(),
              })
              .eq('lab_name', labName)
              .eq('desk_number', deskNumber)
              .or('status.eq.available,booked_by_user_id.eq.$userKey')
              .select();

          if (claimed.isEmpty) {
            final existingRow = await client
                .from('lab_desks')
                .select()
                .eq('lab_name', labName)
                .eq('desk_number', deskNumber)
                .maybeSingle();
            if (existingRow != null) {
              target.status = prevTargetStatus;
              target.bookedByUserId = prevTargetUserId;
              target.bookedByName = prevTargetUserName;
              target.bookedAt = prevTargetBookedAt;
              await refreshFromBackend();
              return DeskBookingResult(
                success: false,
                errorMessage:
                    'Meja ${deskNumber.toString().padLeft(2, '0')} baru saja ditempati praktikan lain',
              );
            }
            await client.from('lab_desks').upsert({
              'lab_name': labName,
              'desk_number': deskNumber,
              'pc_code': target.pcCode,
              'row_num': target.rowNum,
              'col_num': target.colNum,
              'spec': target.spec,
              'status': 'taken',
              'booked_by_user_id': userKey,
              'booked_by_name': userName,
              'booked_at': now.toUtc().toIso8601String(),
              'session_key': currentSessionKey,
              'updated_at': now.toUtc().toIso8601String(),
            }, onConflict: 'lab_name,desk_number');
          }

          if (prevDeskNum != null && prevDeskNum != deskNumber) {
            await client
                .from('lab_desks')
                .update({
                  'status': prevWasBroken ? 'broken' : 'available',
                  'booked_by_user_id': null,
                  'booked_by_name': null,
                  'booked_at': null,
                  'updated_at': now.toUtc().toIso8601String(),
                })
                .eq('lab_name', labName)
                .eq('desk_number', prevDeskNum);

            await client
                .from('desk_bookings')
                .update({'status': 'released'})
                .eq('lab_name', labName)
                .eq('session_key', currentSessionKey)
                .eq('user_identifier', userKey)
                .eq('status', 'active');
          }

          await client.from('desk_bookings').insert({
            'lab_name': labName,
            'desk_number': deskNumber,
            'session_key': currentSessionKey,
            'user_id': userKey,
            'user_identifier': userKey,
            'user_name': userName,
            'status': 'active',
            'booked_at': now.toUtc().toIso8601String(),
          });

          synced = true;
          _backendAvailable = true;
        }
      } catch (e) {
        debugPrint(
          '[LabDeskSync] Pemakaian meja disimpan lokal (Supabase error): $e',
        );
      }
    }

    // Satu praktikan hanya boleh memakai satu meja: lepaskan meja lain yang
    await _releaseOtherDesksOf(userKey, keepLab: labName, keepDesk: deskNumber);

    return DeskBookingResult(success: true, syncedToBackend: synced);
  }

  Future<void> _releaseOtherDesksOf(
    String userKey, {
    required String keepLab,
    required int keepDesk,
  }) async {
    final others = <(String, int)>{};
    _desksByLab.forEach((lab, desks) {
      desks.forEach((n, rec) {
        if (rec.bookedByUserId == userKey &&
            !(lab == keepLab && n == keepDesk)) {
          others.add((lab, n));
        }
      });
    });
    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        final rows = await client
            .from('lab_desks')
            .select('lab_name, desk_number')
            .eq('booked_by_user_id', userKey);
        for (final r in rows) {
          final lab = (r['lab_name'] ?? '').toString();
          final n = (r['desk_number'] as num?)?.toInt();
          if (n != null && !(lab == keepLab && n == keepDesk)) {
            others.add((lab, n));
          }
        }
      } catch (e) {
        debugPrint('[LabDeskSync] Gagal membaca meja lain milik $userKey: $e');
      }
    }
    for (final (lab, n) in others) {
      await releaseDesk(labName: lab, deskNumber: n, userKey: userKey);
    }
  }

  /// Lepaskan meja yang sedang dipakai Praktikan ("Akhiri Pemakaian Meja").
  Future<void> releaseDesk({
    String labName = defaultLab,
    required int deskNumber,
    required String userKey,
  }) async {
    final rec = _desksByLab[labName]?[deskNumber];
    if (rec != null &&
        (rec.bookedByUserId == userKey || rec.status == PrakDesk.taken)) {
      if (rec.status != PrakDesk.broken) {
        rec.status = PrakDesk.available;
      }
      rec.bookedByUserId = null;
      rec.bookedByName = null;
      rec.bookedAt = null;
    }
    if (labName == defaultLab && _bookedDeskByUser[userKey] == deskNumber) {
      _bookedDeskByUser.remove(userKey);
    }
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        final now = DateTime.now().toUtc().toIso8601String();
        // Kosongkan pemakai meja. Status hanya kembali "available" bila meja
        await client
            .from('lab_desks')
            .update({
              'booked_by_user_id': null,
              'booked_by_name': null,
              'booked_at': null,
              'updated_at': now,
            })
            .eq('lab_name', labName)
            .eq('desk_number', deskNumber);
        await client
            .from('lab_desks')
            .update({'status': 'available', 'updated_at': now})
            .eq('lab_name', labName)
            .eq('desk_number', deskNumber)
            .eq('status', 'taken');

        await client
            .from('desk_bookings')
            .update({'status': 'released'})
            .eq('lab_name', labName)
            .eq('desk_number', deskNumber)
            .eq('user_identifier', userKey)
            .eq('status', 'active');
      } catch (e) {
        debugPrint('[LabDeskSync] Gagal releaseDesk di Supabase: $e');
      }
    }
  }

  /// Kosongkan otomatis semua meja yang sedang ditempati saat sesi praktikum berakhir.
  Future<void> releaseSessionDesks({String labName = defaultLab}) async {
    final map = _desksByLab[labName];
    if (map != null) {
      for (final rec in map.values) {
        if (rec.status == PrakDesk.taken) {
          rec.status = PrakDesk.available;
          rec.bookedByUserId = null;
          rec.bookedByName = null;
          rec.bookedAt = null;
        }
      }
    }
    if (labName == defaultLab) {
      _bookedDeskByUser.clear();
    }
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        final now = DateTime.now().toUtc().toIso8601String();
        await client
            .from('lab_desks')
            .update({
              'status': 'available',
              'booked_by_user_id': null,
              'booked_by_name': null,
              'booked_at': null,
              'updated_at': now,
            })
            .eq('lab_name', labName)
            .eq('status', 'taken');

        await client
            .from('desk_bookings')
            .update({'status': 'released'})
            .eq('lab_name', labName)
            .eq('status', 'active');
      } catch (e) {
        debugPrint('[LabDeskSync] releaseSessionDesks error: $e');
      }
    }
  }

  /// Ubah kesiapan meja (Siap / Rusak) dari Inventaris Laboran atau
  Future<void> setDeskReadiness({
    required String labName,
    required int deskNumber,
    required bool ready,
    bool preserveBooker = false,
  }) async {
    final rec = _desksByLab[labName]?[deskNumber];
    if (rec == null) return;

    final now = DateTime.now();
    if (!ready) {
      rec.status = PrakDesk.broken;
      if (!preserveBooker) {
        if (rec.bookedByUserId != null &&
            _bookedDeskByUser[rec.bookedByUserId] == deskNumber) {
          _bookedDeskByUser.remove(rec.bookedByUserId);
        }
        rec.bookedByUserId = null;
        rec.bookedByName = null;
        rec.bookedAt = null;
      }
    } else {
      if (rec.bookedByUserId != null &&
          _bookedDeskByUser[rec.bookedByUserId] == deskNumber) {
        _bookedDeskByUser.remove(rec.bookedByUserId);
      }
      rec.status = PrakDesk.available;
      rec.bookedByUserId = null;
      rec.bookedByName = null;
      rec.bookedAt = null;
    }
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('lab_desks').upsert({
          'lab_name': labName,
          'desk_number': deskNumber,
          'pc_code': rec.pcCode,
          'spec': rec.spec,
          'status': LabDeskRecord.serializeStatus(rec.status),
          'booked_by_user_id': rec.bookedByUserId,
          'booked_by_name': rec.bookedByName,
          'booked_at': rec.bookedAt?.toUtc().toIso8601String(),
          'updated_at': now.toUtc().toIso8601String(),
        }, onConflict: 'lab_name,desk_number');
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[LabDeskSync] Update readiness error: $e');
      }
    }
  }

  /// Tambah perangkat meja baru dari Laboran Inventaris.
  Future<bool> addDeskDevice({
    required String labName,
    required int deskNumber,
    required String pcCode,
    required String spec,
    required bool ready,
  }) async {
    final labMap = _desksByLab.putIfAbsent(labName, () => {});
    if (labMap.containsKey(deskNumber)) return false;

    final rec = LabDeskRecord(
      labName: labName,
      deskNumber: deskNumber,
      pcCode: pcCode.toUpperCase(),
      spec: spec,
      status: ready ? PrakDesk.available : PrakDesk.broken,
    );
    labMap[deskNumber] = rec;
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('lab_desks').upsert({
          'lab_name': labName,
          'desk_number': deskNumber,
          'pc_code': rec.pcCode,
          'spec': rec.spec,
          'status': LabDeskRecord.serializeStatus(rec.status),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'lab_name,desk_number');
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[LabDeskSync] Add device error: $e');
        await refreshFromBackend();
        throw StateError(
            'Perubahan inventaris gagal disimpan. Periksa koneksi lalu coba lagi.');
      }
    }
    return true;
  }

  /// Perbarui kode PC, spesifikasi, dan status perangkat meja di Inventaris.
  Future<void> updateDeskDevice({
    required String labName,
    required int deskNumber,
    required String pcCode,
    required String spec,
    required bool ready,
  }) async {
    final labMap = _desksByLab.putIfAbsent(labName, () => {});
    final existing = labMap[deskNumber];
    final nextStatus = ready
        ? (existing?.status == PrakDesk.taken
              ? PrakDesk.taken
              : PrakDesk.available)
        : PrakDesk.broken;
    final updated = LabDeskRecord(
      labName: labName,
      deskNumber: deskNumber,
      pcCode: pcCode.toUpperCase(),
      spec: spec,
      status: nextStatus,
      bookedByUserId: ready ? existing?.bookedByUserId : null,
      bookedByName: ready ? existing?.bookedByName : null,
      bookedAt: ready ? existing?.bookedAt : null,
    );
    labMap[deskNumber] = updated;
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('lab_desks').upsert({
          'lab_name': labName,
          'desk_number': deskNumber,
          'pc_code': updated.pcCode,
          'spec': updated.spec,
          'status': LabDeskRecord.serializeStatus(updated.status),
          'booked_by_user_id': updated.bookedByUserId,
          'booked_by_name': updated.bookedByName,
          'booked_at': updated.bookedAt?.toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'lab_name,desk_number');
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[LabDeskSync] Update device error: $e');
        await refreshFromBackend();
        throw StateError(
            'Perubahan inventaris gagal disimpan. Periksa koneksi lalu coba lagi.');
      }
    }
  }

  /// Hapus perangkat meja dari Inventaris Laboran & Supabase `lab_desks`.
  Future<void> deleteDeskDevice({
    required String labName,
    required int deskNumber,
  }) async {
    final rec = _desksByLab[labName]?.remove(deskNumber);
    if (rec?.bookedByUserId != null &&
        _bookedDeskByUser[rec!.bookedByUserId] == deskNumber) {
      _bookedDeskByUser.remove(rec.bookedByUserId);
    }
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client
            .from('lab_desks')
            .delete()
            .eq('lab_name', labName)
            .eq('desk_number', deskNumber);
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[LabDeskSync] Delete device error: $e');
        await refreshFromBackend();
        throw StateError(
            'Perubahan inventaris gagal disimpan. Periksa koneksi lalu coba lagi.');
      }
    }
  }

  /// Ubah status terpasang/belum software pada suatu laboratorium di BE.
  Future<void> toggleSoftwareInstalled({
    required String labName,
    required String softwareName,
  }) async {
    final list = _softwareByLab[labName];
    if (list == null) return;
    LabSoftwareRecord? target;
    for (final s in list) {
      if (s.name == softwareName) {
        target = s;
        break;
      }
    }
    if (target == null) return;

    target.installed = !target.installed;
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('lab_software').upsert({
          'lab_name': labName,
          'software_name': target.name,
          'icon': target.icon,
          'is_installed': target.installed,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'lab_name,software_name');
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[LabDeskSync] Toggle software error: $e');
        await refreshFromBackend();
        throw StateError(
            'Perubahan inventaris gagal disimpan. Periksa koneksi lalu coba lagi.');
      }
    }
  }

  String _nextTicketCode() {
    var maxNum = 921;
    for (final t in _tickets) {
      final m = RegExp(r'(\d+)').firstMatch(t.ticketCode);
      if (m != null) {
        final v = int.tryParse(m.group(1)!) ?? 0;
        if (v > maxNum) maxNum = v;
      }
    }
    return '#LK-${(maxNum + 1).toString().padLeft(4, '0')}';
  }

  /// Buat laporan kerusakan dari Praktikan (halaman Laporkan Kerusakan Meja)
  Future<LabTicketRecord> createTicket({
    required String labName,
    int? deskNumber,
    String? pcCode,
    required String icon,
    required String category,
    required String title,
    required String description,
    String? reporterId,
    required String reporterName,
    required String reporterRole,
    String photoName = 'foto_kendala.jpg',
    String? photoPath,
  }) async {
    final code = _nextTicketCode();
    final now = DateTime.now();

    // Simpan perubahan ke database
    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('lab_tickets').insert({
          'ticket_code': code,
          'lab_name': labName,
          'desk_number': deskNumber,
          'pc_code': pcCode,
          'icon': icon,
          'category': category,
          'title': title,
          'description': description,
          'reporter_id': reporterId,
          'reporter_name': reporterName,
          'reporter_role': reporterRole,
          'photo_name': photoName,
          'photo_url': photoPath,
          'status': 0,
          'handling_note': '',
          'created_at': now.toUtc().toIso8601String(),
          'updated_at': now.toUtc().toIso8601String(),
        });
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[LabDeskSync] createTicket error: $e');
        throw StateError(
            'Laporan gagal dikirim. Periksa koneksi internet lalu coba lagi.');
      }
    }
    final rec = LabTicketRecord(
      ticketCode: code,
      labName: labName,
      deskNumber: deskNumber,
      pcCode: pcCode,
      icon: icon,
      category: category,
      title: title,
      description: description,
      reporterId: reporterId,
      reporterName: reporterName,
      reporterRole: reporterRole,
      photoName: photoName,
      photoUrl: photoPath,
      status: 0,
      createdAt: now,
    );

    _tickets.insert(0, rec);
    notifyListeners();

    // Otomatis tandai meja rusak di Denah Meja, Inventaris & Pilih Meja
    if (deskNumber != null) {
      await setDeskReadiness(
        labName: labName,
        deskNumber: deskNumber,
        ready: false,
        preserveBooker: reporterRole == 'praktikan',
      );
    }

    NotificationSyncService.instance.push(
      role: 'laboran',
      icon: 'wrench_outline',
      title: 'Laporan Kerusakan Baru ($code)',
      body: '$labName • $title (dilaporkan oleh $reporterName)',
      targetKey: 'tiket',
      courseId: null,
      important: true,
    );

    if (reporterRole == 'praktikan') {
      NotificationSyncService.instance.push(
        role: 'aslab',
        icon: 'triangle_alert',
        title: 'Kerusakan Meja Dilaporkan ($code)',
        body: '$labName • $title (oleh $reporterName)',
        targetKey: 'laporKendala',
        important: true,
      );
    }

    return rec;
  }

  /// Perbarui status tiket (0 Reported, 1 In Progress, 2 Resolved) oleh Laboran.
  Future<void> updateTicketStatus({
    required String ticketCode,
    required int status,
    required String handlingNote,
  }) async {
    LabTicketRecord? target;
    for (final t in _tickets) {
      if (t.ticketCode == ticketCode) {
        target = t;
        break;
      }
    }
    if (target == null) return;

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final statusLabel = status == 2
        ? 'Selesai'
        : (status == 1 ? 'Ditangani' : 'Baru');
    final newHistory = [
      ...target.statusHistory,
      {
        'status': statusLabel.toLowerCase(),
        'note': handlingNote,
        'updated_at': nowIso,
      },
    ];

    // Simpan perubahan ke database
    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client
            .from('lab_tickets')
            .update({
              'status': status,
              'handling_note': handlingNote,
              'status_history_json': newHistory,
              'updated_at': nowIso,
            })
            .eq('ticket_code', ticketCode);
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[LabDeskSync] Update ticket error: $e');
        throw StateError(
            'Status tiket gagal disimpan. Periksa koneksi lalu coba lagi.');
      }
    }

    target.status = status;
    target.handlingNote = handlingNote;
    target.statusHistory
      ..clear()
      ..addAll(newHistory);

    // Sinkronkan kondisi meja di Denah & Inventaris berdasarkan status tiket
    if (target.deskNumber != null) {
      final desk = _desksByLab[target.labName]?[target.deskNumber!];
      if (desk != null) {
        if (status == 2 && desk.status == PrakDesk.broken) {
          await setDeskReadiness(
            labName: target.labName,
            deskNumber: target.deskNumber!,
            ready: true,
          );
        } else if (status < 2 && desk.status != PrakDesk.broken) {
          await setDeskReadiness(
            labName: target.labName,
            deskNumber: target.deskNumber!,
            ready: false,
            preserveBooker: target.reporterRole == 'praktikan',
          );
        }
      }
    }

    notifyListeners();

    final noteSuffix = handlingNote.isNotEmpty ? ' • $handlingNote' : '';
    NotificationSyncService.instance.push(
      role: target.reporterRole == 'aslab' ? 'aslab' : 'praktikan',
      targetUser: target.reporterId,
      icon: status == 2 ? 'circle_check' : 'wrench_outline',
      title: 'Laporan $ticketCode: $statusLabel',
      body: '${target.title} (${target.labName})$noteSuffix',
      targetKey: target.reporterRole == 'aslab'
          ? 'laporKendala'
          : 'laporkanKerusakan',
      important: status == 2,
    );

    if (target.reporterRole == 'praktikan' && status == 2) {
      NotificationSyncService.instance.push(
        role: 'aslab',
        icon: 'circle_check',
        title: 'Perbaikan Meja Selesai ($ticketCode)',
        body:
            '${target.title} (${target.labName}) siap digunakan kembali$noteSuffix',
        targetKey: 'laporKendala',
        important: false,
      );
    }
  }
}
