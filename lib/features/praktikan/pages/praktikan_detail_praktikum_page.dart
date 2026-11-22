import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Detail Praktikum-Praktikan (Kuis & Rating)".
///
/// Kartu judul, tab (Semua Pertemuan / Materi / Tugas), daftar pertemuan
/// dalam satu kartu (ketuk → Detail Pertemuan), lalu kartu Rating Asisten.
class PraktikanDetailPraktikumPage extends StatefulWidget {
  final PraktikanNav nav;
  final PrakCourse course;

  const PraktikanDetailPraktikumPage({
    super.key,
    required this.nav,
    required this.course,
  });

  @override
  State<PraktikanDetailPraktikumPage> createState() =>
      _PraktikanDetailPraktikumPageState();
}

class _PraktikanDetailPraktikumPageState
    extends State<PraktikanDetailPraktikumPage> {
  final PraktikumSyncService _sync = PraktikumSyncService.instance;

  /// 0 Semua Pertemuan, 1 Materi, 2 Tugas.
  int _tab = 0;

  static const List<String> _labels = ['Semua Pertemuan', 'Materi', 'Tugas'];
  static const List<double> _widths = [144, 86, 86];

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onSyncChanged);
    _sync.refreshFromBackend();
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncChanged);
    super.dispose();
  }

  void _onSyncChanged() {
    if (mounted) setState(() {});
  }

  PrakCourse get _course => widget.course.id.isNotEmpty
      ? _sync.courseById(widget.course.id)
      : widget.course;

  /// Pertemuan yang sudah berjalan (1–4), terbaru di atas.
  List<PrakMeeting> get _meetings =>
      _course.meetings.where((m) => m.number <= 4).toList();

  @override
  Widget build(BuildContext context) {
    final c = _course;
    final nav = widget.nav;
    final doneCount = _meetings.length;
    return LabSubPage(
      onLogoTap: nav.home,
      children: [
        _header(c, doneCount),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (var i = 0; i < _labels.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                _FixedTab(
                  label: _labels[i],
                  width: _widths[i],
                  selected: i == _tab,
                  onTap: () => setState(() => _tab = i),
                ),
              ],
            ],
          ),
        ),
        LabColumn(
          gap: 12,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _tab == 1
                        ? 'Daftar Materi'
                        : (_tab == 2 ? 'Daftar Tugas' : 'Daftar Pertemuan'),
                    style: labText(16, w: kBold),
                  ),
                ),
                Text('$doneCount dari 12',
                    style: labText(12, w: kMedium, c: LabColors.textGrey)),
              ],
            ),
            _ListCard(
              children: [
                for (final m in _meetings) _row(m),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabSectionTitle(icon: 'star', text: 'Rating Asisten'),
              right: LabTag.grey('$doneCount / 12 pertemuan'),
            ),
            Text(
              'Penilaian asisten dibuka setelah seluruh pertemuan praktikum '
              'selesai.',
              style: labText(12, c: ItlgColors.textMuted),
            ),
            LabOutlineButton(
              icon: 'star',
              label: 'Beri Rating Asisten',
              large: true,
              onTap: () => nav.penilaianAsisten(context, c),
            ),
          ],
        ),
      ],
    );
  }

  /// "Modul 4 • Figma Management" → "Modul 4 : Figma Management".
  static String _title(PrakMeeting m) => m.module.replaceFirst(' • ', ' : ');

  /// "Sen, 28 Sep 2026 • 13:00–14:40 WIB" → "Sen, 28 Sep 2026".
  static String _date(PrakMeeting m) => m.date.split(' • ').first;

  Widget _row(PrakMeeting m) {
    final nav = widget.nav;
    final c = _course;
    final userId = AuthController.instance.userIdentifier;
    final current = m.number == 4;
    final sub = _sync.submissionFor(c.id, m.number, userId);
    final taskDone = !current || (sub != null && sub.isSubmitted);
    final pending = _sync.pendingItemsCount(c.id, m.number, userId);

    switch (_tab) {
      case 1:
        final materiLabel = m.materiTitle.isNotEmpty
            ? m.materiTitle
            : (m.number == 4 ? c.materiTitle : 'Materi ${_title(m)}');
        return _MeetingRow(
          number: m.number,
          title: materiLabel,
          subtitle: 'PDF • diunggah asisten',
          trailing: Text('Lihat',
              style: labText(13, w: kSemiBold, c: ItlgColors.primary)),
          onTap: () => nav.detailMateri(context, course: c, meeting: m),
        );
      case 2:
        final tugasLabel = m.tugasTitle.isNotEmpty
            ? m.tugasTitle
            : (m.number == 4
                ? c.tugasTitle
                : 'Tugas ${m.number} • ${_title(m)}');
        final deadlineLabel = m.tugasDeadline.isNotEmpty
            ? m.tugasDeadline
            : (current ? c.tugasDeadline : _date(m));
        return _MeetingRow(
          number: m.number,
          title: tugasLabel,
          subtitle: deadlineLabel,
          trailing: taskDone
              ? const PrakSoftChip.done('Selesai')
              : const PrakSoftChip.warn('Belum dikumpulkan'),
          onTap: () => nav.editTugas(context, course: c, meeting: m),
        );
      default:
        return _MeetingRow(
          number: m.number,
          title: _title(m),
          subtitle: _date(m),
          trailing: pending > 0
              ? PrakSoftChip.warn('$pending belum selesai')
              : const PrakSoftChip.done('Selesai'),
          onTap: () => nav.detailPertemuan(context, c, m),
        );
    }
  }

  // Kartu judul (370 x 268).
  Widget _header(PrakCourse c, int doneCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 23, 13, 28),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ItlgShadows.outline,
      ),
      child: LabColumn(
        gap: 16,
        children: [
          LabColumn(
            gap: 6,
            children: [
              Text(c.kelas,
                  style: labText(16, w: kBold, c: ItlgColors.primaryDark)),
              Text('Praktikum \n${c.name}',
                  style: labText(22, w: kBold, c: Colors.black)),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  icon: 'm_person_small',
                  iconSize: 11,
                  iconColor: PrakColors.mutedRed,
                  label: 'Koordinator',
                  value: c.asisten,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: _InfoBox(
                  icon: 'm_clock',
                  iconSize: 12,
                  iconColor: ItlgColors.secondary,
                  label: 'Waktu',
                  value: c.jadwalDetail,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: LabColumn(
              gap: 4,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Pertemuan',
                          style: labText(16,
                              w: kBold, c: ItlgColors.textSubtle)),
                    ),
                    Text('$doneCount / 12',
                        style: labText(16, w: kBold, c: PrakColors.ink)),
                  ],
                ),
                const PrakTrack(
                    fraction: 227.1 / 341, color: ItlgColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu abu-abu berisi baris-baris bergaris pemisah (Figma: "Kartu Daftar
/// Pertemuan", padding 4/16).
class _ListCard extends StatelessWidget {
  final List<Widget> children;
  const _ListCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ItlgShadows.outline,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i < children.length - 1
                    ? const Border(bottom: BorderSide(color: LabColors.line))
                    : null,
              ),
              child: children[i],
            ),
        ],
      ),
    );
  }
}

/// Baris pertemuan: kotak nomor merah 36 px, judul Bold 14, keterangan
/// Regular 12, chip, chevron.
class _MeetingRow extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _MeetingRow({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ItlgColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$number',
                  style: labText(15, w: kBold, c: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LabColumn(
                gap: 4,
                children: [
                  Text(title, style: labText(14, w: kBold)),
                  Text(subtitle, style: labText(12, c: LabColors.textGrey)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
            const SizedBox(width: 12),
            const LabIcon('chevron_right', size: 16, color: LabColors.divider),
          ],
        ),
      ),
    );
  }
}

/// Kotak cekung 64 px: label kecil + nilai Bold 14.
class _InfoBox extends StatelessWidget {
  final String icon;
  final double iconSize;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoBox({
    required this.icon,
    required this.iconSize,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return InnerShadowBox(
      radius: 12,
      height: 64,
      color: ItlgColors.surfaceDark,
      padding: const EdgeInsets.fromLTRB(15, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LabIcon(icon, size: iconSize, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labText(12, w: kMedium, c: PrakColors.ink2)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labText(14, w: kBold)),
        ],
      ),
    );
  }
}

/// Tab lebar tetap (144 / 86 / 86) seperti di Figma.
class _FixedTab extends StatelessWidget {
  final String label;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  const _FixedTab({
    required this.label,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        constraints: BoxConstraints(minWidth: width),
        height: 39,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? ItlgColors.primary : LabColors.chipIdle,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? ItlgShadows.primary : ItlgShadows.outline,
        ),
        child: Text(
          label,
          maxLines: 1,
          style: labText(12,
              w: kBold,
              c: selected ? ItlgColors.surfaceWhite : ItlgColors.text),
        ),
      ),
    );
  }
}
