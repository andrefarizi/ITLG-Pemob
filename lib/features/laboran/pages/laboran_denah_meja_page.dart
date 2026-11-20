import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../laboran_store.dart';
import '../widgets/laboran_ui.dart';
import 'laboran_detail_tiket_page.dart';
import 'laboran_tiket_page.dart';

/// Status meja di Denah Meja Laboran.
enum LabDeskStatus {
  tersedia,
  terisi,
  dipilih,
  rusak,
}

/// Figma: "Denah Meja-Laboran" (node 5712:3087).
class LaboranDenahMejaPage extends StatefulWidget {
  final LaboranStore store;
  final VoidCallback onLogoTap;
  final VoidCallback? onOpenTiketTab;

  const LaboranDenahMejaPage({
    super.key,
    required this.store,
    required this.onLogoTap,
    this.onOpenTiketTab,
  });

  @override
  State<LaboranDenahMejaPage> createState() => _LaboranDenahMejaPageState();
}

class _LaboranDenahMejaPageState extends State<LaboranDenahMejaPage> {
  int _selectedDesk = 12;

  // Status awal 30 meja sesuai Figma
  late final Map<int, LabDeskStatus> _deskStatuses = {
    for (int i = 1; i <= 30; i++) i: LabDeskStatus.terisi,
  };

  // Meja yang memiliki laporan kendala aktif
  final Set<int> _reportedDesks = {12, 14};

  @override
  void initState() {
    super.initState();
    // Inisialisasi status meja sesuai data Figma
    // Tersedia (putih): 3, 8, 17, 25, 27, 30
    const tersedia = [3, 8, 17, 25, 27, 30];
    for (final d in tersedia) {
      _deskStatuses[d] = LabDeskStatus.tersedia;
    }
    // Rusak (merah muda #eddada): 23
    _deskStatuses[23] = LabDeskStatus.rusak;
    // Dipilih: 12
    _deskStatuses[12] = LabDeskStatus.dipilih;
  }

  void _selectDesk(int number) {
    setState(() {
      if (_selectedDesk > 0) {
        if (_deskStatuses[_selectedDesk] == LabDeskStatus.dipilih) {
          if (_selectedDesk == 23) {
            _deskStatuses[_selectedDesk] = LabDeskStatus.rusak;
          } else if ([3, 8, 17, 25, 27, 30].contains(_selectedDesk)) {
            _deskStatuses[_selectedDesk] = LabDeskStatus.tersedia;
          } else {
            _deskStatuses[_selectedDesk] = LabDeskStatus.terisi;
          }
        }
      }
      _selectedDesk = number;
      _deskStatuses[number] = LabDeskStatus.dipilih;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      children: [
        // Card 1: Informasi Lab
        LabCard(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lab Komputer 1',
                  style: labText(14, c: const Color(0xFF640707)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Denah Meja\nLab',
                  style: labText(22, w: kBold, c: Colors.black).copyWith(height: 1.2),
                ),
              ],
            ),
            Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LabIcon('clock', size: 12, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text(
                      'Senin • 08:00–09:40 WIB',
                      style: labText(11, w: kMedium, c: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LabIcon('people_group', size: 12, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text(
                      '23 / 30 terisi',
                      style: labText(11, w: kMedium, c: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Card 2: Denah Meja Visual
        LabCard(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ItlgColors.primary,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const LabIcon('desktop_device', size: 15, color: Colors.white),
                    ),
                    const SizedBox(width: 9),
                    Text('Denah Meja', style: labText(14, w: kSemiBold, c: Colors.black)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEE9F4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '30 PC',
                    style: labText(10, w: kSemiBold, c: const Color(0xFF2369B7)),
                  ),
                ),
              ],
            ),

            // Denah Grid Meja dengan Inner Shadow
            InnerShadowBox(
              radius: 12,
              color: Colors.white,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Meja Asisten & Layar Proyektor',
                      style: labText(11, w: kMedium, c: const Color(0xFF6B7280)),
                    ),
                  ),
                  for (var row = 0; row < 5; row++) ...[
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var col = 0; col < 6; col++) ...[
                            if (col == 3)
                              const SizedBox(width: 12)
                            else if (col > 0)
                              const SizedBox(width: 8),
                            _LabDeskTile(
                              number: row * 6 + col + 1,
                              status: _deskStatuses[row * 6 + col + 1] ?? LabDeskStatus.terisi,
                              hasReport: _reportedDesks.contains(row * 6 + col + 1),
                              onTap: () => _selectDesk(row * 6 + col + 1),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Legenda Denah Meja
            const _LabDeskLegend(),
          ],
        ),

        // Card 3: Detail Meja yang Dipilih
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: ItlgShadows.outline,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF0F3),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const LabIcon('desktop_device', size: 20, color: Color(0xFF0A0B0C)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meja $_selectedDesk • PC-$_selectedDesk',
                      style: labText(12, w: kBold, c: const Color(0xFF0A0B0C)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedDesk == 12
                          ? 'Dibooking Rina Novita • dilaporkan 08:15'
                          : (_reportedDesks.contains(_selectedDesk)
                              ? 'Ada kendala dilaporkan asisten'
                              : 'Kondisi perangkat normal'),
                      style: labText(11, w: kMedium, c: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              if (_reportedDesks.contains(_selectedDesk))
                Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E6E6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    _selectedDesk == 12 ? 'PC mati' : 'Kendala',
                    style: labText(12, w: kBold, c: ItlgColors.primary),
                  ),
                ),
            ],
          ),
        ),

        // Tombol Aksi
        LabColumn(
          gap: 12,
          children: [
            LabPrimaryButton(
              icon: 'circle_check',
              label: 'Lihat Tiket #TK-0921',
              large: true,
              onTap: () {
                final ticket = widget.store.tickets.firstWhere(
                  (t) => t.id == '#TK-0921',
                  orElse: () => widget.store.tickets.first,
                );
                labPush(
                  context,
                  LaboranDetailTiketPage(
                    ticket: ticket,
                    onLogoTap: widget.onLogoTap,
                  ),
                );
              },
            ),
            LabOutlineButton(
              icon: 'ticket',
              label: 'Lihat Semua Tiket',
              onTap: () {
                if (widget.onOpenTiketTab != null) {
                  Navigator.of(context).pop();
                  widget.onOpenTiketTab!();
                } else {
                  labPush(
                    context,
                    LaboranTiketPage(
                      store: widget.store,
                      onOpenTicket: (t) {
                        labPush(
                          context,
                          LaboranDetailTiketPage(
                            ticket: t,
                            onLogoTap: widget.onLogoTap,
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _LabDeskTile extends StatelessWidget {
  final int number;
  final LabDeskStatus status;
  final bool hasReport;
  final VoidCallback onTap;

  const _LabDeskTile({
    required this.number,
    required this.status,
    required this.hasReport,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = number.toString().padLeft(2, '0');

    if (status == LabDeskStatus.terisi) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            InnerShadowBox(
              width: 40,
              height: 40,
              radius: 10,
              color: const Color(0xFFEEF0F3),
              shadows: LabShadows.track,
              child: Center(
                child: Text(label,
                    style: labText(12, w: kBold, c: const Color(0xFFB5B9BC))),
              ),
            ),
            if (hasReport)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFF850909),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final Color bg;
    final Color fg;
    final List<BoxShadow> shadow;

    switch (status) {
      case LabDeskStatus.dipilih:
        bg = ItlgColors.primary;
        fg = Colors.white;
        shadow = ItlgShadows.primary;
        break;
      case LabDeskStatus.rusak:
        bg = const Color(0xFFEDDADA);
        fg = ItlgColors.primary;
        shadow = const [];
        break;
      case LabDeskStatus.tersedia:
      default:
        bg = Colors.white;
        fg = const Color(0xFF0A0B0C);
        shadow = ItlgShadows.outline;
        break;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              boxShadow: shadow,
            ),
            child: Text(label, style: labText(12, w: kBold, c: fg)),
          ),
          if (hasReport)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: status == LabDeskStatus.dipilih ? Colors.white : const Color(0xFF850909),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LabDeskLegend extends StatelessWidget {
  const _LabDeskLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        _legendItem(
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: ItlgShadows.outline,
            ),
          ),
          'Tersedia',
        ),
        _legendItem(
          const InnerShadowBox(
            width: 14,
            height: 14,
            radius: 4,
            color: Color(0xFFEEF0F3),
            shadows: LabShadows.track,
          ),
          'Terisi',
        ),
        _legendItem(
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: ItlgColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          'Dipilih',
        ),
        _legendItem(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDDADA),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Text('Rusak', style: labText(11, w: kMedium, c: const Color(0xFF6B7280))),
              const SizedBox(width: 8),
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFF850909),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text('Ada Laporan', style: labText(11, w: kMedium, c: const Color(0xFF6B7280))),
            ],
          ),
          null,
        ),
      ],
    );
  }

  Widget _legendItem(Widget box, String? text) {
    if (text == null) return box;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        box,
        const SizedBox(width: 6),
        Text(text, style: labText(11, w: kMedium, c: const Color(0xFF6B7280))),
      ],
    );
  }
}
