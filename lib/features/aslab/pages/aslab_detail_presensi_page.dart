import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../../shared/lab_actions.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';
import '../widgets/aslab_ui.dart';

/// Figma: "Detail Presensi Pertemuan-Aslab".
///
/// Status tiap praktikan bisa diubah (Hadir / Izin / Alpa); rekap di atas
/// ikut berubah.
class AslabDetailPresensiPage extends StatefulWidget {
  final AslabNav nav;
  const AslabDetailPresensiPage({super.key, required this.nav});

  @override
  State<AslabDetailPresensiPage> createState() =>
      _AslabDetailPresensiPageState();
}

class _AslabDetailPresensiPageState extends State<AslabDetailPresensiPage> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  /// Filter status: 0 Semua, lalu 1 + indeks [AslabAttend].
  int _status = 0;

  Future<void> _openFilter() async {
    final i = await prakShowPicker(
      context,
      title: 'Filter Status Kehadiran',
      options: const ['Semua', 'Hadir', 'Izin', 'Alpa'],
      selected: _status,
    );
    if (i != null && mounted) setState(() => _status = i);
  }

  /// Status awal (untuk tanda "Diubah dari ..." dan tombol Simpan).
  late final List<AslabAttend> _initial =
      widget.nav.store.presences.map((p) => p.status).toList();

  /// 19 praktikan lain (tidak ditampilkan) berstatus hadir: 21/2/1.
  static const int _otherHadir = 19;

  List<AslabPresence> get _list => widget.nav.store.presences;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _count(AslabAttend a) => _list.where((p) => p.status == a).length;

  void _simpan() {
    Navigator.of(context).maybePop();
    labToast(context, 'Perubahan presensi Pertemuan 4 disimpan');
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = [
      for (var i = 0; i < _list.length; i++)
        if ((_status == 0 ||
                _list[i].status == AslabAttend.values[_status - 1]) &&
            (q.isEmpty ||
                _list[i].student.name.toLowerCase().contains(q) ||
                _list[i].student.nim.contains(q)))
          i,
    ];
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            const PrakSpaceRow(
              left: LabChip.idle('Sesi Ditutup'),
              right: LabMeta(icon: 'calendar', text: 'Sen, 28 Sep 2026'),
            ),
            const LabOverline(
              overline: 'Praktikum Pemrograman Mobile • Kelas C',
              title: 'Presensi\nPertemuan 4',
            ),
            AslabRekap(
              hadir: _otherHadir + _count(AslabAttend.hadir),
              izin: _count(AslabAttend.izin),
              alpa: _count(AslabAttend.alpa),
            ),
          ],
        ),
        const PrakNotice.info(
          icon: 'info',
          text: 'Ubah status dengan memilih salah satu kotak. Setiap '
              'perubahan tercatat atas nama anda.',
        ),
        PrakSearchField(
          hint: 'Cari nama atau NIM praktikan...',
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          onFilter: _openFilter,
          filterActive: _status != 0,
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Tidak ada praktikan dengan filter ini.',
                textAlign: TextAlign.center,
                style: labText(12, c: ItlgColors.textSubtle)),
          ),
        LabColumn(
          gap: 10,
          children: [
            for (final i in items)
              _StudentCard(
                presence: _list[i],
                changedFrom: _list[i].status != _initial[i]
                    ? _initial[i]
                    : null,
                onStatus: (v) =>
                    setState(() => _list[i].status = AslabAttend.values[v]),
                onProof: () => widget.nav.buktiPresensi(context),
              ),
          ],
        ),
        LabPrimaryButton(
          icon: 'check',
          label: 'Simpan Perubahan',
          large: true,
          onTap: _simpan,
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  final AslabPresence presence;
  final AslabAttend? changedFrom;
  final ValueChanged<int> onStatus;
  final VoidCallback onProof;

  const _StudentCard({
    required this.presence,
    required this.changedFrom,
    required this.onStatus,
    required this.onProof,
  });

  static const List<String> _names = ['Hadir', 'Izin', 'Alpa'];

  @override
  Widget build(BuildContext context) {
    final p = presence;
    final tag = changedFrom != null
        ? 'Diubah dari ${_names[changedFrom!.index]}'
        : p.changedTag;
    final izin = p.izin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ItlgShadows.outline,
      ),
      child: LabColumn(
        gap: 10,
        children: [
          Row(
            children: [
              LabAvatar(p.student.initials),
              const SizedBox(width: 10),
              Expanded(
                child: LabColumn(
                  gap: 2,
                  children: [
                    Text(p.student.name, style: labText(14, w: kBold)),
                    Text(p.student.nim,
                        style: labText(11,
                            w: kMedium, c: ItlgColors.textSubtle)),
                  ],
                ),
              ),
              if (tag != null) ...[
                const SizedBox(width: 8),
                LabTag.blue(tag),
              ],
            ],
          ),
          if (p.proof.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onProof,
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        for (final m in p.proof)
                          LabMeta(icon: m.$1, text: m.$2),
                      ],
                    ),
                  ),
                  if (p.proofLink) ...[
                    const SizedBox(width: 8),
                    Text('Lihat Bukti',
                        style: labText(12, c: ItlgColors.primary)),
                  ],
                ],
              ),
            ),
          AslabStatusPicker(value: p.status.index, onChanged: onStatus),
          if (izin != null)
            InnerShadowBox(
              radius: 12,
              color: ItlgColors.surfaceDark,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: LabColumn(
                gap: 6,
                children: [
                  Text(izin.$1, style: labText(12, w: kBold)),
                  Text(izin.$2,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                  Row(
                    children: [
                      Flexible(
                        child: AslabFilePill(
                            icon: 'attach', text: izin.$3, raised: true),
                      ),
                      const SizedBox(width: 8),
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => labShowFilePreview(
                          context,
                          name: izin.$3,
                          source: 'Lampiran izin praktikan',
                        ),
                        child: Text('Lihat Lampiran',
                            style: labText(12, c: ItlgColors.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
