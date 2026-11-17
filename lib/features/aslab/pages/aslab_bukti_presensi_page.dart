import 'package:flutter/material.dart';

import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';

/// Figma: "Bukti Presensi-Aslab".
class AslabBuktiPresensiPage extends StatelessWidget {
  final AslabNav nav;
  const AslabBuktiPresensiPage({super.key, required this.nav});

  @override
  Widget build(BuildContext context) {
    return LabSubPage(
      onLogoTap: nav.home,
      children: [
        const LabCard(
          children: [
            PrakSpaceRow(
              left: LabChip.live('Hadir'),
              right: LabTag.blue('Pertemuan 4'),
            ),
            LabPerson(
              initials: 'RN',
              name: 'Rina Novita',
              caption: '231402045 • TIF 3001 - Kelas C',
            ),
            LabColumn(
              gap: 8,
              cross: CrossAxisAlignment.start,
              children: [
                LabMeta(
                  icon: 'book_open',
                  text: 'Praktikum Pemrograman Mobile • Kelas C',
                ),
                LabMeta(icon: 'clock', text: 'Sen, 28 Sep 2026 • 08:02 WIB'),
                LabMeta(
                  icon: 'gesture_tap_button',
                  text: 'Diverifikasi dengan Tombol Hadir + Lokasi',
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
            const PrakLocationMap(inside: true),
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
                            Text('Lab Komputer 1, Gedung C Lantai 2',
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
                  const PrakSpaceRow(
                    left:
                        LabMeta(icon: 'crosshairs_gps', text: '3.5621, 98.6600'),
                    right: LabMeta(icon: 'clock', text: 'Tercatat 08:02 WIB'),
                  ),
                ],
              ),
            ),
            const LabStatRow(
              gap: 13,
              stats: [
                LabStat(
                  icon: 'map_marker_radius_outline',
                  label: 'Jarak dari Lab',
                  value: '12 meter',
                ),
                LabStat(
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
            const PrakSpaceRow(
              left: LabSectionTitle(
                  icon: 'signature_freehand', text: 'Tanda Tangan'),
              right: LabMeta(icon: 'clock', text: '08:02 WIB'),
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
                        'Ditandatangani oleh Rina Novita',
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
