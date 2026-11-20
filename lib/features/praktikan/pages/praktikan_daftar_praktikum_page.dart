import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Daftar Praktikum-Praktikan (Navbar)".
class PraktikanDaftarPraktikumPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanDaftarPraktikumPage({super.key, required this.nav});

  @override
  State<PraktikanDaftarPraktikumPage> createState() =>
      _PraktikanDaftarPraktikumPageState();
}

class _PraktikanDaftarPraktikumPageState
    extends State<PraktikanDaftarPraktikumPage> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  static const List<String> _sorts = [
    'Urutan Default',
    'Nama A–Z',
    'Nama Z–A',
  ];
  int _sort = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openFilter() async {
    final i = await prakShowPicker(context,
        title: 'Urutkan Praktikum', options: _sorts, selected: _sort);
    if (i != null && mounted) setState(() => _sort = i);
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final courses = widget.nav.store.courses
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
            IntrinsicHeight(
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 2; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  Expanded(
                    child: i < courses.length
                        ? _CourseCard(
                            course: courses[i],
                            onTap: () => widget.nav
                                .detailPraktikum(context, courses[i]),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
            ),
        ],
      ),
    );
  }
}

/// Kartu praktikum 177 x 258 (posisi isi mengikuti Figma).
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
    // Di 402 px posisinya sama dengan Figma (info asisten mulai di y 134,
    // progress di bawah). Bila judul lebih panjang, kartu ikut memanjang
    // sehingga tidak ada teks yang bertumpuk.
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
                children: const [
                  PrakBookTile(),
                  Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: PrakTag17('Modul 4'),
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
                      Text('4 / 12',
                          style:
                              labText(10, w: kSemiBold, c: PrakColors.ink)),
                    ],
                  ),
                  const PrakTrack(fraction: 96.6 / 145, color: LabColors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
