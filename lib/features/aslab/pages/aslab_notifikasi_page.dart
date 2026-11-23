import 'package:flutter/material.dart';

import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/notification_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';

/// Figma: "Notifikasi-Aslab".
class AslabNotifikasiPage extends StatefulWidget {
  final AslabNav nav;

  const AslabNotifikasiPage({super.key, required this.nav});

  @override
  State<AslabNotifikasiPage> createState() =>
      _AslabNotifikasiPageState();
}

class _AslabNotifikasiPageState extends State<AslabNotifikasiPage> {
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

  AslabNotifTarget _targetFor(String key) {
    switch (key) {
      case 'evaluasi':
        return AslabNotifTarget.evaluasi;
      case 'shiftJaga':
        return AslabNotifTarget.shiftJaga;
      case 'persetujuanIzin':
        return AslabNotifTarget.persetujuanIzin;
      case 'laporKendala':
        return AslabNotifTarget.laporKendala;
      case 'hasilKuis':
        return AslabNotifTarget.hasilKuis;
      default:
        return AslabNotifTarget.detailPresensi;
    }
  }

  void _markAllRead() {
    _sync.markAllRead('aslab');
    labToast(context, 'Semua notifikasi ditandai sudah dibaca');
  }

  void _open(AppNotificationRecord n) {
    _sync.markRead(n.id);
    if (n.title.toLowerCase().contains('arahan') ||
        n.title.toLowerCase().contains('tindak lanjut') ||
        n.body.toLowerCase().contains('arahan')) {
      final fu = NilaiSyncService.instance.allFollowUps.isNotEmpty
          ? NilaiSyncService.instance.allFollowUps.first
          : null;
      _showDosenFollowUpSheet(fu);
      return;
    }
    widget.nav.openNotif(context, _targetFor(n.targetKey));
  }

  /// Figma: "Sheet Arahan Tindak Lanjut Dosen-Aslab" (5816:3389).
  void _showDosenFollowUpSheet(AssistantFollowUpRecord? fu) {
    final student = fu?.studentName ?? 'Yoga Siregar';
    final msg = fu?.message ??
        'Mohon bantu ingatkan Yoga soal kehadiran dan jadwalkan konsultasi sebelum Pertemuan 6.';
    final type = fu?.followUpType ?? 'Kehadiran';
    labShowCustomSheet<void>(
      context,
      title: 'Arahan Tindak Lanjut Dosen',
      child: LabColumn(
        gap: 14,
        children: [
          LabPerson(
            initials: 'DC',
            name: 'Dr. Eng. Daniele Christian, M.Kom.',
            caption: 'Dikirim 05 Okt, 09:12 • Kategori $type',
          ),
          LabInsetBox(
            child: LabColumn(
              gap: 8,
              cross: CrossAxisAlignment.start,
              children: [
                Text('Praktikan: $student • Kehadiran 50%',
                    style: labText(12, w: kBold)),
                Text(msg, style: labText(12, c: ItlgColors.textMuted)),
              ],
            ),
          ),
          const PrakNotice.info(
            icon: 'info',
            text:
                'Dosen menerima notifikasi setelah arahan ini kamu tandai sudah ditindaklanjuti.',
          ),
          LabButtonPair(
            left: LabOutlineButton(
              icon: 'phone_outline',
              label: 'Hubungi Praktikan',
              onTap: () {
                Navigator.of(context).pop();
                labToast(context, 'Pesan pengingat dikirim ke $student');
              },
            ),
            right: LabPrimaryButton(
              icon: 'check',
              label: 'Tandai Ditindaklanjuti',
              onTap: () {
                if (fu != null) {
                  NilaiSyncService.instance.markFollowUpDone(
                    fu.id,
                    byAslab: AuthController.instance.userName,
                  );
                }
                Navigator.of(context).pop();
                labToast(
                    context, 'Arahan ditandai ditindaklanjuti & Dosen diberi tahu');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(String label, List<AppNotificationRecord> items) {
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
    return ListenableBuilder(
      listenable: _sync,
      builder: (context, _) {
        final all = _sync.forRole('aslab');
        final unread = _sync.unreadCountForRole('aslab');
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
                    child: Text('Tandai Semua Dibaca',
                        style: labText(12, w: kSemiBold, c: ItlgColors.primary)),
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
