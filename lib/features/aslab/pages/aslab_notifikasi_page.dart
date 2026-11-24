import 'package:flutter/material.dart';

import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/notification_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';

/// Halaman Notifikasi Asisten Lab.
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
      // Arahan yang dirujuk notifikasi ini (nama/NIM praktikan di isi pesan),
      // bukan selalu arahan pertama.
      final all = NilaiSyncService.instance.allFollowUps;
      AssistantFollowUpRecord? fu;
      for (final f in all) {
        if (n.body.contains(f.studentNim) || n.body.contains(f.studentName)) {
          fu = f;
          break;
        }
      }
      fu ??= all.isNotEmpty ? all.first : null;
      if (fu == null) {
        labToast(context, 'Arahan tindak lanjut tidak ditemukan', error: true);
        return;
      }
      _showDosenFollowUpSheet(fu);
      return;
    }
    widget.nav.openNotif(
      context,
      _targetFor(n.targetKey),
      courseId: n.courseId,
      meetingNumber: n.meetingNumber,
    );
  }

  /// Bottom sheet Arahan Tindak Lanjut Dosen (Asisten Lab).
  void _showDosenFollowUpSheet(AssistantFollowUpRecord fu) {
    final student = fu.studentName;
    final msg = fu.message;
    final type = fu.followUpType;
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final w = fu.createdAt.toUtc().add(const Duration(hours: 7));
    final sentAt =
        '${w.day.toString().padLeft(2, '0')} ${bulan[w.month - 1]}, ${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')} WIB';
    labShowCustomSheet<void>(
      context,
      title: 'Arahan Tindak Lanjut Dosen',
      child: LabColumn(
        gap: 14,
        children: [
          LabPerson(
            initials: 'DS',
            name: 'Dosen Pengampu',
            caption: 'Dikirim $sentAt • Kategori $type',
          ),
          LabInsetBox(
            child: LabColumn(
              gap: 8,
              cross: CrossAxisAlignment.start,
              children: [
                Text('Praktikan: $student (${fu.studentNim})',
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
                NotificationSyncService.instance.push(
                  role: 'praktikan',
                  targetUser: fu.studentNim,
                  icon: 'chat_bubble',
                  title: 'Pengingat dari Asisten',
                  body: 'Untuk $student (${fu.studentNim}): $msg',
                  targetKey: 'detailAbsensi',
                  important: true,
                );
                Navigator.of(context).pop();
                labToast(context, 'Pesan pengingat dikirim ke $student');
              },
            ),
            right: LabPrimaryButton(
              icon: 'check',
              label: 'Tandai Ditindaklanjuti',
              onTap: () async {
                try {
                  await NilaiSyncService.instance.markFollowUpDone(
                    fu.id,
                    byAslab: AuthController.instance.userName,
                  );
                } on StateError catch (e) {
                  if (mounted) labToast(context, e.message);
                  return;
                }
                if (!mounted) return;
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
