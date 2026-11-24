import 'package:flutter/material.dart';

import '../../../core/services/file_upload_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/praktikan_store.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';

/// Halaman Tambah Materi.
class AslabTambahMateriPage extends StatefulWidget {
  final AslabNav nav;

  /// 0 modul, 1 tugas, 2 kuis.
  final int kind;

  /// ID praktikum yang dipilih (pemob, desain, adj, ml).
  final String courseId;

  /// Nomor pertemuan awal (opsional, misalnya saat membuka "Edit Kuis").
  final int? meetingNumber;

  const AslabTambahMateriPage({
    super.key,
    required this.nav,
    this.kind = 0,
    this.courseId = 'pemob',
    this.meetingNumber,
  });

  @override
  State<AslabTambahMateriPage> createState() => _AslabTambahMateriPageState();
}

class _AslabTambahMateriPageState extends State<AslabTambahMateriPage> {
  static const List<(String, String)> _jenis = [
    ('book_open', 'Modul'),
    ('clipboard', 'Tugas'),
    ('question', 'Kuis'),
  ];
  static const List<String> _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  static const List<String> _hari = [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min',
  ];

  /// (nomor, label pilihan, label tanggal yang disimpan, tanggal pertemuan).
  late final List<(int, String, String, DateTime?)> _pertemuanData =
      _buildPertemuan();
  List<String> get _pertemuan => [for (final p in _pertemuanData) p.$2];

  static DateTime? _parseTanggal(String s) {
    final m = RegExp(r'(\d{1,2}) ([A-Za-z]{3}) (\d{4})').firstMatch(s);
    if (m == null) return null;
    final mon = _bulan.indexOf(m.group(2)!);
    if (mon < 0) return null;
    return DateTime(int.parse(m.group(3)!), mon + 1, int.parse(m.group(1)!));
  }

  static String _fmtTanggal(DateTime d) =>
      '${_hari[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')} '
      '${_bulan[d.month - 1]} ${d.year}';

  /// Daftar Pertemuan 1–12 dari jadwal praktikum ini.
  List<(int, String, String, DateTime?)> _buildPertemuan() {
    final sync = PraktikumSyncService.instance;
    DateTime? base;
    var baseN = 0;
    var suffix = '';
    final out = <(int, String, String, DateTime?)>[];
    for (var n = 1; n <= 12; n++) {
      final m = sync.meetingFor(widget.courseId, n);
      if (m != null && m.date.isNotEmpty) {
        final d = _parseTanggal(m.date);
        if (d != null) {
          base = d;
          baseN = n;
          final i = m.date.indexOf(' • ');
          suffix = i == -1 ? '' : m.date.substring(i);
        }
        out.add((n, 'Pertemuan $n • ${m.date.split(' • ').first}', m.date, d));
      } else {
        final est = base?.add(Duration(days: 7 * (n - baseN)));
        out.add((
          n,
          est == null ? 'Pertemuan $n (baru)' : 'Pertemuan $n • ${_fmtTanggal(est)} (baru)',
          est == null ? 'Pertemuan $n' : '${_fmtTanggal(est)}$suffix',
          est,
        ));
      }
    }
    return out;
  }

  /// Pilihan batas pengumpulan dihitung dari tanggal pertemuan terpilih.
  List<String> get _deadline {
    final d = _pertemuanData[_pt].$4 ?? DateTime.now();
    String f(DateTime x, String jam) =>
        'Batas $jam WIB, ${x.day.toString().padLeft(2, '0')} ${_bulan[x.month - 1]} ${x.year}';
    final w1 = d.add(const Duration(days: 7));
    final w2 = d.add(const Duration(days: 14));
    return [f(w1, '10:30'), f(w1, '23:59'), f(w2, '10:30')];
  }

  static const List<String> _jenisKuis = ['Pre-Test', 'Post-Test', 'Kuis Harian'];
  static const List<String> _durasi = ['10 menit', '15 menit', '20 menit', '30 menit'];
  static const List<String> _letters = ['A', 'B', 'C', 'D'];

  late int _kind = widget.kind;
  int _pt = 4; // default Pertemuan 5
  int _dl = 0;
  int _jk = 0;
  int _dr = 0;
  int _kunci = 1;
  int _soal = 1;
  final List<(String, String)> _files = [];
  final List<PrakQuestion> _savedQuestions = [];

  final TextEditingController _nama = TextEditingController();
  final TextEditingController _desk = TextEditingController();
  final TextEditingController _tanya = TextEditingController();
  final List<TextEditingController> _opsi = [
    for (var i = 0; i < 4; i++) TextEditingController(),
  ];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final targetNum = widget.meetingNumber ??
        PraktikumSyncService.instance.courseById(widget.courseId).meetings.length;
    final idx = _pertemuanData.indexWhere((p) => p.$1 == targetNum);
    if (idx != -1) _pt = idx;
    if (widget.meetingNumber != null && widget.kind == 2) {
      final existing = PraktikumSyncService.instance
          .meetingFor(widget.courseId, targetNum);
      if (existing != null && existing.kuisTitle.isNotEmpty) {
        _nama.text = existing.kuisTitle;
      }
      if (existing != null && existing.description.isNotEmpty) {
        _desk.text = existing.description;
      }
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _desk.dispose();
    _tanya.dispose();
    for (final c in _opsi) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(String title, List<String> options, int current,
      ValueChanged<int> onPicked) async {
    final i = await prakShowPicker(context,
        title: title, options: options, selected: current);
    if (i != null && mounted) setState(() => onPicked(i));
  }

  Future<void> _addFile() async {
    final sub = const ['modul', 'tugas', 'kuis'][_kind];
    final picked = await FileUploadService.instance.pickAndUpload(
      folder: 'materi/${widget.courseId}/$sub',
    );
    if (picked == null || !mounted) return;
    if (!picked.uploadedToCloud) {
      labToast(context,
          'Gagal mengunggah ${picked.name}. Periksa koneksi lalu coba lagi.');
      return;
    }
    setState(() => _files.add((picked.name, picked.metaLabel)));
    labToast(context, '${picked.name} berhasil diunggah');
  }

  /// Simpan soal yang sedang diketik. Mengembalikan pesan kesalahan bila
  String? _appendCurrentQuestionIfValid() {
    final qText = _tanya.text.trim();
    final opts = [for (final o in _opsi) o.text.trim()];
    if (qText.isEmpty && opts.every((o) => o.isEmpty)) return null;
    if (qText.isEmpty) return 'Tulis pertanyaan Soal $_soal';
    if (opts.any((o) => o.isEmpty)) {
      return 'Isi keempat pilihan jawaban Soal $_soal';
    }
    _savedQuestions.add(PrakQuestion(qText, opts, _kunci));
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final meetingNum = _pertemuanData[_pt].$1;
    final dateLabel = _pertemuanData[_pt].$3;
    final kindLabel = const ['modul', 'tugas', 'kuis'][_kind];
    final title = _nama.text.trim();
    if (title.length < 5) {
      labToast(context, 'Isi nama $kindLabel (minimal 5 karakter)');
      return;
    }
    if (_kind == 0 && _files.isEmpty) {
      labToast(context, 'Unggah berkas modul terlebih dahulu');
      return;
    }
    if (_kind == 1 && _desk.text.trim().length < 10) {
      labToast(context, 'Tulis deskripsi/instruksi tugas (minimal 10 karakter)');
      return;
    }
    if (_kind == 2) {
      final err = _appendCurrentQuestionIfValid();
      if (err != null) {
        labToast(context, err);
        return;
      }
      if (_savedQuestions.isEmpty) {
        labToast(context, 'Tulis minimal 1 soal beserta 4 pilihan jawaban');
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await PraktikumSyncService.instance.upsertMeetingContentFromAslab(
        courseId: widget.courseId,
        meetingNumber: meetingNum,
        dateLabel: dateLabel,
        kind: _kind,
        title: title,
        description: _desk.text.trim(),
        fileName: _files.isNotEmpty ? _files.first.$1 : null,
        deadline: _kind == 1 ? _deadline[_dl] : null,
      );
      if (_kind == 2) {
        await PraktikumSyncService.instance.saveQuizQuestionsFromAslab(
          courseId: widget.courseId,
          meetingNumber: meetingNum,
          questions: _savedQuestions,
        );
      }
    } on StateError catch (e) {
      if (_kind == 2 && _savedQuestions.isNotEmpty) {
        // Soal terakhir dimasukkan lagi ke form saat dicoba ulang.
        _savedQuestions.removeLast();
      }
      if (mounted) {
        setState(() => _saving = false);
        labToast(context, e.message);
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).maybePop();
    labToast(
      context,
      const [
        'Modul disimpan & diterbitkan',
        'Tugas diterbitkan',
        'Kuis & soal diterbitkan'
      ][_kind],
    );
  }

  @override
  Widget build(BuildContext context) {
    final course = PraktikumSyncService.instance.courseById(widget.courseId);
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            LabOverline(
              overline: 'Praktikum ${course.name} • ${course.kelas}',
              title: 'Tambah Materi',
            ),
            PrakField(
              label: 'Jenis Materi',
              child: PrakOptionChips(
                options: _jenis,
                index: _kind,
                onChanged: (i) => setState(() {
                  _kind = i;
                  _files.clear();
                }),
              ),
            ),
            PrakField(
              label: 'Pertemuan',
              child: PrakSelect(
                value: _pertemuan[_pt],
                onTap: () =>
                    _pick('Pertemuan', _pertemuan, _pt, (i) => _pt = i),
              ),
            ),
          ],
        ),
        if (_kind == 0) _modulCard(),
        if (_kind == 1) _tugasCard(),
        if (_kind == 2) ...[_kuisCard(), _soalCard()],
        LabPrimaryButton(
          icon: _kind == 0 ? 'check' : 'send',
          label: const ['Simpan Modul', 'Terbitkan Tugas', 'Terbitkan Kuis']
              [_kind],
          large: true,
          onTap: _save,
        ),
      ],
    );
  }

  Widget _uploaded() {
    if (_files.isEmpty) return const SizedBox.shrink();
    return PrakField(
      label: 'Berkas Terunggah',
      child: LabColumn(
        gap: 8,
        children: [
          for (final f in _files)
            PrakFileItem(
              name: f.$1,
              meta: f.$2,
              action: 'delete_filled',
              onAction: () => setState(() => _files.remove(f)),
            ),
        ],
      ),
    );
  }

  Widget _modulCard() {
    return LabCard(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: LabSectionTitle(icon: 'book_open', text: 'Unggah Modul'),
        ),
        PrakField(
          label: 'Nama Modul',
          child: PrakInput(
              controller: _nama,
              hint: 'Contoh : Modul 5 - Navigasi & Routing'),
        ),
        PrakField(
          label: 'Deskripsi Modul :',
          child: PrakTextArea(
            controller: _desk,
            height: 96,
            hint: 'Tulis ringkasan materi yang dibahas...',
          ),
        ),
        PrakField(
          label: 'Berkas Modul',
          child: PrakUploadBox(
            title: 'Tarik atau Pilih Berkas Modul',
            subtitle: 'Format didukung PDF, PPTX, DOCX',
            onTap: _addFile,
          ),
        ),
        LabOutlineButton(
          icon: 'add_outline',
          label: 'Unggah Berkas',
          large: true,
          onTap: _addFile,
        ),
        if (_files.isNotEmpty) _uploaded(),
      ],
    );
  }

  Widget _tugasCard() {
    return LabCard(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: LabSectionTitle(icon: 'clipboard', text: 'Unggah Tugas'),
        ),
        PrakField(
          label: 'Nama Tugas',
          child: PrakInput(
              controller: _nama,
              hint: 'Contoh : Tugas 5 - Aplikasi Multi Halaman'),
        ),
        PrakField(
          label: 'Deskripsi Tugas :',
          child: PrakTextArea(
            controller: _desk,
            height: 96,
            hint: 'Tulis instruksi dan ketentuan pengerjaan...',
          ),
        ),
        PrakField(
          label: 'Berkas Tugas',
          child: PrakUploadBox(
            title: 'Tarik atau Pilih Berkas Tugas',
            subtitle: 'Format didukung PDF, DOCX, ZIP',
            onTap: _addFile,
          ),
        ),
        LabOutlineButton(
          icon: 'add_outline',
          label: 'Unggah Berkas',
          large: true,
          onTap: _addFile,
        ),
        if (_files.isNotEmpty) _uploaded(),
        PrakField(
          label: 'Deadline Pengumpulan',
          child: PrakSelect(
            value: _deadline[_dl],
            onTap: () => _pick(
                'Deadline Pengumpulan', _deadline, _dl, (i) => _dl = i),
          ),
        ),
      ],
    );
  }

  Widget _kuisCard() {
    return LabCard(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: LabSectionTitle(icon: 'question', text: 'Buat Kuis'),
        ),
        PrakField(
          label: 'Nama Kuis',
          child: PrakInput(
              controller: _nama, hint: 'Contoh : Pre-Test Modul 5'),
        ),
        PrakField(
          label: 'Deskripsi Kuis :',
          child: PrakTextArea(
            controller: _desk,
            height: 80,
            hint: 'Tulis petunjuk pengerjaan kuis...',
          ),
        ),
        PrakField(
          label: 'Jenis Kuis',
          child: PrakSelect(
            value: _jenisKuis[_jk],
            onTap: () =>
                _pick('Jenis Kuis', _jenisKuis, _jk, (i) => _jk = i),
          ),
        ),
        PrakField(
          label: 'Durasi Pengerjaan',
          child: PrakSelect(
            value: _durasi[_dr],
            onTap: () =>
                _pick('Durasi Pengerjaan', _durasi, _dr, (i) => _dr = i),
          ),
        ),
        PrakField(
          label: 'Berkas Soal (Opsional)',
          child: PrakUploadBox(
            title: 'Tarik atau Pilih Berkas Soal',
            subtitle: 'Impor soal dari XLSX atau CSV',
            onTap: _addFile,
          ),
        ),
        if (_files.isNotEmpty) _uploaded(),
      ],
    );
  }

  Widget _soalCard() {
    return LabCard(
      children: [
        PrakSpaceRow(
          left: LabSectionTitle(icon: 'clipboard', text: 'Soal $_soal'),
          right: const PrakSideLink('Pilihan Ganda'),
        ),
        PrakField(
          label: 'Pertanyaan :',
          child: PrakTextArea(controller: _tanya, height: 72),
        ),
        LabColumn(
          gap: 8,
          children: [
            for (var i = 0; i < 4; i++)
              _OptionRow(
                letter: _letters[i],
                controller: _opsi[i],
                isKey: i == _kunci,
                onSetKey: () => setState(() => _kunci = i),
              ),
          ],
        ),
        LabOutlineButton(
          icon: 'add_outline',
          label: 'Tambah Soal',
          large: true,
          onTap: () {
            _appendCurrentQuestionIfValid();
            setState(() {
              _soal++;
              _tanya.clear();
              for (final c in _opsi) {
                c.clear();
              }
              _kunci = 0;
            });
            labToast(context, 'Soal ${_soal - 1} disimpan (${_savedQuestions.length} soal)');
          },
        ),
      ],
    );
  }
}

/// Pilihan jawaban di editor soal. Ketuk huruf untuk menjadikannya kunci.
class _OptionRow extends StatelessWidget {
  final String letter;
  final TextEditingController controller;
  final bool isKey;
  final VoidCallback onSetKey;

  const _OptionRow({
    required this.letter,
    required this.controller,
    required this.isKey,
    required this.onSetKey,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
          horizontal: isKey ? 10.5 : 12, vertical: isKey ? 10 : 10),
      decoration: BoxDecoration(
        color: isKey ? LabColors.tagRedBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            isKey ? Border.all(color: ItlgColors.primary, width: 1.5) : null,
        boxShadow: isKey ? const [] : ItlgShadows.outline,
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSetKey,
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isKey ? ItlgColors.primary : LabColors.tile,
                shape: BoxShape.circle,
              ),
              child: Text(letter,
                  style: labText(12,
                      w: kBold, c: isKey ? Colors.white : ItlgColors.text)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              cursorColor: ItlgColors.primary,
              cursorWidth: 2.0,
              cursorRadius: const Radius.circular(2),
              style: labText(14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: 'Jawaban $letter',
                hintStyle: labText(14, c: ItlgColors.textSubtle),
              ),
            ),
          ),
          if (isKey) ...[
            const SizedBox(width: 10),
            const LabTag.red('Kunci Jawaban'),
          ],
        ],
      ),
    );
  }
}
