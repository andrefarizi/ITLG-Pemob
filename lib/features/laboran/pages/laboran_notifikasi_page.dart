import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../laboran_store.dart';
import '../widgets/laboran_ui.dart';

/// Figma: "Notifikasi-Laboran".
class LaboranNotifikasiPage extends StatefulWidget {
  final LaboranStore store;
  final ValueChanged<LabNotifTarget> onOpen;
  final VoidCallback? onLogoTap;

  const LaboranNotifikasiPage({
    super.key,
    required this.store,
    required this.onOpen,
    this.onLogoTap,
  });

  @override
  State<LaboranNotifikasiPage> createState() => _LaboranNotifikasiPageState();
}

class _LaboranNotifikasiPageState extends State<LaboranNotifikasiPage> {
  /// 0 Semua, 1 Belum Dibaca, 2 Penting.
  int _tab = 0;

  bool _match(LabNotif n) {
    if (_tab == 1) return n.unread;
    if (_tab == 2) return n.important;
    return true;
  }

  void _markAllRead() {
    setState(() {
      for (final n in widget.store.notifs) {
        n.unread = false;
      }
    });
  }

  void _open(LabNotif n) {
    setState(() => n.unread = false);
    widget.onOpen(n.target);
  }

  Widget _group(String label, List<LabNotif> items) {
    return LabColumn(
      gap: 10,
      children: [
        Text(label, style: labText(12, w: kBold, c: ItlgColors.textSubtle)),
        for (final n in items) _NotifCard(notif: n, onTap: () => _open(n)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final unread = store.unreadCount;
    final today = store.notifs.where((n) => n.today && _match(n)).toList();
    final earlier = store.notifs.where((n) => !n.today && _match(n)).toList();

    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      children: [
        Row(
          children: [
            Expanded(
              child: LabColumn(
                gap: 6,
                children: [
                  Text('Notifikasi',
                      style: labText(22, w: kBold, c: Colors.black)),
                  Text(
                    unread == 0
                        ? 'Semua sudah dibaca'
                        : '$unread belum dibaca',
                    style: labText(14, c: Colors.black),
                  ),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _markAllRead,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Tandai Dibaca',
                    style: labText(12, c: ItlgColors.primary)),
              ),
            ),
          ],
        ),
        LabTabs(
          labels: ['Semua', 'Belum Dibaca ($unread)', 'Penting'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        if (today.isNotEmpty) _group('Hari Ini', today),
        if (earlier.isNotEmpty) _group('Kemarin', earlier),
        if (today.isEmpty && earlier.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Tidak ada notifikasi.',
              textAlign: TextAlign.center,
              style: labText(12, c: ItlgColors.textSubtle),
            ),
          ),
      ],
    );
  }
}

class _NotifCard extends StatelessWidget {
  final LabNotif notif;
  final VoidCallback onTap;
  const _NotifCard({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ItlgShadows.outline,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabIconTile(notif.icon),
            const SizedBox(width: 10),
            Expanded(
              child: LabColumn(
                gap: 4,
                children: [
                  Text(notif.title, style: labText(12, w: kBold)),
                  Text(notif.body,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                  Text(
                    notif.time,
                    style: labText(
                      11,
                      w: kMedium,
                      c: notif.unread
                          ? ItlgColors.primary
                          : ItlgColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
            if (notif.unread) ...[
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ItlgColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
