import 'package:flutter/material.dart';

import '../../../core/services/notification_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';

/// Figma: "Notifikasi-Praktikan".
class PraktikanNotifikasiPage extends StatefulWidget {
  final PraktikanNav nav;

  const PraktikanNotifikasiPage({super.key, required this.nav});

  @override
  State<PraktikanNotifikasiPage> createState() =>
      _PraktikanNotifikasiPageState();
}

class _PraktikanNotifikasiPageState extends State<PraktikanNotifikasiPage> {
  final NotificationSyncService _sync = NotificationSyncService.instance;

  /// 0 Semua, 1 Belum Dibaca, 2 Penting.
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _sync.refreshFromBackend();
  }

  bool _match(AppNotificationRecord n) {
    if (_tab == 1) return n.unread;
    if (_tab == 2) return n.important;
    return true;
  }

  PrakNotifTarget _targetFor(String key) {
    switch (key) {
      case 'editTugas':
        return PrakNotifTarget.editTugas;
      case 'presensi':
        return PrakNotifTarget.presensi;
      case 'detailAbsensi':
        return PrakNotifTarget.detailAbsensi;
      case 'kuis':
        return PrakNotifTarget.kuis;
      case 'detailNilai':
        return PrakNotifTarget.detailNilai;
      default:
        return PrakNotifTarget.pengumuman;
    }
  }

  void _markAllRead() {
    _sync.markAllRead('praktikan');
  }

  void _open(AppNotificationRecord n) {
    _sync.markRead(n.id);
    widget.nav.openNotif(context, _targetFor(n.targetKey));
  }

  Widget _group(String label, List<AppNotificationRecord> items) {
    return LabColumn(
      gap: 10,
      children: [
        Text(label, style: labText(12, w: kBold, c: ItlgColors.textSubtle)),
        // Figma: notifikasi per kelompok di dalam satu "Kartu Daftar".
        if (items.isNotEmpty)
          LabListCard(
            children: [
              for (final n in items)
                _NotifCard(notif: n, onTap: () => _open(n)),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sync,
      builder: (context, _) {
        final all = _sync.forRole('praktikan');
        final unread = _sync.unreadCountForRole('praktikan');
        final today = all.where((n) => n.isToday && _match(n)).toList();
        final earlier = all.where((n) => !n.isToday && _match(n)).toList();

        return LabSubPage(
          onLogoTap: widget.nav.home,
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
      },
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotificationRecord notif;
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
                    notif.relativeTime,
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
