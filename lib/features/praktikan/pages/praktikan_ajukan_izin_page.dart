import 'package:flutter/material.dart';

import '../../../core/services/file_upload_service.dart';
import '../../../core/services/lab_desk_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../auth/auth_controller.dart';
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
  final List<PrakFile> _files = [];

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

  Future<void> _addFile() async {
    final cid = widget.course.id.isNotEmpty ? widget.course.id : 'pemob';
    final picked = await FileUploadService.instance.pickAndUpload(
      folder: 'izin/$cid/m${widget.meeting.number}',
    );
    if (picked == null || !mounted) return;
    setState(() => _files.add(PrakFile(picked.name, picked.metaLabel)));
    labToast(
      context,
      picked.uploadedToCloud
          ? '${picked.name} berhasil diunggah ke BE'
          : '${picked.name} dipilih dari perangkat',
    );
  }

  Future<void> _kirim() async {
    final auth = AuthController.instance;
    final jenisLabel = const ['Izin Sakit', 'Izin', 'Kendala QR'][_jenis];
    final dateShort = widget.meeting.date.split(' • ').first;
    final activeDesk = _jenis == 2
        ? LabDeskSyncService.instance.bookedDeskForUser(auth.userIdentifier)
        : null;
    await PresensiSyncService.instance.submitLeaveRequest(
      courseId: widget.course.id.isNotEmpty ? widget.course.id : 'pemob',
      meetingNumber: widget.meeting.number,
      userIdentifier: auth.userIdentifier,
      userName: auth.userName,
      leaveType: jenisLabel,
      pertemuanLabel: '${widget.meeting.number} • $dateShort',
      note: _alasan.text.trim(),
      fileName: _files.isNotEmpty ? _files.first.name : null,
      deskNumber: activeDesk,
    );
    if (widget.meeting.status == PrakAttend.upcoming) {
      widget.meeting.status = PrakAttend.pending;
    }
    if (!mounted) return;
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
              label: _jenis == 2
                  ? 'Keterangan Kendala & Nomor Meja :'
                  : 'Alasan Izin :',
              child: PrakTextArea(
                controller: _alasan,
                height: 96,
                hint: _jenis == 2
                    ? 'Contoh: Kamera HP rusak, saya hadir di ${c.room}, Meja 14.'
                    : 'Jelaskan alasan anda tidak dapat hadir...',
              ),
            ),
            PrakField(
              label: _jenis == 2
                  ? 'Foto Bukti Kehadiran di Lab (Opsional)'
                  : 'Surat / Lampiran',
              child: PrakUploadBox(
                camera: _jenis == 2,
                title: _jenis == 2
                    ? 'Ambil atau Pilih Foto Bukti'
                    : 'Tarik atau Pilih Surat / Lampiran',
                subtitle: _jenis == 2
                    ? 'Format didukung PNG, JPG'
                    : 'Format didukung PDF, PNG, JPG',
                onTap: _addFile,
              ),
            ),
            LabOutlineButton(
              icon: 'add_outline',
              label: 'Unggah Berkas',
              large: true,
              onTap: _addFile,
            ),
            PrakField(
              label: 'Berkas Terunggah',
              child: _files.isEmpty
                  ? Text(
                      'Belum ada berkas dipilih.',
                      style: labText(12, c: LabColors.textGrey),
                    )
                  : LabColumn(
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
        PrakNotice.info(
          icon: 'info',
          text: _jenis == 2
              ? 'Asisten akan mengecek kehadiranmu langsung di lab, lalu menandai kamu hadir.'
              : 'Pengajuan diperiksa asisten. Status kehadiran pertemuan ini '
                  'berubah setelah disetujui.',
        ),
        LabPrimaryButton(
          icon: 'send',
          label: _jenis == 2 ? 'Kirim Laporan Kendala QR' : 'Kirim Pengajuan',
          large: true,
          onTap: _kirim,
        ),
      ],
    );
  }
}
