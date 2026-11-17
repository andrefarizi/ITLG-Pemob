import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../laboran_store.dart';
import '../widgets/laboran_ui.dart';

/// Figma: "Tiket Perbaikan-Laboran".
class LaboranTiketPage extends StatefulWidget {
  final LaboranStore store;
  final ValueChanged<LabTicket> onOpenTicket;

  const LaboranTiketPage({
    super.key,
    required this.store,
    required this.onOpenTicket,
  });

  @override
  State<LaboranTiketPage> createState() => _LaboranTiketPageState();
}

class _LaboranTiketPageState extends State<LaboranTiketPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tickets = _tab == 0 ? widget.store.tickets : const <LabTicket>[];
    return LabTabBody(
      children: [
        const LabTitle(
          title: 'Tiket Perbaikan',
          subtitle: 'Laporan kendala perangkat dari Asisten Lab',
        ),
        const LabStatRow(
          stats: [
            LabStat(icon: 'triangle_alert', label: 'Reported', value: '3'),
            LabStat(icon: 'wrench_outline', label: 'In Progress', value: '2'),
            LabStat(icon: 'check', label: 'Resolved', value: '12'),
          ],
        ),
        LabTabs(
          labels: const ['Reported (3)', 'In Progress', 'Resolved'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        for (final t in tickets)
          _TicketCard(ticket: t, onOpen: () => widget.onOpenTicket(t)),
        if (tickets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Belum ada data tiket untuk status ini.',
              textAlign: TextAlign.center,
              style: labText(12, c: ItlgColors.textSubtle),
            ),
          ),
      ],
    );
  }
}

class _TicketCard extends StatelessWidget {
  final LabTicket ticket;
  final VoidCallback onOpen;
  const _TicketCard({required this.ticket, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return LabCard(
      children: [
        Row(
          children: [
            LabTag.grey(ticket.id),
            const Spacer(),
            const LabChip.danger('Reported'),
          ],
        ),
        Row(
          children: [
            LabIconTile(ticket.icon),
            const SizedBox(width: 10),
            Expanded(
              child: LabColumn(
                gap: 2,
                children: [
                  Text(ticket.title,
                      style: labText(16, w: kBold, c: Colors.black)),
                  Text(ticket.place,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                ],
              ),
            ),
          ],
        ),
        Text(ticket.summary, style: labText(12, c: ItlgColors.textMuted)),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: LabMeta(icon: 'person', text: ticket.reporter),
              ),
            ),
            const SizedBox(width: 8),
            LabMeta(icon: 'clock', text: ticket.time),
          ],
        ),
        LabOutlineButton(
          icon: 'eye',
          label: 'Lihat & Perbarui Status',
          onTap: onOpen,
        ),
      ],
    );
  }
}
