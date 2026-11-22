import 'package:flutter/material.dart';

import '../../../core/services/lab_desk_sync_service.dart';
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
  final LabDeskSyncService _sync = LabDeskSyncService.instance;
  int _tab = 0;

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

  @override
  Widget build(BuildContext context) {
    final reportedCount = _sync.ticketCountByStatus(0);
    final inProgressCount = _sync.ticketCountByStatus(1);
    final resolvedCount = _sync.ticketCountByStatus(2);
    final tickets = _sync.ticketsByStatus(_tab);

    return LabTabBody(
      children: [
        const LabTitle(
          title: 'Tiket Perbaikan',
          subtitle: 'Laporan kendala perangkat dari Praktikan & Asisten Lab',
        ),
        LabStatRow(
          stats: [
            LabStat(
                icon: 'triangle_alert',
                label: 'Reported',
                value: '$reportedCount'),
            LabStat(
                icon: 'wrench_outline',
                label: 'In Progress',
                value: '$inProgressCount'),
            LabStat(icon: 'check', label: 'Resolved', value: '$resolvedCount'),
          ],
        ),
        LabTabs(
          labels: ['Reported ($reportedCount)', 'In Progress', 'Resolved'],
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

  Widget _statusChip() {
    switch (ticket.status) {
      case 1:
        return const LabChip.warn('In Progress');
      case 2:
        return const LabChip.live('Resolved');
      default:
        return const LabChip.danger('Reported');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LabCard(
      children: [
        Row(
          children: [
            LabTag.grey(ticket.id),
            const Spacer(),
            _statusChip(),
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
