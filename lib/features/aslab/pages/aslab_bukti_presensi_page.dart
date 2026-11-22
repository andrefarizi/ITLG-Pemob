import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../../praktikan/widgets/prak_google_map.dart';
import '../aslab_nav.dart';
import '../aslab_store.dart';

/// Figma: "Bukti Presensi-Aslab".
class AslabBuktiPresensiPage extends StatelessWidget {
  final AslabNav nav;
  final AslabPresence? presence;
  final String courseId;
  final int meetingNumber;
  const AslabBuktiPresensiPage({
    super.key,
    required this.nav,
    this.presence,
    this.courseId = 'pemob',
    this.meetingNumber = 4,
  });

  @override
  Widget build(BuildContext context) {
    final presensi = PresensiSyncService.instance;
    final course = PraktikumSyncService.instance.courseById(courseId);
    final classShort = course.kelas.contains(' - ')
        ? course.kelas.split(' - ').last
        : course.kelas;
    final meetingObj = course.meetings.firstWhere(
      (m) => m.number == meetingNumber,
      orElse: () => course.meetings.first,
    );
    final dateShort = meetingObj.date.split(' • ').first;
    final st = presence?.student ?? kRina;
    final rec = presensi.recordFor(courseId, meetingNumber, st.nim) ??
        presensi.recordFor(courseId, 4, st.nim) ??
        presensi.recordFor(courseId, 5, st.nim);
    final lat = rec?.lat ?? 3.5621;
    final lng = rec?.lng ?? 98.6600;
    final dist = rec?.distanceMeters != null
        ? '${rec!.distanceMeters!.round()} meter'
        : '12 meter';
    final clock = rec != null
        ? '${rec.recordedAt.toLocal().hour.toString().padLeft(2, '0')}:${rec.recordedAt.toLocal().minute.toString().padLeft(2, '0')} WIB'
        : '08:02 WIB';
    final methodText = rec?.method == 'qr'
        ? 'Diverifikasi dengan Pindai QR Presensi'
        : 'Diverifikasi dengan Tombol Hadir + Lokasi';

    return LabSubPage(
      onLogoTap: nav.home,
      children: [
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabChip.live('Hadir'),
              right: LabTag.blue('Pertemuan $meetingNumber'),
            ),
            LabPerson(
              initials: st.initials,
              name: st.name,
              caption: '${st.nim} • ${course.kelas}',
            ),
            LabColumn(
              gap: 8,
              cross: CrossAxisAlignment.start,
              children: [
                LabMeta(
                  icon: 'book_open',
                  text: 'Praktikum ${course.name} • $classShort',
                ),
                LabMeta(icon: 'clock', text: '$dateShort • $clock'),
                LabMeta(
                  icon: 'gesture_tap_button',
                  text: methodText,
                ),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            const PrakSpaceRow(
              left: LabSectionTitle(icon: 'location', text: 'Lokasi Presensi'),
              right: LabChip.live('Di Dalam Area'),
            ),
            const PrakGoogleMap(inside: true),
            LabInsetBox(
              child: LabColumn(
                gap: 10,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LabIcon('location',
                          size: 16, color: Color(0xFF850909)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LabColumn(
                          gap: 2,
                          children: [
                            Text('Lokasi Saat Presensi',
                                style: labText(11,
                                    w: kMedium, c: const Color(0xFF6B7280))),
                            Text('${course.room}, Gedung C Lantai 2',
                                style: labText(12, w: kBold)),
                            Text(
                                'Fasilkom-TI USU, Jl. Alumni, Padang Bulan, '
                                'Medan',
                                style: labText(12,
                                    c: const Color(0xFF5B636B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const PrakDivider(),
                  PrakSpaceRow(
                    left: LabMeta(
                        icon: 'crosshairs_gps',
                        text:
                            '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'),
                    right: LabMeta(icon: 'clock', text: 'Tercatat $clock'),
                  ),
                ],
              ),
            ),
            LabStatRow(
              gap: 13,
              stats: [
                LabStat(
                  icon: 'map_marker_radius_outline',
                  label: 'Jarak dari Lab',
                  value: dist,
                ),
                const LabStat(
                  icon: 'crosshairs_gps',
                  label: 'Akurasi GPS',
                  value: '± 5 meter',
                ),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabSectionTitle(
                  icon: 'signature_freehand', text: 'Tanda Tangan'),
              right: LabMeta(icon: 'clock', text: clock),
            ),
            SizedBox(
              height: 170,
              child: LayoutBuilder(
                builder: (context, box) => Stack(
                  children: [
                    const Positioned.fill(child: LabInsetBox(child: SizedBox())),
                    Positioned(
                      left: (box.maxWidth - 230) / 2,
                      top: 26,
                      width: 230,
                      height: 96,
                      child: Image.asset('assets/praktikan_signature.png',
                          fit: BoxFit.fill),
                    ),
                    Positioned(
                      left: 25,
                      right: 25,
                      top: 131.25,
                      child: Container(
                          height: 1.5, color: LabColors.divider),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 144,
                      child: Text(
                        'Ditandatangani oleh ${st.name}',
                        textAlign: TextAlign.center,
                        style: labText(11,
                            w: kMedium, c: const Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        LabOutlineButton(
          icon: 'pencil',
          label: 'Ubah Status Kehadiran',
          large: true,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
