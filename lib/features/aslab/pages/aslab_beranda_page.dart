import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../shared/profil_data.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';
import '../widgets/aslab_ui.dart';

/// Figma: "Page Beranda-Aslab".
class AslabBerandaPage extends StatefulWidget {
  final AslabNav nav;
  final ValueChanged<int> onOpenTab;

  const AslabBerandaPage({
    super.key,
    required this.nav,
    required this.onOpenTab,
  });

  @override
  State<AslabBerandaPage> createState() => _AslabBerandaPageState();
}

class _AslabBerandaPageState extends State<AslabBerandaPage> {
  AslabNav get _nav => widget.nav;
  AslabStore get _store => widget.nav.store;

  void _refresh(void _) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final swapBadge = _store.swapAnswer == null ? 1 : 0;
    final presensiSync = PresensiSyncService.instance;
    final praktikumSync = PraktikumSyncService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([presensiSync, praktikumSync]),
      builder: (context, _) {
        final leaves = presensiSync.pendingLeaveCount;
        final session = presensiSync.activeSession;
        final activeCourse = praktikumSync.courseById(session.courseId);
        final pendingSubs = praktikumSync.allSubmissions
            .where((s) => s.status != 'graded')
            .take(2)
            .toList();
        return LabTabBody(
      children: [
        _greeting(),
        LabCard(
          children: [
            PrakSpaceRow(
              left: session.isActive
                  ? const LabChip.live('Sesi Berlangsung')
                  : const LabChip.info('Sesi Berikutnya'),
              right: session.isActive
                  ? AslabElapsedPill(start: session.startedAt)
                  : const LabPill(icon: 'clock', text: 'Mulai 08:00'),
            ),
            Text('Praktikum\n${activeCourse.name}',
                style: labText(22, w: kBold, c: Colors.black)),
            LabColumn(
              gap: 8,
              cross: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: LabMeta(
                          icon: 'clock', text: activeCourse.jadwalAbsensi),
                    ),
                    const SizedBox(width: 24),
                    Flexible(
                      child: LabMeta(icon: 'location', text: session.labName),
                    ),
                  ],
                ),
                LabMeta(
                  icon: 'people_group',
                  text: '${activeCourse.kelas} • 24 Praktikan',
                ),
              ],
            ),
            LabPrimaryButton(
              icon: 'qrcode',
              label: session.isActive
                  ? 'Lihat Sesi & QR Presensi'
                  : 'Mulai Sesi Presensi',
              large: true,
              onTap: () => session.isActive
                  ? _nav.sesiAktif(context)
                  : _nav.buatSesi(context, courseId: activeCourse.id),
            ),
          ],
        ),
        LabColumn(
          gap: 12,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabHeading(icon: 'grid', text: 'Menu Asisten'),
            ),
            _grid(
              AslabMenuCard(
                icon: 'calendar',
                title: 'Shift Jaga',
                subtitle: swapBadge > 0
                    ? '1 permintaan tukar shift'
                    : 'Tidak ada permintaan baru',
                badge: swapBadge,
                onTap: () => _nav.shiftJaga(context).then(_refresh),
              ),
              AslabMenuCard(
                icon: 'triangle_alert',
                title: 'Lapor Kendala',
                subtitle: 'PC, proyektor, AC, jaringan',
                onTap: () => _nav.laporKendala(context),
              ),
            ),
            _grid(
              AslabMenuCard(
                icon: 'bullhorn_outline',
                title: 'Pengumuman',
                subtitle: 'Buat pengumuman & ubah jadwal',
                onTap: () => _nav.buatPengumuman(context),
              ),
              AslabMenuCard(
                icon: 'file',
                title: 'Persetujuan Izin',
                subtitle: leaves > 0
                    ? '$leaves pengajuan menunggu'
                    : 'Tidak ada pengajuan baru',
                badge: leaves,
                onTap: () => _nav.persetujuanIzin(context).then(_refresh),
              ),
            ),
          ],
        ),
        LabColumn(
          gap: 12,
          children: [
            PrakSpaceRow(
              left: const LabHeading(icon: 'clipboard', text: 'Perlu Dinilai'),
              right: PrakSideLink(
                'Lihat Semua',
                onTap: () => widget.onOpenTab(AslabTab.penilaian),
              ),
            ),
            if (pendingSubs.isNotEmpty)
              for (final rec in pendingSubs)
                Builder(
                  builder: (_) {
                    final parts = rec.userName.trim().split(RegExp(r'\s+'));
                    final initials = parts.length >= 2
                        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                        : (rec.userName.isNotEmpty
                            ? rec.userName.substring(0, 1).toUpperCase()
                            : 'PR');
                    final c = praktikumSync.courseById(rec.courseId);
                    final st = AslabStudent(
                        initials, rec.userName, rec.userIdentifier);
                    return LabListItem(
                      leading: LabAvatar(st.initials),
                      title: st.name,
                      subtitle: 'Tugas ${rec.meetingNumber} • Praktikum ${c.name}',
                      trailing: const LabIcon('chevron_right',
                          size: 16, color: ItlgColors.primary),
                      onTap: () => _nav.penilaianTugas(
                        context,
                        student: st,
                        courseId: c.id,
                      ),
                    );
                  },
                )
            else
              for (final s in const [kRina, kDimas])
                LabListItem(
                  leading: LabAvatar(s.initials),
                  title: s.name,
                  subtitle: 'Tugas 4 • Praktikum Pemrograman Mobile',
                  trailing: const LabIcon('chevron_right',
                      size: 16, color: ItlgColors.primary),
                  onTap: () => _nav.penilaianTugas(
                    context,
                    student: s,
                    courseId: 'pemob',
                  ),
                ),
          ],
        ),
      ],
    );
      },
    );
  }

  Widget _grid(Widget a, Widget b) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: 14),
          Expanded(child: b),
        ],
      ),
    );
  }

  // Kartu sapaan (370 x 89).
  Widget _greeting() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ItlgShadows.outline,
      ),
      child: Row(
        children: [
          Image.asset('assets/avatar_laboran.png', width: 64, height: 65),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat Datang', style: labText(14, c: Colors.black)),
                const SizedBox(height: 2),
                ListenableBuilder(
                  listenable: ProfilData.aslab,
                  builder: (_, __) => Text(
                      ProfilData.aslab.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labText(16, w: kBold, c: Colors.black)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const LabIcon('shield_check_outline',
                        size: 12, color: ItlgColors.textSubtle),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text('Asisten Lab • Ganjil 2026',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: labText(12, c: ItlgColors.textSubtle)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _nav.notifikasi(context).then(_refresh),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: ItlgColors.primary,
                shape: BoxShape.circle,
                boxShadow: ItlgShadows.outline,
              ),
              child: const LabIcon('m_bell', size: 16.7, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
