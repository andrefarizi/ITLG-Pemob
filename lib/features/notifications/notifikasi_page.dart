import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/itlg_ui.dart';
import '../gyro/gyro_page.dart';

/// Halaman Notifikasi (Figma: "05 Umum — Login & Notifikasi" > "Notifikasi").
/// Data masih contoh (belum ada backend).
class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

enum _Filter { semua, belumDibaca, penting }

class NotifikasiItem {
  final IconData icon;
  final String title;
  final String body;
  final String time;
  final String group; // "Hari Ini" / "Kemarin"
  final bool important;
  bool unread;

  NotifikasiItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.group,
    this.important = false,
    this.unread = false,
  });
}

/// Contoh data notifikasi (sesuai desain Figma).
List<NotifikasiItem> contohNotifikasi() => [
      NotifikasiItem(
        icon: Icons.schedule_rounded,
        title: 'Deadline Tugas 4 besok',
        body: 'Praktikum Desain Interaksi • kumpulkan sebelum Senin 29 Sep, '
            '10:30 WIB',
        time: '5 menit lalu',
        group: 'Hari Ini',
        important: true,
        unread: true,
      ),
      NotifikasiItem(
        icon: Icons.swap_horiz_rounded,
        title: 'Permintaan tukar shift',
        body: 'Feri Gunawan meminta bertukar shift Rabu 30 Sep dengan shift '
            'anda',
        time: '1 jam lalu',
        group: 'Hari Ini',
        unread: true,
      ),
      NotifikasiItem(
        icon: Icons.campaign_outlined,
        title: 'Perubahan jadwal praktikum',
        body: 'Pemrograman Mobile Kelas A pindah ke Lab Multimedia, Jumat '
            '02 Okt',
        time: '2 jam lalu',
        group: 'Hari Ini',
        important: true,
        unread: true,
      ),
      NotifikasiItem(
        icon: Icons.confirmation_number_outlined,
        title: 'Tiket #TK-0918 diperbarui',
        body: 'Status penanganan berubah menjadi In Progress',
        time: 'Kemarin, 15:10',
        group: 'Kemarin',
      ),
      NotifikasiItem(
        icon: Icons.meeting_room_outlined,
        title: 'Peminjaman ruangan disetujui',
        body: 'Lab Komputer 1 • Kamis 01 Okt, 13:00–14:40',
        time: 'Kemarin, 11:42',
        group: 'Kemarin',
      ),
      NotifikasiItem(
        icon: Icons.emoji_events_outlined,
        title: 'Nilai Modul 3 sudah keluar',
        body: 'Praktikum Pemrograman Mobile • 88 / 100 dengan catatan asisten',
        time: 'Kemarin, 09:05',
        group: 'Kemarin',
        important: true,
      ),
    ];

class _NotifikasiPageState extends State<NotifikasiPage> {
  final List<NotifikasiItem> _items = contohNotifikasi();
  _Filter _filter = _Filter.semua;

  int get _unreadCount => _items.where((n) => n.unread).length;

  List<NotifikasiItem> get _visible {
    switch (_filter) {
      case _Filter.semua:
        return _items;
      case _Filter.belumDibaca:
        return _items.where((n) => n.unread).toList();
      case _Filter.penting:
        return _items.where((n) => n.important).toList();
    }
  }

  void _markAllRead() {
    if (_unreadCount == 0) return;
    setState(() {
      for (final n in _items) {
        n.unread = false;
      }
    });
  }

  void _open(NotifikasiItem item) {
    setState(() => item.unread = false);
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<NotifikasiItem>>{};
    for (final n in _visible) {
      groups.putIfAbsent(n.group, () => []).add(n);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: ItlgColors.surfaceWhite,
        body: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 7, 16, 32),
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: ItlgBackButton(),
                  ),
                  const SizedBox(height: 10),
                  _buildHeading(),
                  const SizedBox(height: 24),
                  _buildTabs(),
                  const SizedBox(height: 24),
                  if (groups.isEmpty) _buildEmpty(),
                  for (final entry in groups.entries) ...[
                    Text(
                      entry.key,
                      style: ItlgText.style(
                        size: 12,
                        weight: FontWeight.w700,
                        color: ItlgColors.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final item in entry.value) ...[
                      _NotificationCard(item: item, onTap: () => _open(item)),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeading() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notifikasi',
                  style: ItlgText.style(
                      size: 22, weight: FontWeight.w700, color: Colors.black)),
              const SizedBox(height: 6),
              Text(
                _unreadCount == 0
                    ? 'Semua sudah dibaca'
                    : '$_unreadCount belum dibaca',
                style: ItlgText.style(color: Colors.black),
              ),
            ],
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _unreadCount == 0 ? null : _markAllRead,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              'Tandai Dibaca',
              style: ItlgText.style(
                size: 12,
                color: _unreadCount == 0
                    ? ItlgColors.textSubtle
                    : ItlgColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    String label(_Filter f) {
      switch (f) {
        case _Filter.semua:
          return 'Semua';
        case _Filter.belumDibaca:
          return 'Belum Dibaca ($_unreadCount)';
        case _Filter.penting:
          return 'Penting';
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final f in _Filter.values) ...[
            _TabChip(
              label: label(f),
              selected: f == _filter,
              onTap: () => setState(() => _filter = f),
            ),
            if (f != _Filter.values.last) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.notifications_off_outlined,
              size: 40, color: ItlgColors.textSubtle),
          const SizedBox(height: 10),
          Text(
            _filter == _Filter.belumDibaca
                ? 'Tidak ada notifikasi yang belum dibaca'
                : 'Belum ada notifikasi',
            style: ItlgText.style(size: 13, color: ItlgColors.textSubtle),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Komponen
// =============================================================================

/// Bar atas: logo ITLG Mobile + tombol "Tanya Gyro" (Figma "Frame 41").
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(19, top + 4, 18, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFCFC),
        boxShadow: ItlgShadows.outline,
      ),
      child: Row(
        children: [
          const ItlgLogoMark(size: 29),
          const SizedBox(width: 6.5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ITLG',
                style: ItlgText.style(
                  size: 14.8,
                  weight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  height: 1.2,
                ),
              ),
              Text('Mobile', style: ItlgText.style(size: 11.1, height: 1.15)),
            ],
          ),
          const Spacer(),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: ItlgShadows.outline,
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GyroPage()),
                ),
                child: SizedBox(
                  width: 146,
                  height: 38.12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/gyro/gyro_avatar.png',
                        width: 38.12,
                        height: 38.12,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.smart_toy_rounded,
                          size: 26,
                          color: ItlgColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 3.55),
                      Text(
                        'Tanya Gyro',
                        style: ItlgText.style(
                          size: 14.18,
                          weight: FontWeight.w700,
                          color: const Color(0xFF2F0303),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 39,
      decoration: BoxDecoration(
        color: selected ? ItlgColors.primary : const Color(0xFFFEFEFE),
        borderRadius: BorderRadius.circular(12),
        boxShadow: selected ? ItlgShadows.primary : ItlgShadows.outline,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: ItlgText.style(
                  size: 12,
                  weight: FontWeight.w700,
                  color: selected ? ItlgColors.surfaceWhite : ItlgColors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotifikasiItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: ItlgShadows.outline,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconTile(icon: item.icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: ItlgText.style(
                              size: 12, weight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        style: ItlgText.style(
                          size: 11,
                          weight: FontWeight.w500,
                          color: ItlgColors.textSubtle,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.time,
                        style: ItlgText.style(
                          size: 11,
                          weight: FontWeight.w500,
                          color: item.unread
                              ? ItlgColors.primary
                              : ItlgColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: item.unread ? 1 : 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: ItlgColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ubin ikon 36 px ala neumorphism (Figma "Icon Tile").
class _IconTile extends StatelessWidget {
  final IconData icon;
  const _IconTile({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0F3),
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
              offset: Offset(6, 6), blurRadius: 14, color: Color(0x73A3B1C6)),
          BoxShadow(
              offset: Offset(-6, -6),
              blurRadius: 11,
              color: Color(0xE6FFFFFF)),
        ],
      ),
      child: Icon(icon, size: 20, color: ItlgColors.primary),
    );
  }
}
