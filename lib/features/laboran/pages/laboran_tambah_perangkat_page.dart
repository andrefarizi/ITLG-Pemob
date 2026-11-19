import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../laboran_store.dart';
import '../widgets/laboran_ui.dart';

/// Form "Tambah Perangkat" dari halaman Data Inventaris. Perangkat baru
/// disimpan di [LaboranStore.desks] (memori saja, belum ke backend).
class LaboranTambahPerangkatPage extends StatefulWidget {
  final LaboranStore store;
  final int initialLab;
  final VoidCallback? onLogoTap;

  const LaboranTambahPerangkatPage({
    super.key,
    required this.store,
    this.initialLab = 0,
    this.onLogoTap,
  });

  @override
  State<LaboranTambahPerangkatPage> createState() =>
      _LaboranTambahPerangkatPageState();
}

class _LaboranTambahPerangkatPageState
    extends State<LaboranTambahPerangkatPage> {
  static const List<(String, String)> _status = [
    ('circle_check', 'Siap'),
    ('triangle_alert', 'Rusak'),
  ];

  late int _lab = widget.initialLab;
  int _st = 0;
  final TextEditingController _meja = TextEditingController();
  final TextEditingController _pc = TextEditingController();
  final TextEditingController _spec =
      TextEditingController(text: LaboranStore.defaultSpec);

  @override
  void initState() {
    super.initState();
    _suggestNumber();
  }

  /// Isi nomor meja berikutnya otomatis (bisa diubah).
  void _suggestNumber() {
    final next = (widget.store.desks[_lab].length + 1).toString().padLeft(2, '0');
    _meja.text = next;
    _pc.text = 'PC-$next';
  }

  @override
  void dispose() {
    _meja.dispose();
    _pc.dispose();
    _spec.dispose();
    super.dispose();
  }

  Future<void> _pickLab() async {
    final i = await prakShowPicker(
      context,
      title: 'Pilih Laboratorium',
      options: LaboranStore.inventoryLabs,
      selected: _lab,
    );
    if (i != null && mounted) {
      setState(() {
        _lab = i;
        _suggestNumber();
      });
    }
  }

  void _simpan() {
    final meja = _meja.text.trim();
    final pc = _pc.text.trim();
    final spec = _spec.text.trim();
    if (meja.isEmpty || pc.isEmpty) {
      labToast(context, 'Nomor meja dan kode PC wajib diisi');
      return;
    }
    if (spec.isEmpty) {
      labToast(context, 'Spesifikasi PC wajib diisi');
      return;
    }
    final name = 'Meja ${meja.padLeft(2, '0')} • ${pc.toUpperCase()}';
    final list = widget.store.desks[_lab];
    if (list.any((d) => d.name == name)) {
      labToast(context, '$name sudah terdaftar');
      return;
    }
    list.add(LabDesk(name, spec, _st == 0));
    Navigator.of(context).maybePop(true);
    labToast(context,
        '$name ditambahkan ke ${LaboranStore.inventoryLabs[_lab]}');
  }

  @override
  Widget build(BuildContext context) {
    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      children: [
        LabCard(
          children: [
            const LabOverline(
              overline: 'Data Inventaris',
              title: 'Tambah Perangkat',
            ),
            Text('Daftarkan meja dan PC baru beserta spesifikasinya.',
                style: labText(12, c: ItlgColors.textMuted)),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(icon: 'chip', text: 'Detail Perangkat'),
            ),
            PrakField(
              label: 'Laboratorium',
              child: PrakSelect(
                value: LaboranStore.inventoryLabs[_lab],
                onTap: _pickLab,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: PrakField(
                    label: 'Nomor Meja',
                    child: PrakInput(controller: _meja, leadingIcon: 'grid'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrakField(
                    label: 'Kode PC',
                    child: PrakInput(
                        controller: _pc, leadingIcon: 'desktop_device'),
                  ),
                ),
              ],
            ),
            PrakField(
              label: 'Spesifikasi PC',
              child: PrakInput(controller: _spec),
            ),
            PrakField(
              label: 'Status Awal',
              child: PrakOptionChips(
                options: _status,
                index: _st,
                onChanged: (i) => setState(() => _st = i),
              ),
            ),
          ],
        ),
        LabPrimaryButton(
          icon: 'plus',
          label: 'Simpan Perangkat',
          large: true,
          onTap: _simpan,
        ),
      ],
    );
  }
}
