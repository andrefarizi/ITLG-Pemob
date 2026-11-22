import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/aslab/aslab_store.dart';
import '../../features/laboran/laboran_store.dart';
import '../../features/praktikan/praktikan_store.dart';
import 'supabase_service.dart';

/// Model terpadu satu meja + PC di sebuah laboratorium.
class LabDeskRecord {
  final String labName;
  final int deskNumber;
  final String pcCode;
  String spec;
  PrakDesk status;
  String? bookedByUserId;
  String? bookedByName;
  DateTime? bookedAt;

  LabDeskRecord({
    required this.labName,
    required this.deskNumber,
    required this.pcCode,
    required this.spec,
    required this.status,
    this.bookedByUserId,
    this.bookedByName,
    this.bookedAt,
  });

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
      pcCode: (json['pc_code'] as String?) ??
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

/// Model terpadu tiket laporan kendala/kerusakan yang tersinkron antar role
/// (Praktikan, Aslab, Laboran).
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

  /// 0 = Reported, 1 = In Progress, 2 = Resolved.
  int status;
  String handlingNote;
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
    this.status = 0,
    this.handlingNote = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get initials {
    final parts = reporterName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'US';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  String get formattedClock {
    final local = createdAt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String get formattedDateShort {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final local = createdAt.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    return '$dd ${months[local.month - 1]}';
  }

  String get timeLabel => 'Hari ini, $formattedClock';
  String get reportedAtLabel => 'Dilaporkan hari ini $formattedClock WIB';

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

  PrakReport toPrakReport() =>
      PrakReport(icon, title, '$labName • $formattedDateShort', status);

  AslabReport toAslabReport() =>
      AslabReport(icon, title, '$labName • $formattedDateShort', status);

  factory LabTicketRecord.fromJson(Map<String, dynamic> json) {
    return LabTicketRecord(
      ticketCode: (json['ticket_code'] as String?) ?? '#TK-0000',
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
      status: (json['status'] as num?)?.toInt() ?? 0,
      handlingNote: (json['handling_note'] as String?) ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : DateTime.now(),
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

/// Service pusat sinkronisasi Meja Praktikum, Booking, Inventaris, dan Tiket
/// Kerusakan antar peran (Praktikan ↔ Aslab ↔ Laboran) dengan backend Supabase
/// + Realtime serta fallback lokal otomatis bila tabel/jaringan belum aktif.
class LabDeskSyncService extends ChangeNotifier {
  static final LabDeskSyncService instance = LabDeskSyncService._internal();
  LabDeskSyncService._internal() {
    _seedDefaults();
  }

  static const String defaultLab = 'Lab Komputer 1';
  static const String currentSessionKey = 'PEMOB-PERTEMUAN-5';

  final Map<String, Map<int, LabDeskRecord>> _desksByLab = {};
  final List<LabTicketRecord> _tickets = [];

  /// Riwayat laporan bawaan Figma (ditampilkan bersama laporan baru dari DB).
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

    // 30 meja untuk Lab Komputer 1 sesuai Figma
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

    // Lab lain untuk Data Inventaris Laboran
    for (final lab in const ['Lab Jaringan 2', 'Lab Multimedia']) {
      _desksByLab[lab] = {
        1: LabDeskRecord(
          labName: lab,
          deskNumber: 1,
          pcCode: 'PC-01',
          spec: LaboranStore.defaultSpec,
          status: PrakDesk.available,
        ),
        2: LabDeskRecord(
          labName: lab,
          deskNumber: 2,
          pcCode: 'PC-02',
          spec: LaboranStore.defaultSpec,
          status: PrakDesk.available,
        ),
        12: LabDeskRecord(
          labName: lab,
          deskNumber: 12,
          pcCode: 'PC-12',
          spec: LaboranStore.defaultSpec,
          status: PrakDesk.broken,
        ),
      };
    }

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
              rec.status == PrakDesk.taken &&
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
          ..addAll(ticketRows
              .map((r) => LabTicketRecord.fromJson(Map<String, dynamic>.from(r))));
        _backendAvailable = true;
      }

      notifyListeners();
      debugPrint(
          '[LabDeskSync] Berhasil sinkronisasi dari Supabase (${deskRows.length} meja, ${ticketRows.length} tiket).');
    } catch (e) {
      _backendAvailable = false;
      debugPrint(
          '[LabDeskSync] Tabel Supabase belum tersedia / offline, menggunakan sinkronisasi memori bersama: $e');
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
          .subscribe();
    } catch (e) {
      debugPrint('[LabDeskSync] Gagal pasang realtime channel: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Getter untuk Praktikan, Aslab, dan Laboran
  // ---------------------------------------------------------------------------

  Map<int, PrakDesk> deskStatusMap({String labName = defaultLab}) {
    final map = _desksByLab[labName] ?? const {};
    return {
      for (var i = 1; i <= 30; i++) i: map[i]?.status ?? PrakDesk.taken,
    };
  }

  LabDeskRecord? deskRecord(int deskNumber, {String labName = defaultLab}) {
    return _desksByLab[labName]?[deskNumber];
  }

  int takenCount({String labName = defaultLab}) {
    return deskStatusMap(labName: labName)
        .values
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
      if (d.status == PrakDesk.taken && d.bookedByUserId == userKey) {
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
    // Di Lab Komputer 1 (30 meja), tampilkan semua meja terurut;
    // untuk tampilan ringkas atau pencarian semuanya sinkron.
    return list;
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
  LabTicketRecord? activeTicketForDesk(int deskNumber,
      {String labName = defaultLab}) {
    for (final t in _tickets) {
      if (t.labName == labName && t.deskNumber == deskNumber && t.status < 2) {
        return t;
      }
    }
    return null;
  }

  List<LabTicketRecord> get allTickets => List.unmodifiable(_tickets);

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
        .where((t) =>
            t.reporterRole == 'praktikan' &&
            (reporterId == null ||
                t.reporterId == null ||
                t.reporterId == reporterId))
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

  // ---------------------------------------------------------------------------
  // Aksi lintas role (menulis ke Supabase + update memori + notifyListeners)
  // ---------------------------------------------------------------------------

  /// Booking meja oleh Praktikan. Sinkron ke Praktikan Meja Kamu,
  /// Laboran Denah Meja, dan Supabase (`lab_desks` + `desk_bookings`).
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
          final freshStatus = LabDeskRecord.parseStatus(fresh['status'] as String?);
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

    // Jika user sebelumnya sudah booking meja lain di lab ini, lepaskan dulu
    final prevDeskNum = bookedDeskForUser(userKey, labName: labName);
    if (prevDeskNum != null && prevDeskNum != deskNumber) {
      final prev = labMap[prevDeskNum];
      if (prev != null && prev.status == PrakDesk.taken) {
        prev.status = PrakDesk.available;
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
        if (prevDeskNum != null && prevDeskNum != deskNumber) {
          await client.from('lab_desks').update({
            'status': 'available',
            'booked_by_user_id': null,
            'booked_by_name': null,
            'booked_at': null,
            'updated_at': now.toIso8601String(),
          }).eq('lab_name', labName).eq('desk_number', prevDeskNum);

          await client
              .from('desk_bookings')
              .update({'status': 'released'})
              .eq('lab_name', labName)
              .eq('session_key', currentSessionKey)
              .eq('user_identifier', userKey)
              .eq('status', 'active');
        }

        await client.from('lab_desks').upsert(
          {
            'lab_name': labName,
            'desk_number': deskNumber,
            'pc_code': target.pcCode,
            'spec': target.spec,
            'status': 'taken',
            'booked_by_user_id': userKey,
            'booked_by_name': userName,
            'booked_at': now.toIso8601String(),
            'session_key': currentSessionKey,
            'updated_at': now.toIso8601String(),
          },
          onConflict: 'lab_name,desk_number',
        );

        await client.from('desk_bookings').insert({
          'lab_name': labName,
          'desk_number': deskNumber,
          'session_key': currentSessionKey,
          'user_id': userKey,
          'user_identifier': userKey,
          'user_name': userName,
          'status': 'active',
          'booked_at': now.toIso8601String(),
        });

        synced = true;
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[LabDeskSync] Booking disimpan lokal (Supabase error): $e');
      }
    }

    return DeskBookingResult(success: true, syncedToBackend: synced);
  }

  /// Ubah kesiapan meja (Siap / Rusak) dari Inventaris Laboran.
  /// Sinkron langsung ke Denah Meja Laboran & Pilih Meja Praktikan.
  Future<void> setDeskReadiness({
    required String labName,
    required int deskNumber,
    required bool ready,
  }) async {
    final rec = _desksByLab[labName]?[deskNumber];
    if (rec == null) return;

    final now = DateTime.now();
    if (!ready) {
      if (rec.bookedByUserId != null &&
          _bookedDeskByUser[rec.bookedByUserId] == deskNumber) {
        _bookedDeskByUser.remove(rec.bookedByUserId);
      }
      rec.status = PrakDesk.broken;
      rec.bookedByUserId = null;
      rec.bookedByName = null;
      rec.bookedAt = null;
    } else {
      rec.status = PrakDesk.available;
    }
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('lab_desks').upsert(
          {
            'lab_name': labName,
            'desk_number': deskNumber,
            'pc_code': rec.pcCode,
            'spec': rec.spec,
            'status': LabDeskRecord.serializeStatus(rec.status),
            'booked_by_user_id': rec.bookedByUserId,
            'booked_by_name': rec.bookedByName,
            'booked_at': rec.bookedAt?.toIso8601String(),
            'updated_at': now.toIso8601String(),
          },
          onConflict: 'lab_name,desk_number',
        );
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
        await client.from('lab_desks').upsert(
          {
            'lab_name': labName,
            'desk_number': deskNumber,
            'pc_code': rec.pcCode,
            'spec': rec.spec,
            'status': LabDeskRecord.serializeStatus(rec.status),
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'lab_name,desk_number',
        );
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[LabDeskSync] Add device error: $e');
      }
    }
    return true;
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
    return '#TK-${(maxNum + 1).toString().padLeft(4, '0')}';
  }

  /// Buat laporan kerusakan dari Praktikan (halaman Laporkan Kerusakan Meja)
  /// atau Aslab (halaman Lapor Kendala). Langsung masuk ke Tiket Perbaikan &
  /// Denah Meja Laboran.
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
  }) async {
    final code = _nextTicketCode();
    final now = DateTime.now();
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
      status: 0,
      createdAt: now,
    );

    _tickets.insert(0, rec);
    notifyListeners();

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
          'status': 0,
          'handling_note': '',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[LabDeskSync] Create ticket disimpan lokal (Supabase error): $e');
      }
    }
    return rec;
  }

  /// Perbarui status tiket (0 Reported, 1 In Progress, 2 Resolved) oleh Laboran.
  /// Otomatis sinkron ke Praktikan ("Laporan Saya"), Aslab ("Laporan Saya"),
  /// Denah Meja, dan Data Inventaris (jika Resolved, meja rusak kembali Siap).
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

    target.status = status;
    target.handlingNote = handlingNote;

    // Jika tiket selesai (Resolved) dan terkait meja rusak, kembalikan jadi tersedia
    if (status == 2 && target.deskNumber != null) {
      final desk = _desksByLab[target.labName]?[target.deskNumber!];
      if (desk != null && desk.status == PrakDesk.broken) {
        desk.status = PrakDesk.available;
        await setDeskReadiness(
          labName: target.labName,
          deskNumber: target.deskNumber!,
          ready: true,
        );
      }
    }

    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('lab_tickets').update({
          'status': status,
          'handling_note': handlingNote,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('ticket_code', ticketCode);
        _backendAvailable = true;
      } catch (e) {
        debugPrint('[LabDeskSync] Update ticket error: $e');
      }
    }
  }
}
