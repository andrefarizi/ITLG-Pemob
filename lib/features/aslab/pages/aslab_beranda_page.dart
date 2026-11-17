import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
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
    final leaves = _store.pendingLeaves;
    return LabTabBody(
      children: [
        _greeting(),
        LabCard(
          children: [
            const PrakSpaceRow(
              left: LabChip.info('Sesi Berikutnya'),
              right: LabPill(icon: 'clock', text: 'Mulai 08:00'),
            ),
            Text('Praktikum\nPemrograman Mobile',
                style: labText(22, w: kBold, c: Colors.black)),
            const LabColumn(
              gap: 8,
              cross: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: LabMeta(
                          icon: 'clock', text: 'Senin • 08:00–09:40 WIB'),
                    ),
                    SizedBox(width: 24),
                    Flexible(
                      child: LabMeta(icon: 'location', text: 'Lab Komputer 1'),
                    ),
                  ],
                ),
                LabMeta(
                  icon: 'people_group',
                  text: 'TIF 3001 - Kelas C • 24 Praktikan',
                ),
              ],
            ),
            LabPrimaryButton(
              icon: 'qrcode',
              label: 'Mulai Sesi Presensi',
              large: true,
              onTap: () => _nav.buatSesi(context),
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
            for (final s in const [kRina, kDimas])
              LabListItem(
                leading: LabAvatar(s.initials),
                title: s.name,
                subtitle: 'Tugas 4 • Praktikum Basis Data',
                trailing: const LabIcon('chevron_right',
                    size: 16, color: ItlgColors.primary),
                onTap: () => _nav.penilaianTugas(context, student: s),
              ),
          ],
        ),
      ],
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
                Text('Andi Pratama',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labText(16, w: kBold, c: Colors.black)),
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
