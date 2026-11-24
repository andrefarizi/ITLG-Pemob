import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/shift_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../shared/lab_actions.dart';
import '../../shared/profil_data.dart';
import '../../shared/ubah_profil_page.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../aslab_nav.dart';

/// Halaman Profil Asisten Lab.
class AslabProfilPage extends StatefulWidget {
  final AslabNav nav;
  final VoidCallback onLogout;

  const AslabProfilPage({
    super.key,
    required this.nav,
    required this.onLogout,
  });

  @override
  State<AslabProfilPage> createState() => _AslabProfilPageState();
}

class _AslabProfilPageState extends State<AslabProfilPage> {
  ProfilData get _p => ProfilData.aslab;

  void _onProfil() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _p.addListener(_onProfil);
  }

  @override
  void dispose() {
    _p.removeListener(_onProfil);
    super.dispose();
  }

  void _openUbahProfil() {
    labPush(
      context,
      UbahProfilPage(
        data: _p,
        roleLabel: 'Asisten Lab',
        onLogoTap: widget.nav.home,
      ),
    );
  }

  void _openChangePassword() => widget.nav.ubahKataSandi(context);

  Future<void> _confirmLogout() async {
    final ok = await labShowConfirmDialog(
      context,
      icon: 'sign_out',
      title: 'Keluar dari Akun ITLG Mobile?',
      message:
          'Kamu perlu masuk lagi dengan NIM/NIP dan kata sandi untuk memakai aplikasi.',
      cancelLabel: 'Batal',
      confirmLabel: 'Ya, Keluar',
    );
    if (ok) widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.nav.store;
    return LabTabBody(
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 89),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: ItlgColors.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            boxShadow: ItlgShadows.outline,
          ),
          child: Row(
            children: [
              LabInitialAvatar(
                initials: _p.initials,
                size: 64,
                hasPhotoBadge: _p.photoSource != null,
                photoSource: _p.photoSource,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labText(16, w: kBold, c: Colors.black)),
                    const SizedBox(height: 2),
                    Text('${_p.idLabel} ${_p.idValue}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labText(12, c: ItlgColors.textSubtle)),
                    const SizedBox(height: 6),
                    const LabChip.info('Asisten Lab • Ganjil 2026'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openUbahProfil,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: LabColors.tile,
                    borderRadius: BorderRadius.circular(12),
                                      ),
                  child: const LabIcon('pencil',
                      size: 18, color: ItlgColors.primary),
                ),
              ),
            ],
          ),
        ),
        ListenableBuilder(
          listenable: Listenable.merge([
            PraktikumSyncService.instance,
            ShiftSyncService.instance,
          ]),
          builder: (_, __) {
            final prak = PraktikumSyncService.instance;
            final shift = ShiftSyncService.instance;
            final myShifts = shift.allShifts
                .where((s) => s.asistenName == _p.name)
                .map((s) => s.dayLabel.split(',').first)
                .toSet()
                .toList();
            final shiftText = myShifts.isNotEmpty
                ? myShifts.join(' & ')
                : 'Senin & Kamis';
            return LabCard(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: LabSectionTitle(icon: 'person', text: 'Data Diri'),
                ),
                _DataRow(
                    icon: 'card_account_details_outline',
                    label: 'NIM',
                    value: _p.idValue),
                const _DataRow(
                    icon: 'school_outline',
                    label: 'Program Studi',
                    value: 'Teknologi Informasi'),
                _DataRow(
                    icon: 'book_open',
                    label: 'Praktikum Diampu',
                    value: '${prak.courses.length} Praktikum'),
                _DataRow(
                    icon: 'star',
                    label: 'Rating Asisten',
                    value: '★ ${prak.overallAsistenRatingLabel()} / 5,0'),
                _DataRow(
                    icon: 'calendar',
                    label: 'Jadwal Mengajar',
                    value: shiftText),
                _DataRow(icon: 'envelope', label: 'Email', value: _p.email),
                _DataRow(
                    icon: 'phone_outline', label: 'No. HP', value: _p.phone),
              ],
            );
          },
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(
                  icon: 'settings_outline', text: 'Pengaturan'),
            ),
            LabColumn(
              gap: 8,
              children: [
                _SettingItem(
                  icon: 'bell',
                  title: 'Notifikasi Push',
                  subtitle: 'Tukar jadwal, izin, dan pengumpulan tugas',
                  trailing: _Toggle(
                    value: store.pushOn,
                    onChanged: (v) => setState(() => store.pushOn = v),
                  ),
                  onTap: () => setState(() => store.pushOn = !store.pushOn),
                ),
                _SettingItem(
                  icon: 'lock_on',
                  title: 'Ubah Kata Sandi',
                  subtitle: 'Ganti kata sandi akun anda',
                  trailing: const LabIcon('chevron_right',
                      size: 16, color: ItlgColors.primary),
                  onTap: _openChangePassword,
                ),
                _SettingItem(
                  icon: 'h_help',
                  title: 'Pusat Bantuan Lab',
                  subtitle: 'Gedung Teknologi Informasi • ITLG',
                  trailing: const LabIcon('chevron_right',
                      size: 16, color: ItlgColors.primary),
                  onTap: () => labShowHelpCenter(context),
                ),
              ],
            ),
          ],
        ),
        LabOutlineButton(
          icon: 'sign_out',
          label: 'Keluar dari Akun',
          large: true,
          onTap: _confirmLogout,
        ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _DataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LabMeta(icon: icon, text: label),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labText(12, w: kBold),
          ),
        ),
      ],
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ItlgShadows.outline,
        ),
        child: Row(
          children: [
            LabIconTile(icon),
            const SizedBox(width: 10),
            Expanded(
              child: LabColumn(
                gap: 2,
                children: [
                  Text(title, style: labText(12, w: kBold)),
                  Text(subtitle,
                      style:
                          labText(11, w: kMedium, c: ItlgColors.textSubtle)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// Toggle dengan knop putih.
class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 40,
        height: 22,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? ItlgColors.primary : LabColors.toggleOff,
          borderRadius: BorderRadius.circular(11),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: ItlgShadows.outline,
            ),
          ),
        ),
      ),
    );
  }
}
