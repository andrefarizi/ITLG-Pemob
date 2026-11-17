import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Pilih Meja-Praktikan".
class PraktikanPilihMejaPage extends StatefulWidget {
  final PraktikanNav nav;
  const PraktikanPilihMejaPage({super.key, required this.nav});

  @override
  State<PraktikanPilihMejaPage> createState() => _PraktikanPilihMejaPageState();
}

class _PraktikanPilihMejaPageState extends State<PraktikanPilihMejaPage> {
  PraktikanStore get _s => widget.nav.store;

  int get _taken =>
      _s.desks.values.where((d) => d == PrakDesk.taken).length;

  void _konfirmasi() {
    final n = _s.selectedDesk;
    widget.nav.home();
    labToast(widget.nav.rootContext(), 'Meja $n dikonfirmasi');
  }

  @override
  Widget build(BuildContext context) {
    final sel = _s.selectedDesk;
    final pc = sel.toString().padLeft(2, '0');
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            const LabOverline(
                overline: 'Lab Komputer 1', title: 'Pilih Meja\nPraktikum'),
            Row(
              children: [
                const Flexible(
                  child:
                      LabMeta(icon: 'clock', text: 'Senin • 08:00–09:40 WIB'),
                ),
                const SizedBox(width: 24),
                Flexible(
                  child: LabMeta(
                      icon: 'people_group', text: '$_taken / 30 terisi'),
                ),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            const PrakSpaceRow(
              left: LabSectionTitle(icon: 'desktop_device', text: 'Denah Meja'),
              right: LabTag.blue('30 PC'),
            ),
            InnerShadowBox(
              radius: 12,
              color: Colors.white,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Container(
                    height: 25,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ItlgColors.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Meja Asisten & Layar Proyektor',
                        style: labText(11,
                            w: kMedium, c: ItlgColors.textSubtle)),
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
                              const SizedBox(width: 28)
                            else if (col > 0)
                              const SizedBox(width: 8),
                            _desk(row * 6 + col + 1),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                _Legend(kind: 0, text: 'Tersedia'),
                _Legend(kind: 1, text: 'Terisi'),
                _Legend(kind: 2, text: 'Dipilih'),
                _Legend(kind: 3, text: 'Rusak'),
              ],
            ),
          ],
        ),
        LabListItem(
          leading: const LabIconTile('desktop_device'),
          title: 'Meja $sel • PC-$pc',
          subtitle: 'Core i5-12400 • 16 GB • SSD 512 GB',
          titleSize: 12,
          trailing: const LabChip.live('Siap'),
        ),
        LabColumn(
          gap: 12,
          children: [
            LabPrimaryButton(
              icon: 'check',
              label: 'Konfirmasi Meja $sel',
              large: true,
              onTap: _konfirmasi,
            ),
            LabOutlineButton(
              icon: 'triangle_alert',
              label: 'Laporkan Kerusakan Meja',
              large: true,
              onTap: () => widget.nav.laporkanKerusakan(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _desk(int n) {
    final status = _s.desks[n]!;
    final selected = n == _s.selectedDesk;
    final label = n.toString().padLeft(2, '0');

    if (status == PrakDesk.taken) {
      return InnerShadowBox(
        width: 40,
        height: 40,
        radius: 10,
        color: LabColors.tile,
        shadows: LabShadows.track,
        child: Center(
          child: Text(label,
              style: labText(12, w: kBold, c: LabColors.divider)),
        ),
      );
    }

    final Color bg;
    final Color fg;
    final List<BoxShadow> shadow;
    if (status == PrakDesk.broken) {
      bg = LabColors.tagRedBg;
      fg = ItlgColors.primary;
      shadow = const [];
    } else if (selected) {
      bg = ItlgColors.primary;
      fg = Colors.white;
      shadow = ItlgShadows.primary;
    } else {
      bg = Colors.white;
      fg = ItlgColors.text;
      shadow = ItlgShadows.outline;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: status == PrakDesk.available
          ? () => setState(() => _s.selectedDesk = n)
          : () => labToast(context, 'Meja $label sedang rusak'),
      child: AnimatedContainer(
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
    );
  }
}

/// Kotak 14 px + keterangan Medium 11.
class _Legend extends StatelessWidget {
  /// 0 tersedia, 1 terisi, 2 dipilih, 3 rusak.
  final int kind;
  final String text;
  const _Legend({required this.kind, required this.text});

  @override
  Widget build(BuildContext context) {
    final Widget box = kind == 1
        ? const InnerShadowBox(
            width: 14,
            height: 14,
            radius: 4,
            color: LabColors.tile,
            shadows: LabShadows.track,
          )
        : Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: kind == 0
                  ? Colors.white
                  : (kind == 2 ? ItlgColors.primary : LabColors.tagRedBg),
              borderRadius: BorderRadius.circular(4),
              boxShadow: kind == 0 ? ItlgShadows.outline : const [],
            ),
          );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        box,
        const SizedBox(width: 6),
        Text(text, style: labText(11, w: kMedium, c: ItlgColors.textSubtle)),
      ],
    );
  }
}
