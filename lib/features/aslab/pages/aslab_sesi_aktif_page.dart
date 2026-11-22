import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../widgets/aslab_ui.dart';

/// Figma: "Sesi Aktif & QR Presensi-Aslab".
///
/// QR berganti tiap 15 detik (hitung mundur berjalan, gambar QR dibalik
/// sebagai tanda kode baru).
class AslabSesiAktifPage extends StatefulWidget {
  final AslabNav nav;
  const AslabSesiAktifPage({super.key, required this.nav});

  @override
  State<AslabSesiAktifPage> createState() => _AslabSesiAktifPageState();
}

class _AslabSesiAktifPageState extends State<AslabSesiAktifPage> {
  Timer? _timer;

  /// Kode QR session saat ini — berubah tiap [_left] habis.
  /// Format: ITLG-{sessionId}-{generation}-{timestamp}
  String get _qrData =>
      'ITLG-PEMOB-PERTEMUAN5-GEN$_generation-${DateTime.now().millisecondsSinceEpoch ~/ 1000}';

  /// Figma: 12 detik tersisa.
  int _left = 12;
  int _generation = 0;

  final PresensiSyncService _sync = PresensiSyncService.instance;

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onSyncChanged);
    _sync.refreshFromBackend();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_left > 1) {
          _left--;
        } else {
          _left = 15;
          _generation++;
        }
      });
    });
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncChanged);
    _timer?.cancel();
    super.dispose();
  }

  void _onSyncChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _akhiri() async {
    await _sync.endActiveSession();
    if (!mounted) return;
    labToast(context, 'Sesi presensi diakhiri');
    widget.nav.goTab(AslabTab.absensi);
  }

  @override
  Widget build(BuildContext context) {
    final nav = widget.nav;
    return LabSubPage(
      onLogoTap: nav.home,
      children: [
        LabCard(
          children: [
            PrakSpaceRow(
              left: const LabChip.live('Sesi Berlangsung'),
              right: AslabElapsedPill(start: nav.store.sessionStart),
            ),
            const AslabClassTitle(),
            const Row(
              children: [
                Flexible(
                  child:
                      LabMeta(icon: 'clock', text: 'Senin • 08:00–09:40 WIB'),
                ),
                SizedBox(width: 24),
                Flexible(
                  child: LabMeta(icon: 'location', text: 'Lab Komputer 1'),
                ),
              ],
            ),
            const Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                LabTag.blue('QR Dinamis'),
                LabTag.blue('Tombol + Lokasi 50 m'),
                LabTag.blue('Wajib Tanda Tangan'),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            const PrakSpaceRow(
              left: LabSectionTitle(icon: 'qrcode', text: 'QR Code Presensi'),
              right: LabTag.blue('Dinamis'),
            ),
            InnerShadowBox(
              radius: 12,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: QrImageView(
                      key: ValueKey<int>(_generation),
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 220,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF8B1A1A),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1A1A1A),
                      ),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Diperbarui otomatis dalam',
                      style: labText(12, c: ItlgColors.textSubtle)),
                  const SizedBox(height: 2),
                  Text('$_left detik',
                      style: labText(22, w: kBold, c: ItlgColors.primary)),
                ],
              ),
            ),
            LabProgress(
              label: 'Auto-refresh setiap 15 detik',
              value: '$_left dtk',
              fraction: _left / 15,
              color: ItlgColors.primary,
            ),
            Row(
              children: [
                const LabIcon('shield_check_outline',
                    size: 14, color: ItlgColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kode lama langsung hangus sehingga tangkapan layar tidak '
                    'dapat dipakai untuk presensi.',
                    style: labText(12, c: ItlgColors.textMuted),
                  ),
                ),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            Builder(
              builder: (_) {
                final session = _sync.activeSession;
                final liveList = _sync
                    .recordsForMeeting(session.courseId, session.meetingNumber)
                    .where((r) => r.status.name == 'hadir')
                    .toList();
                final totalHadir = (15 + liveList.length).clamp(0, 24);
                final pct = ((totalHadir * 100) / 24).round();
                return LabColumn(
                  gap: 14,
                  children: [
                    PrakSpaceRow(
                      left: const LabSectionTitle(
                          icon: 'people_group', text: 'Kehadiran Praktikan'),
                      right: Text('$totalHadir / 24',
                          style: labText(16, w: kBold, c: ItlgColors.primary)),
                    ),
                    LabProgress(
                      label: 'Rasio Kehadiran',
                      value: '$pct%',
                      fraction: totalHadir / 24,
                    ),
                    LabColumn(
                      gap: 8,
                      children: [
                        for (final rec in liveList.take(5))
                          LabListItem(
                            leading: LabAvatar(rec.initials),
                            title: rec.userName,
                            subtitle: rec.userIdentifier,
                            trailing: LabMeta(
                                icon: 'check',
                                text: rec.shortProofLabel,
                                color: LabColors.green),
                            onTap: () => nav.buktiPresensi(context),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        LabOutlineButton(
          icon: 'stop',
          label: 'Akhiri Sesi',
          large: true,
          onTap: _akhiri,
        ),
      ],
    );
  }
}
