import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';

/// Figma: "Praktikum Saya-Aslab".
class AslabPraktikumSayaPage extends StatefulWidget {
  final AslabNav nav;
  const AslabPraktikumSayaPage({super.key, required this.nav});

  @override
  State<AslabPraktikumSayaPage> createState() => _AslabPraktikumSayaPageState();
}

class _AslabPraktikumSayaPageState extends State<AslabPraktikumSayaPage> {
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
    PraktikumSyncService.instance.addListener(_onSync);
    PraktikumSyncService.instance.refreshFromBackend();
  }

  void _onSync() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    PraktikumSyncService.instance.removeListener(_onSync);
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
    final courses = PraktikumSyncService.instance.aslabCourses
        .where((c) => q.isEmpty || c.name.toLowerCase().contains(q))
        .toList();
    if (_sort == 1) courses.sort((a, b) => a.name.compareTo(b.name));
    if (_sort == 2) courses.sort((a, b) => b.name.compareTo(a.name));
    return LabTabBody(
      children: [
        const LabTitle(
          title: 'Praktikum Saya',
          subtitle: 'Praktikum yang anda ampu Semester Ganjil 2026/2027',
        ),
        PrakSearchField(
          hint: 'Cari praktikum...',
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          onFilter: _openFilter,
          filterActive: _sort != 0,
        ),
        if (courses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('Praktikum tidak ditemukan.',
                textAlign: TextAlign.center,
                style: labText(12, c: ItlgColors.textSubtle)),
          )
        else
          AslabCourseGrid(
            courses: courses,
            thirdMeta: (c) => ('door', c.room),
            onTap: (c) => widget.nav.detailPraktikum(context, c),
          ),
      ],
    );
  }
}

/// Dua kartu praktikum 178 x 270 berdampingan (dipakai juga di Absensi).
class AslabCourseGrid extends StatelessWidget {
  final List<AslabCourse> courses;
  final (String, String) Function(AslabCourse) thirdMeta;
  final ValueChanged<AslabCourse> onTap;

  const AslabCourseGrid({
    super.key,
    required this.courses,
    required this.thirdMeta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LabColumn(
      gap: 14,
      children: [
        for (var row = 0; row < courses.length; row += 2)
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
                            third: thirdMeta(courses[row + col]),
                            onTap: () => onTap(courses[row + col]),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  final AslabCourse course;
  final (String, String) third;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.third,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 270),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: ItlgColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: ItlgShadows.outline,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LabIconTile('book_open'),
                LabTag.blue('Kelas C'),
              ],
            ),
            const SizedBox(height: 10),
            Text('Praktikum\n${course.name}',
                style: labText(16, w: kBold, c: Colors.black)),
            const SizedBox(height: 10),
            const PrakDivider(),
            const SizedBox(height: 10),
            LabColumn(
              gap: 6,
              children: [
                const LabMeta(icon: 'people_group', text: '24 Praktikan'),
                LabMeta(icon: 'clock', text: course.jadwal),
                LabMeta(icon: third.$1, text: third.$2),
              ],
            ),
            const SizedBox(height: 10),
            const LabProgress(
              label: 'Pertemuan',
              value: '4 / 12',
              fraction: 50 / 150,
            ),
          ],
        ),
      ),
    );
  }
}
