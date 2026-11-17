import 'package:flutter/material.dart';

import '../../laboran/widgets/laboran_ui.dart';
import '../widgets/dosen_ui.dart';

/// Figma: "Minta Revisi-Dosen" (dari tombol "Minta Revisi ke Asisten").
class DosenMintaRevisiPage extends StatefulWidget {
  final VoidCallback? onLogoTap;
  const DosenMintaRevisiPage({super.key, this.onLogoTap});

  @override
  State<DosenMintaRevisiPage> createState() => _DosenMintaRevisiPageState();
}

class _DosenMintaRevisiPageState extends State<DosenMintaRevisiPage> {
  static const List<String> _bagian = ['Nilai Tugas', 'Presensi', 'Nilai Akhir'];

  final TextEditingController _note = TextEditingController(
    text: 'Mohon periksa kembali nilai tugas Modul 3 dan 4. Ada selisih antara '
        'nilai tugas dan rekap presensi.',
  );
  bool _andi = true;
  bool _feri = true;
  int _part = 0;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _send() {
    FocusScope.of(context).unfocus();
    dosenShowResult(
      context,
      icon: 'send',
      title: 'Permintaan Terkirim',
      message: 'Asisten penilai akan menerima catatan revisi anda sebagai '
          'notifikasi.',
      button: 'Kembali ke Validasi',
      onPressed: () => dosenPopToShell(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      children: [
        const LabTitle(
          title: 'Minta Revisi',
          subtitle: 'Kirim catatan revisi nilai ke asisten penilai',
        ),
        const LabCard(
          children: [
            DosenClassTitle(),
            LabMeta(
              icon: 'people_group',
              text: 'Dinilai oleh Andi Pratama & Feri Gunawan',
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(icon: 'pencil', text: 'Detail Revisi'),
            ),
            LabColumn(
              gap: 8,
              children: [
                Text('Kirim Ke', style: labText(14)),
                DosenCheckOption(
                  title: 'Andi Pratama',
                  subtitle: 'Asisten Lab • Penilai Kelas C',
                  checked: _andi,
                  onTap: () => setState(() => _andi = !_andi),
                ),
                DosenCheckOption(
                  title: 'Feri Gunawan',
                  subtitle: 'Asisten Lab • Penilai Kelas C',
                  checked: _feri,
                  onTap: () => setState(() => _feri = !_feri),
                ),
              ],
            ),
            LabColumn(
              gap: 8,
              children: [
                Text('Bagian yang Direvisi', style: labText(14)),
                LabTabs(
                  labels: _bagian,
                  index: _part,
                  gap: 10,
                  hPadding: 12,
                  onChanged: (i) => setState(() => _part = i),
                ),
              ],
            ),
            DosenTextArea(label: 'Catatan Revisi :', controller: _note),
          ],
        ),
        const DosenInfoBox(
          icon: 'arrow_cycle',
          text: 'Selama revisi berlangsung, validasi nilai akhir kelas ini '
              'ditunda.',
        ),
        LabPrimaryButton(
          icon: 'send',
          label: 'Kirim Permintaan',
          large: true,
          onTap: _send,
        ),
      ],
    );
  }
}
