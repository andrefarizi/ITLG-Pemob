import 'package:flutter/material.dart';

import '../../../core/services/lab_desk_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../praktikan/praktikan_store.dart';
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
  static const List<String> _labTabs = [
    'Jaringan 1',
    'Jaringan 2',
    'Jaringan 3',
    'Jaringan 4',
  ];
  static const List<String> _labNames = [
    LabDeskSyncService.defaultLab,
    'Lab Jaringan 2',
    'Lab Jaringan 3',
    'Lab Jaringan 4',
  ];
  final LabDeskSyncService _sync = LabDeskSyncService.instance;
  int _selectedDesk = 12;
  int _labIdx = 0;

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

  LabDeskStatus _statusFor(int number, Map<int, PrakDesk> liveMap) {
    if (number == _selectedDesk) return LabDeskStatus.dipilih;
    switch (liveMap[number]) {
      case PrakDesk.available:
        return LabDeskStatus.tersedia;
      case PrakDesk.broken:
        return LabDeskStatus.rusak;
      default:
        return LabDeskStatus.terisi;
    }
  }

  String _subtitleForDesk(LabDeskRecord? rec, LabTicketRecord? ticket) {
    if (ticket != null) {
      final booker = rec?.bookedByName;
      if (booker != null && booker.isNotEmpty) {
        return 'Ditempati $booker • dilaporkan ${ticket.formattedClock}';
      }
      return 'Dilaporkan ${ticket.reporterName} • ${ticket.formattedClock}';
    }
    if (rec == null) return 'Kondisi perangkat normal';
    if (rec.status == PrakDesk.broken) {
      return 'Perangkat rusak • perlu perbaikan';
    }
    if (rec.status == PrakDesk.available) {
      return 'Meja tersedia • kondisi perangkat normal';
    }
    if (rec.bookedByName != null && rec.bookedByName!.isNotEmpty) {
      return 'Ditempati ${rec.bookedByName}';
    }
    return 'Kondisi perangkat normal';
  }

  String _badgeForDesk(LabDeskRecord? rec, LabTicketRecord? ticket) {
    if (ticket != null) {
      if (ticket.deskNumber == 12 &&
          ticket.title.toLowerCase().contains('menyala')) {
        return 'PC mati';
      }
      return ticket.status == 1 ? 'Proses' : 'Kendala';
    }
    if (rec?.status == PrakDesk.broken) return 'Rusak';
    return 'Kendala';
  }

  @override
  Widget build(BuildContext context) {
    final activeLab = _labNames[_labIdx];
    final liveMap = _sync.deskStatusMap(labName: activeLab);
    final taken = _sync.takenCount(labName: activeLab);
    final reportedDesks = _sync.activeReportedDesks(labName: activeLab);
    final selectedRec = _sync.deskRecord(_selectedDesk, labName: activeLab);
    final selectedTicket =
        _sync.activeTicketForDesk(_selectedDesk, labName: activeLab);
    final hasReport = selectedTicket != null ||
        selectedRec?.status == PrakDesk.broken;
    final pcLabel = _selectedDesk.toString().padLeft(2, '0');

    // Tiket untuk tombol utama: tiket meja terpilih, atau tiket terbaru di lab ini / semua lab
    final labTickets =
        _sync.allTickets.where((t) => t.labName == activeLab).toList();
    final primaryTicketRecord = selectedTicket ??
        (labTickets.isNotEmpty
            ? labTickets.first
            : (_sync.allTickets.isNotEmpty ? _sync.allTickets.first : null));
    final primaryTicket =
        primaryTicketRecord?.toLabTicket() ?? widget.store.tickets.first;

    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      children: [
        LabTabs(
          labels: _labTabs,
          index: _labIdx,
          onChanged: (i) => setState(() => _labIdx = i),
        ),
        // Card 1: Informasi Lab
        LabCard(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kom C • Sesi C1',
                  style: labText(14, c: const Color(0xFF640707)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Denah Meja\nLab ${_labTabs[_labIdx]}',
                  style: labText(22, w: kBold, c: Colors.black)
                      .copyWith(height: 1.2),
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
                      style:
                          labText(11, w: kMedium, c: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LabIcon('people_group',
                        size: 12, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text(
                      '$taken / 30 terisi',
                      style:
                          labText(11, w: kMedium, c: const Color(0xFF6B7280)),
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
                      child: const LabIcon('desktop_device',
                          size: 15, color: Colors.white),
                    ),
                    const SizedBox(width: 9),
                    Text('Denah Meja',
                        style: labText(14, w: kSemiBold, c: Colors.black)),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEE9F4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '30 PC',
                    style:
                        labText(10, w: kSemiBold, c: const Color(0xFF2369B7)),
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
                      style:
                          labText(11, w: kMedium, c: const Color(0xFF6B7280)),
                    ),
                  ),
                  for (var row = 0; row < 6; row++) ...[
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var col = 0; col < 5; col++) ...[
                            if (col == 3)
                              const SizedBox(width: 28)
                            else if (col > 0)
                              const SizedBox(width: 8),
                            _LabDeskTile(
                              number: row * 5 + col + 1,
                              status: _statusFor(row * 5 + col + 1, liveMap),
                              hasReport:
                                  reportedDesks.contains(row * 5 + col + 1),
                              onTap: () => setState(
                                  () => _selectedDesk = row * 5 + col + 1),
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
                child: const LabIcon('desktop_device',
                    size: 20, color: Color(0xFF0A0B0C)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meja $_selectedDesk • PC-$pcLabel',
                      style: labText(12, w: kBold, c: const Color(0xFF0A0B0C)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitleForDesk(selectedRec, selectedTicket),
                      style:
                          labText(11, w: kMedium, c: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              if (hasReport)
                Container(
                  height: 22,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E6E6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    _badgeForDesk(selectedRec, selectedTicket),
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
              label: 'Lihat Laporan ${primaryTicket.id.replaceFirst('#TK-', '#LK-')}',
              large: true,
              onTap: () {
                labPush(
                  context,
                  LaboranDetailTiketPage(
                    ticket: primaryTicket,
                    onLogoTap: widget.onLogoTap,
                  ),
                );
              },
            ),
            LabOutlineButton(
              icon: 'ticket',
              label: 'Lihat Semua Laporan',
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
                  color: status == LabDeskStatus.dipilih
                      ? Colors.white
                      : const Color(0xFF850909),
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
              Text('Rusak',
                  style: labText(11, w: kMedium, c: const Color(0xFF6B7280))),
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
              Text('Ada Laporan',
                  style: labText(11, w: kMedium, c: const Color(0xFF6B7280))),
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
