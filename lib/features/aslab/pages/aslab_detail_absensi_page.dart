import 'package:flutter/material.dart';

import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';
import '../widgets/aslab_ui.dart';

/// Figma: "Detail Absensi Praktikum-Aslab".
class AslabDetailAbsensiPage extends StatefulWidget {
  final AslabNav nav;
  final AslabCourse course;

  const AslabDetailAbsensiPage({
    super.key,
    required this.nav,
    required this.course,
  });

  @override
  State<AslabDetailAbsensiPage> createState() => _AslabDetailAbsensiPageState();
}

class _AslabDetailAbsensiPageState extends State<AslabDetailAbsensiPage> {
  /// 0 Semua, 1 Selesai, 2 Belum Dibuat.
  int _tab = 0;

  bool _match(AslabSession s) {
    if (_tab == 1) return s.state == 2;
    if (_tab == 2) return s.state != 2;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final nav = widget.nav;
    final items = c.sessions.where(_match).toList();
    return LabSubPage(
      onLogoTap: nav.home,
      children: [
        LabCard(
          children: [
            AslabClassTitle(kelas: c.kelas, name: c.name),
            LabStatRow(
              gap: 13,
              stats: [
                const LabStat(
                    icon: 'people_group', label: 'Praktikan', value: '24 Orang'),
                LabStat(
                    icon: 'statistic_up',
                    label: 'Rata-rata Hadir',
                    value: c.rataHadir),
              ],
            ),
            const LabProgress(
              label: 'Presensi dibuat',
              value: '4 / 12 pertemuan',
              fraction: 113 / 338,
            ),
          ],
        ),
        LabTabs(
          labels: const ['Semua', 'Selesai', 'Belum Dibuat'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        LabColumn(
          gap: 16,
          children: [
            for (final s in items)
              _SessionCard(
                session: s,
                onCreate: () => nav.buatSesi(
                  context,
                  courseId: c.id,
                  meetingNumber: s.number,
                ),
                onDetail: () => nav.detailPresensi(context),
              ),
          ],
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final AslabSession session;
  final VoidCallback onCreate;
  final VoidCallback onDetail;

  const _SessionCard({
    required this.session,
    required this.onCreate,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final s = session;
    final done = s.state == 2;
    return LabCard(
      gap: 12,
      children: [
        Row(
          children: [
            PrakNumberTile('${s.number}'),
            const SizedBox(width: 10),
            Expanded(
              child: LabColumn(
                gap: 2,
                children: [
                  Text('Pertemuan ${s.number}', style: labText(14, w: kBold)),
                  Text(s.module,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labText(11,
                          w: kMedium, c: const Color(0xFF6B7280))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            done
                ? const LabChip.live('Selesai')
                : const LabChip.idle('Belum Dibuat'),
          ],
        ),
        LabMeta(icon: 'calendar', text: s.date),
        if (s.state == 0)
          LabPrimaryButton(
              icon: 'qrcode', label: 'Buat Sesi Presensi', onTap: onCreate),
        if (s.state == 1)
          const LabMeta(
            icon: 'lock_on',
            text: 'Sesi dapat dibuat pada hari pertemuan',
          ),
        if (done) ...[
          AslabRekap(hadir: s.hadir, izin: s.izin, alpa: s.alpa),
          LabOutlineButton(
            icon: 'eye',
            label: 'Detail Presensi Pertemuan ${s.number}',
            onTap: onDetail,
          ),
        ],
      ],
    );
  }
}
