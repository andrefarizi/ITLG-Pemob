import 'package:flutter/material.dart';

import '../../laboran/widgets/laboran_ui.dart';
import '../dosen_store.dart';
import '../widgets/dosen_ui.dart';
import 'dosen_peringatan_page.dart';

/// Figma: "Hubungi Asisten-Dosen (Yoga / Lia / Bagas)".
class DosenHubungiPage extends StatefulWidget {
  final DosenStudent student;
  final VoidCallback? onLogoTap;

  const DosenHubungiPage({super.key, required this.student, this.onLogoTap});

  @override
  State<DosenHubungiPage> createState() => _DosenHubungiPageState();
}

class _DosenHubungiPageState extends State<DosenHubungiPage> {
  static const List<String> _followUps = ['Kehadiran', 'Konsultasi', 'Remedial'];

  late final TextEditingController _message =
      TextEditingController(text: widget.student.message);
  late int _followUp = widget.student.followUp;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _send() {
    FocusScope.of(context).unfocus();
    dosenShowResult(
      context,
      icon: 'chat_bubble',
      title: 'Pesan Terkirim',
      message: 'Asisten akan menerima pesan anda sebagai notifikasi.',
      button: 'Kembali ke Peringatan',
      onPressed: () => dosenPopToShell(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      children: [
        const LabTitle(
          title: 'Hubungi Asisten',
          subtitle: 'Kirim pesan tindak lanjut untuk praktikan berisiko',
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(icon: 'chat_bubble', text: 'Penerima'),
            ),
            LabListItem(
              leading: LabAvatar(s.asistenInitials),
              title: s.asisten,
              subtitle: 'Asisten Lab • ${s.kelas}',
            ),
          ],
        ),
        DosenStudentCard(student: s),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(icon: 'chat_bubble', text: 'Isi Pesan'),
            ),
            LabColumn(
              gap: 8,
              children: [
                Text('Tindak Lanjut', style: labText(14)),
                LabTabs(
                  labels: _followUps,
                  index: _followUp,
                  gap: 10,
                  hPadding: 12,
                  onChanged: (i) => setState(() => _followUp = i),
                ),
              ],
            ),
            DosenTextArea(
                label: 'Pesan untuk Asisten :', controller: _message),
          ],
        ),
        LabPrimaryButton(
          icon: 'send',
          label: 'Kirim Pesan',
          large: true,
          onTap: _send,
        ),
      ],
    );
  }
}
