import 'package:flutter/material.dart';

import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../widgets/dosen_ui.dart';

/// Halaman Minta Revisi Dosen.
class DosenMintaRevisiPage extends StatefulWidget {
  final String courseId;
  final VoidCallback? onLogoTap;
  const DosenMintaRevisiPage({
    super.key,
    this.courseId = 'pemob',
    this.onLogoTap,
  });

  @override
  State<DosenMintaRevisiPage> createState() => _DosenMintaRevisiPageState();
}

class _DosenMintaRevisiPageState extends State<DosenMintaRevisiPage> {
  static const List<String> _bagian = ['Nilai Tugas', 'Presensi', 'Nilai Akhir'];

  final TextEditingController _note = TextEditingController();
  bool _primaryAsst = true;
  bool _partnerAsst = true;
  int _part = 0;
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send(String primaryName, String partnerName) async {
    FocusScope.of(context).unfocus();
    final noteText = _note.text.trim();
    if (noteText.length < 10) {
      labToast(context, 'Tulis catatan revisi minimal 10 karakter', error: true);
      return;
    }
    final targets = <String>[
      if (_primaryAsst) primaryName,
      if (_partnerAsst) partnerName,
    ];
    if (targets.isEmpty) {
      labToast(context, 'Pilih minimal satu asisten penerima revisi',
          error: true);
      return;
    }
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await NilaiSyncService.instance.requestRevision(
        courseId: widget.courseId,
        part: _bagian[_part],
        note: noteText,
        assistants: targets,
        requestedBy: AuthController.instance.userName,
      );
    } on StateError catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        labToast(context, e.message);
      }
      return;
    }
    if (!mounted) return;
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
    final course = PraktikumSyncService.instance.courseById(widget.courseId);
    final primaryName = course.asisten;
    final partnerName =
        primaryName == 'Feri Gunawan' ? 'Abbil Rizki' : 'Feri Gunawan';
    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      children: [
        const LabTitle(
          title: 'Minta Revisi',
          subtitle: 'Kirim catatan revisi nilai ke asisten penilai',
        ),
        LabCard(
          children: [
            DosenClassTitle(code: course.kelas, courseName: course.name),
            LabMeta(
              icon: 'people_group',
              text: 'Dinilai oleh $primaryName & $partnerName',
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
                  title: primaryName,
                  subtitle: 'Asisten Lab • Penilai ${course.kelas}',
                  checked: _primaryAsst,
                  onTap: () => setState(() => _primaryAsst = !_primaryAsst),
                ),
                DosenCheckOption(
                  title: partnerName,
                  subtitle: 'Asisten Lab • Penilai ${course.kelas}',
                  checked: _partnerAsst,
                  onTap: () => setState(() => _partnerAsst = !_partnerAsst),
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
          onTap: () => _send(primaryName, partnerName),
        ),
      ],
    );
  }
}
