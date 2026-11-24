import 'package:flutter/material.dart';

import '../../../core/services/device_calendar_service.dart';
import '../../../core/services/jadwal_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../widgets/praktikan_ui.dart';

/// Halaman Pengumuman Praktikan.
class PraktikanPengumumanPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanPengumumanPage({super.key, required this.nav});

  @override
  State<PraktikanPengumumanPage> createState() =>
      _PraktikanPengumumanPageState();
}

class _PraktikanPengumumanPageState extends State<PraktikanPengumumanPage> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  /// 0 Semua, 1 Perubahan Jadwal, 2 Umum.
  int _tab = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _match(AnnouncementRecord a) {
    final mappedCat = a.category == 1 ? 1 : 2;
    if (_tab != 0 && mappedCat != _tab) return false;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return a.title.toLowerCase().contains(q) ||
        a.body.toLowerCase().contains(q) ||
        a.author.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final sync = JadwalSyncService.instance;
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final items = sync.announcements.where(_match).toList();
        return LabSubPage(
          onLogoTap: widget.nav.home,
          children: [
            const LabTitle(
              title: 'Pengumuman',
              subtitle: 'Informasi terbaru dan perubahan jadwal praktikum',
            ),
            PrakSearchField(
              hint: 'Cari pengumuman...',
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              filterActive: _tab != 0,
              onFilter: () async {
                final i = await prakShowPicker(
                  context,
                  title: 'Filter Kategori',
                  options: const ['Semua', 'Perubahan Jadwal', 'Umum'],
                  selected: _tab,
                );
                if (i != null && mounted) setState(() => _tab = i);
              },
            ),
            LabTabs(
              labels: const ['Semua', 'Perubahan Jadwal', 'Umum'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            // Semua pengumuman di dalam satu "Kartu Daftar".
            if (items.isNotEmpty)
              LabListCard(
                children: [
                  for (final a in items) _AnnouncementCard(item: a),
                ],
              ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Tidak ada pengumuman.',
                    textAlign: TextAlign.center,
                    style: labText(12, c: ItlgColors.textSubtle)),
              ),
          ],
        );
      },
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementRecord item;
  const _AnnouncementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final showScheduleBox = item.category == 1 &&
        item.newSchedule != null &&
        item.newSchedule!.isNotEmpty;
    return LabRowCard(
      gap: 16,
      children: [
        PrakSpaceRow(
          left: Align(
            alignment: Alignment.centerLeft,
            child: item.tagRed ? LabTag.red(item.tag) : LabTag.blue(item.tag),
          ),
          right: LabMeta(icon: 'clock', text: item.relativeTime),
        ),
        Text(item.title, style: labText(16, w: kBold, c: Colors.black)),
        Text(item.body, style: labText(12, c: ItlgColors.textMuted)),
        if (showScheduleBox)
          LabInsetBox(
            child: LabColumn(
              gap: 10,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LabColumn(
                        gap: 2,
                        children: [
                          Text('Jadwal Lama',
                              style: labText(11,
                                  w: kMedium, c: ItlgColors.textSubtle)),
                          Text(item.oldSchedule ?? 'Sen • 08:00',
                              style: labText(12,
                                  w: kBold, c: LabColors.divider)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const LabIcon('arrow_right',
                        size: 16, color: ItlgColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LabColumn(
                        gap: 2,
                        children: [
                          Text('Jadwal Baru',
                              style: labText(11,
                                  w: kMedium, c: ItlgColors.textSubtle)),
                          Text(item.newSchedule!,
                              style: labText(12, w: kBold)),
                        ],
                      ),
                    ),
                  ],
                ),
                LabMeta(
                  icon: 'location',
                  text: item.room ?? 'Lab Jaringan 1',
                ),
                LabOutlineButton(
                  icon: 'calendar',
                  label: 'Sinkronkan ke Kalender HP',
                  onTap: () async {
                    final res = await DeviceCalendarService.instance
                        .syncSchedules(
                      JadwalSyncService.instance.schedules,
                      askPermission: true,
                    );
                    if (!context.mounted) return;
                    labToast(
                      context,
                      res.synced
                          ? 'Jadwal pengganti disinkronkan ke ${res.calendarName}'
                          : 'Jadwal pengganti dicatat untuk kalender HP',
                    );
                  },
                ),
              ],
            ),
          ),
        LabMeta(icon: 'person', text: item.author),
      ],
    );
  }
}
