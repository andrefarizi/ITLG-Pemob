import 'package:flutter/material.dart';

import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Figma: "Ajukan Izin-Praktikan".
class PraktikanAjukanIzinPage extends StatefulWidget {
  final PraktikanNav nav;
  final PrakCourse course;
  final PrakMeeting meeting;

  const PraktikanAjukanIzinPage({
    super.key,
    required this.nav,
    required this.course,
    required this.meeting,
  });

  @override
  State<PraktikanAjukanIzinPage> createState() =>
      _PraktikanAjukanIzinPageState();
}

class _PraktikanAjukanIzinPageState extends State<PraktikanAjukanIzinPage> {
  final TextEditingController _alasan = TextEditingController();
  int _jenis = 0;
  final List<PrakFile> _files = [
    const PrakFile('surat_dokter.pdf', 'PDF • 420 KB'),
  ];

  static const List<(String, String)> _options = [
    ('health', 'Sakit'),
    ('person', 'Izin'),
    ('camera', 'Kendala QR'),
  ];

  @override
  void dispose() {
    _alasan.dispose();
    super.dispose();
  }

  void _addFile() {
    setState(() => _files.add(
        PrakFile('lampiran_${_files.length + 1}.pdf', 'PDF • 256 KB')));
  }

  void _kirim() {
    if (widget.meeting.status == PrakAttend.upcoming) {
      widget.meeting.status = PrakAttend.pending;
    }
    Navigator.of(context).maybePop();
    labToast(context, 'Pengajuan izin terkirim ke asisten');
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final m = widget.meeting;
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            const LabOverline(overline: 'Izin Praktikum', title: 'Ajukan Izin'),
            LabInsetBox(
              child: LabColumn(
                gap: 10,
                children: [
                  PrakSpaceRow(
                    left: Text('Praktikum ${c.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labText(12, w: kBold)),
                    right: LabTag.blue('Pertemuan ${m.number}'),
                  ),
                  LabMeta(icon: 'calendar', text: m.date),
                  LabMeta(
                    icon: 'door',
                    text: '${c.room} • Asisten: ${c.asisten}',
                  ),
                ],
              ),
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child:
                  LabSectionTitle(icon: 'file', text: 'Detail Pengajuan'),
            ),
            PrakField(
              label: 'Jenis Pengajuan',
              child: PrakOptionChips(
                options: _options,
                index: _jenis,
                onChanged: (i) => setState(() => _jenis = i),
              ),
            ),
            PrakField(
              label: 'Alasan Izin :',
              child: PrakTextArea(
                controller: _alasan,
                height: 96,
                hint: 'Jelaskan alasan anda tidak dapat hadir...',
              ),
            ),
            PrakField(
              label: 'Surat / Lampiran',
              child: PrakUploadBox(
                title: 'Tarik atau Pilih Surat / Lampiran',
                subtitle: 'Format didukung PDF, PNG, JPG',
                onTap: _addFile,
              ),
            ),
            LabOutlineButton(
              icon: 'add_outline',
              label: 'Unggah Berkas',
              large: true,
              onTap: _addFile,
            ),
            if (_files.isNotEmpty)
              PrakField(
                label: 'Berkas Terunggah',
                child: LabColumn(
                  gap: 8,
                  children: [
                    for (final f in _files)
                      PrakFileItem(
                        name: f.name,
                        meta: f.meta,
                        action: 'delete_filled',
                        onAction: () => setState(() => _files.remove(f)),
                      ),
                  ],
                ),
              ),
          ],
        ),
        const PrakNotice.info(
          icon: 'info',
          text: 'Pengajuan diperiksa asisten. Status kehadiran pertemuan ini '
              'berubah setelah disetujui.',
        ),
        LabPrimaryButton(
          icon: 'send',
          label: 'Kirim Pengajuan',
          large: true,
          onTap: _kirim,
        ),
      ],
    );
  }
}
