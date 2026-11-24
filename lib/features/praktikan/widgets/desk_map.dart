import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_store.dart';

/// Widget grid denah 30 meja laboratorium (6 baris x 5 kolom).
class PrakDeskMap extends StatelessWidget {
  final Map<int, PrakDesk> desks;
  final int? selected;

  /// null = hanya tampilan (tidak bisa dipilih).
  final ValueChanged<int>? onTap;

  const PrakDeskMap({
    super.key,
    required this.desks,
    this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InnerShadowBox(
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
            child: Text(
              'Meja Asisten & Layar Proyektor',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labText(11, w: kMedium, c: ItlgColors.textSubtle),
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
                    _Desk(
                      number: row * 5 + col + 1,
                      status: desks[row * 5 + col + 1] ?? PrakDesk.taken,
                      selected: row * 5 + col + 1 == selected,
                      onTap: onTap,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Desk extends StatelessWidget {
  final int number;
  final PrakDesk status;
  final bool selected;
  final ValueChanged<int>? onTap;

  const _Desk({
    required this.number,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = number.toString().padLeft(2, '0');

    if (status == PrakDesk.taken && !selected) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null ? null : () => onTap!(number),
        child: InnerShadowBox(
          width: 40,
          height: 40,
          radius: 10,
          color: LabColors.tile,
          shadows: LabShadows.track,
          child: Center(
            child: Text(label,
                style: labText(12, w: kBold, c: LabColors.divider)),
          ),
        ),
      );
    }

    final Color bg;
    final Color fg;
    final List<BoxShadow> shadow;
    if (selected) {
      bg = ItlgColors.primary;
      fg = Colors.white;
      shadow = ItlgShadows.primary;
    } else if (status == PrakDesk.broken) {
      bg = LabColors.tagRedBg;
      fg = ItlgColors.primary;
      shadow = const [];
    } else {
      bg = Colors.white;
      fg = ItlgColors.text;
      shadow = ItlgShadows.outline;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null ? null : () => onTap!(number),
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

/// Keterangan warna denah: Tersedia, Terisi, [selectedLabel], Rusak.
class PrakDeskLegend extends StatelessWidget {
  final String selectedLabel;
  const PrakDeskLegend({super.key, this.selectedLabel = 'Dipilih'});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        const _Legend(kind: 0, text: 'Tersedia'),
        const _Legend(kind: 1, text: 'Terisi'),
        _Legend(kind: 2, text: selectedLabel),
        const _Legend(kind: 3, text: 'Rusak'),
      ],
    );
  }
}

/// Kotak + keterangan.
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
