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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final courses = widget.nav.store.courses
        .where((c) => q.isEmpty || c.name.toLowerCase().contains(q))
        .toList();

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 258,
        decoration: BoxDecoration(
          color: ItlgColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: ItlgShadows.outline,
        ),
        child: Stack(
          children: [
            Positioned(
              left: 12,
              right: 6,
              top: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PrakBookTile(),
                  const SizedBox(height: 6),
                  Text('Praktikum \n${course.name}',
                      style: labText(16, w: kBold, c: Colors.black)),
                ],
              ),
            ),
            const Positioned(right: 8, top: 23, child: PrakTag17('Modul 4')),
            Positioned(
              left: 15,
              right: 17,
              top: 134,
              child: Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0x33A3B1C6), width: 1),
                  ),
                ),
                child: LabColumn(
                  gap: 6,
                  children: [
                    _meta('m_person_small', 9.3, course.asisten,
                        PrakColors.ink),
                    _meta('m_clock', 11.7, course.jadwalDaftar,
                        ItlgColors.textSubtle),
                    _meta('m_door', 10.5, course.room, ItlgColors.textSubtle),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 213,
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
