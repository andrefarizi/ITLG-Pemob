import 'package:flutter/material.dart';

import '../../../core/services/nilai_sync_service.dart';
import '../../../core/services/shift_sync_service.dart';
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

  final NilaiSyncService _sync = NilaiSyncService.instance;
  late final TextEditingController _message =
      TextEditingController(text: widget.student.message);
  late int _followUp = widget.student.followUp;
  late String _selectedAssistant = widget.student.asisten;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _sync.refreshFromBackend();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickAssistant() async {
    final options = <String>{
      widget.student.asisten,
      ...ShiftSyncService.instance.availableAssistantNames(),
    }.toList();
    final idx = options.indexOf(_selectedAssistant);
    final picked = await dosenShowPicker(
      context,
      title: 'Pilih Asisten Penerima',
      options: options,
      selected: idx < 0 ? 0 : idx,
    );
    if (picked != null && mounted) {
      setState(() => _selectedAssistant = options[picked]);
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    final text = _message.text.trim();
    if (text.isEmpty) {
      labToast(context, 'Pesan untuk asisten tidak boleh kosong');
      return;
    }
    setState(() => _sending = true);
    FocusScope.of(context).unfocus();
    await _sync.sendAssistantFollowUp(
      studentNim: widget.student.nim,
      studentName: widget.student.name,
      assistantName: _selectedAssistant,
      followUpType: _followUps[_followUp],
      message: text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    dosenShowResult(
      context,
      icon: 'chat_bubble',
      title: 'Pesan Terkirim',
      message:
          '$_selectedAssistant dan praktikan menerima tindak lanjut anda secara real-time.',
      button: 'Kembali ke Peringatan',
      onPressed: () => dosenPopToShell(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return ListenableBuilder(
      listenable: _sync,
      builder: (context, _) {
        final history = _sync.followUpsForStudent(s.nim);
        final initials = ShiftSyncService.initialsOf(_selectedAssistant);
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
                  leading: LabAvatar(initials),
                  title: _selectedAssistant,
                  subtitle: 'Asisten Lab • ${s.kelas} (ketuk untuk ganti)',
                  onTap: _pickAssistant,
                ),
                if (history.isNotEmpty)
                  LabMeta(
                    icon: 'circle_check',
                    text:
                        'Terakhir dihubungi (${history.first.followUpType}) • ${history.first.formattedClock}',
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
                  label: 'Pesan untuk Asisten :',
                  controller: _message,
                  hint: 'Tulis arahan tindak lanjut untuk asisten...',
                ),
              ],
            ),
            LabPrimaryButton(
              icon: 'send',
              label: 'Kirim Pesan',
              large: true,
              onTap: _send,
            ),
            // Figma: Kartu "Riwayat Arahan" (5601:3086)
            if (history.isNotEmpty)
              LabCard(
                gap: 12,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: LabSectionTitle(
                        icon: 'clock', text: 'Riwayat Arahan'),
                  ),
                  for (final f in history)
                    LabListItem(
                      leading: const LabIconTile('chat_bubble'),
                      title: '${f.followUpType} • ${f.formattedClock}',
                      subtitle: 'Ke ${f.assistantName} • ${f.message}',
                      titleSize: 12,
                      trailing: f.isDone
                          ? const LabChip.live('Ditindaklanjuti')
                          : const LabChip.warn('Menunggu'),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
