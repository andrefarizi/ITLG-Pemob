import 'package:flutter/material.dart';

import '../../../core/services/file_upload_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/praktikan_store.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';

/// Figma: "Tambah Materi (Modul)", "Tambah Materi (Tugas)", dan "Tambah
/// Materi (Kuis)". Pilihan Jenis Materi berpindah di antara ketiganya.
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
  static const List<(int, String)> _pertemuanData = [
    (3, 'Pertemuan 3 • Sen, 21 Sep 2026'),
    (4, 'Pertemuan 4 • Sen, 28 Sep 2026'),
    (5, 'Pertemuan 5 • Sen, 05 Okt 2026'),
    (6, 'Pertemuan 6 • Sen, 12 Okt 2026'),
    (7, 'Pertemuan 7 • Sen, 19 Okt 2026'),
  ];
  static List<String> get _pertemuan => [for (final p in _pertemuanData) p.$2];
  static const List<String> _deadline = [
    'Sen, 12 Okt 2026 • 10:30 WIB',
    'Sen, 12 Okt 2026 • 23:59 WIB',
    'Sen, 19 Okt 2026 • 10:30 WIB',
  ];
  static const List<String> _jenisKuis = ['Pre-Test', 'Post-Test', 'Kuis Harian'];
  static const List<String> _durasi = ['10 menit', '15 menit', '20 menit', '30 menit'];
  static const List<String> _letters = ['A', 'B', 'C', 'D'];

  late int _kind = widget.kind;
  int _pt = 2; // default Pertemuan 5
  int _dl = 0;
  int _jk = 0;
  int _dr = 0;
  int _kunci = 1;
  int _soal = 1;
  final List<(String, String)> _files = [];
  final List<PrakQuestion> _savedQuestions = [];

  final TextEditingController _nama = TextEditingController();
  final TextEditingController _desk = TextEditingController();
  final TextEditingController _tanya = TextEditingController(
      text: 'Widget manakah yang membangun ulang tampilan ketika state '
          'berubah?');
  final List<TextEditingController> _opsi = [
    TextEditingController(text: 'StatelessWidget'),
    TextEditingController(text: 'StatefulWidget'),
    TextEditingController(text: 'InheritedWidget'),
    TextEditingController(text: 'Container'),
  ];

  @override
  void initState() {
    super.initState();
    final targetNum = widget.meetingNumber ?? 5;
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
    setState(() => _files.add((picked.name, picked.metaLabel)));
    labToast(
      context,
      picked.uploadedToCloud
          ? '${picked.name} berhasil diunggah ke BE'
          : '${picked.name} dipilih dari perangkat',
    );
  }

  void _appendCurrentQuestionIfValid() {
    final qText = _tanya.text.trim();
    if (qText.isEmpty) return;
    final opts = [
      for (var i = 0; i < 4; i++)
        _opsi[i].text.trim().isNotEmpty
            ? _opsi[i].text.trim()
            : 'Pilihan ${_letters[i]}',
    ];
    _savedQuestions.add(PrakQuestion(qText, opts, _kunci));
  }

  Future<void> _save() async {
    final meetingNum = _pertemuanData[_pt].$1;
    final dateLabel = _pertemuanData[_pt].$2;
    final title = _nama.text.trim().isNotEmpty
        ? _nama.text.trim()
        : [
            'Modul $meetingNum : Materi Praktikum',
            'Tugas $meetingNum : Implementasi Praktikum',
            '${_jenisKuis[_jk]} Modul $meetingNum',
          ][_kind];
    if (_kind == 2) {
      _appendCurrentQuestionIfValid();
      if (_savedQuestions.isNotEmpty) {
        PraktikumSyncService.instance.saveQuizQuestionsFromAslab(
          courseId: widget.courseId,
          questions: _savedQuestions,
        );
      }
    }
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
    if (!mounted) return;
    Navigator.of(context).maybePop();
    labToast(
      context,
      const [
        'Modul disimpan & diterbitkan ke BE',
        'Tugas diterbitkan ke BE',
        'Kuis & soal diterbitkan ke BE'
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
              overline: 'Praktikum ${course.name} • Kelas C',
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
