import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Halaman Daftar Praktikum Praktikan.
class PraktikanDaftarPraktikumPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanDaftarPraktikumPage({super.key, required this.nav});

  @override
  State<PraktikanDaftarPraktikumPage> createState() =>
      _PraktikanDaftarPraktikumPageState();
}

class _PraktikanDaftarPraktikumPageState
    extends State<PraktikanDaftarPraktikumPage> {
  final PraktikumSyncService _sync = PraktikumSyncService.instance;
  final TextEditingController _search = TextEditingController();
  String _query = '';

  static const List<String> _sorts = [
    'Urutan Default',
    'Nama A–Z',
    'Nama Z–A',
  ];
  int _sort = 0;

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onSyncChanged);
    _sync.refreshFromBackend();
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncChanged);
    _search.dispose();
    super.dispose();
  }

  void _onSyncChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openFilter() async {
    final i = await prakShowPicker(context,
        title: 'Urutkan Praktikum', options: _sorts, selected: _sort);
    if (i != null && mounted) setState(() => _sort = i);
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final courses = _sync.courses
        .where((c) => q.isEmpty || c.name.toLowerCase().contains(q))
        .toList();
    if (_sort == 1) courses.sort((a, b) => a.name.compareTo(b.name));
    if (_sort == 2) courses.sort((a, b) => b.name.compareTo(a.name));

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, labTopBarHeight(context) + 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Daftar Praktikum',
              style: labText(22, w: kBold, c: Colors.black)),
          const SizedBox(height: 6),
          Text('Daftar Praktikum Semester Ganjil 2026/2027',
              style: labText(14, c: Colors.black)),
          const SizedBox(height: 21),
          PrakSearchField(
            hint: 'Cari mata kuliah praktikum...',
            controller: _search,
            compact: true,
            onChanged: (v) => setState(() => _query = v),
            onFilter: _openFilter,
            filterActive: _sort != 0,
          ),
          const SizedBox(height: 16),
          if (courses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('Praktikum tidak ditemukan.',
                  textAlign: TextAlign.center,
                  style: labText(12, c: ItlgColors.textSubtle)),
            )
          else
            for (var row = 0; row < courses.length; row += 2) ...[
              if (row > 0) const SizedBox(height: 14),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var col = 0; col < 2; col++) ...[
                      if (col > 0) const SizedBox(width: 14),
                      Expanded(
                        child: (row + col) < courses.length
                            ? _CourseCard(
                                course: courses[row + col],
                                onTap: () => widget.nav.detailPraktikum(
                                    context, courses[row + col]),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

/// Kartu praktikum.
class _CourseCard extends StatelessWidget {
  final PrakCourse course;
  final VoidCallback onTap;
  const _CourseCard({required this.course, required this.onTap});

  Widget _meta(String icon, double size, String text, Color color) {
    return SizedBox(
      height: 14,
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Align(
              alignment: Alignment.centerLeft,
              child: LabIcon(icon, size: size, color: ItlgColors.textSubtle),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labText(11, w: kMedium, c: color)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hitung jumlah pertemuan dari data praktikum aktif
    final meetingCount = course.meetings.length.clamp(0, 12);
    final lastModul = course.meetings.isEmpty
        ? 0
        : course.meetings.map((m) => m.number).reduce((a, b) => a > b ? a : b);
    // Susunan informasi kartu praktikum
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 258),
        padding: const EdgeInsets.only(top: 18, bottom: 20),
        decoration: BoxDecoration(
          color: ItlgColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: ItlgShadows.outline,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const PrakBookTile(),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: PrakTag17('Modul $lastModul'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 6),
              child: Text('Praktikum \n${course.name}',
                  style: labText(16, w: kBold, c: Colors.black)),
            ),
            const SizedBox(height: 16),
            const Spacer(),
            Container(
              margin: const EdgeInsets.only(left: 15, right: 17),
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0x33A3B1C6), width: 1),
                ),
              ),
              child: LabColumn(
                gap: 6,
                children: [
                  _meta('m_person_small', 9.3, course.asisten, PrakColors.ink),
                  _meta('m_clock', 11.7, course.jadwalDaftar,
                      ItlgColors.textSubtle),
                  _meta('m_door', 10.5, course.room, ItlgColors.textSubtle),
                ],
              ),
            ),
            const SizedBox(height: 17),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LabColumn(
                gap: 4,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Pertemuan',
                            style: labText(10, c: ItlgColors.textSubtle)),
                      ),
                      Text('$meetingCount / 12',
                          style:
                              labText(10, w: kSemiBold, c: PrakColors.ink)),
                    ],
                  ),
                  PrakTrack(fraction: meetingCount / 12, color: LabColors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
