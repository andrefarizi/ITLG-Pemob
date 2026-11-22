import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';
import '../widgets/aslab_ui.dart';

/// Figma: "Sesi Aktif & QR Presensi-Aslab".
///
/// QR berganti otomatis tiap 5 menit dengan token stabil yang tersinkron ke
/// backend agar dapat langsung dipindai oleh Praktikan.
class AslabSesiAktifPage extends StatefulWidget {
  final AslabNav nav;
  const AslabSesiAktifPage({super.key, required this.nav});

  @override
  State<AslabSesiAktifPage> createState() => _AslabSesiAktifPageState();
}

class _AslabSesiAktifPageState extends State<AslabSesiAktifPage> {
  static const int _qrIntervalSeconds = 5 * 60; // 5 menit

  Timer? _timer;

  /// Token QR stabil selama siklus 5 menit.
  late String _qrData;

  /// Sisa waktu rotasi QR (detik).
  int _left = _qrIntervalSeconds;
  int _generation = 1;

  final PresensiSyncService _sync = PresensiSyncService.instance;

  String get _formattedLeft {
    final m = (_left ~/ 60).toString().padLeft(2, '0');
    final s = (_left % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onSyncChanged);
    _sync.refreshFromBackend();
    final existing = _sync.activeSession.qrToken;
    _qrData = existing.isNotEmpty
        ? existing
        : PresensiSyncService.buildQrToken(
            courseId: _sync.activeSession.courseId,
            meetingNumber: _sync.activeSession.meetingNumber,
            generation: _generation,
          );
    _rotateQr(publishImmediate: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_left > 1) {
        setState(() => _left--);
      } else {
        setState(() {
          _left = _qrIntervalSeconds;
          _generation++;
        });
        _rotateQr();
      }
    });
  }

  Future<void> _rotateQr({bool publishImmediate = false}) async {
    final token = await _sync.rotateActiveQrToken(_generation);
    if (!mounted) return;
    if (publishImmediate || _qrData != token) {
      setState(() => _qrData = token);
    }
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
    final session = _sync.activeSession;
    final course = PraktikumSyncService.instance.courseById(session.courseId);
    return LabSubPage(
      onLogoTap: nav.home,
      children: [
        LabCard(
          children: [
            PrakSpaceRow(
              left: session.isActive
                  ? const LabChip.live('Sesi Berlangsung')
                  : const LabChip.idle('Sesi Ditutup'),
              right: AslabElapsedPill(start: session.startedAt),
            ),
            AslabClassTitle(kelas: course.kelas, name: course.name),
            Row(
              children: [
                Flexible(
                  child: LabMeta(icon: 'clock', text: course.jadwalAbsensi),
                ),
                const SizedBox(width: 24),
                Flexible(
                  child: LabMeta(icon: 'location', text: session.labName),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (session.allowQr) const LabTag.blue('QR Dinamis'),
                if (session.allowButton)
                  LabTag.blue(
                      'Tombol + Lokasi ${session.radiusMeters.toInt()} m'),
                if (session.requireSignature)
                  const LabTag.blue('Wajib Tanda Tangan'),
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
                      key: ValueKey<String>(_qrData),
                      data: _qrData,
                      version: QrVersions.auto,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                      gapless: true,
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
                  Text(_formattedLeft,
                      style: labText(22, w: kBold, c: ItlgColors.primary)),
                ],
              ),
            ),
            LabProgress(
              label: 'Auto-refresh setiap 5 menit',
              value: _formattedLeft,
              fraction: _left / _qrIntervalSeconds,
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
