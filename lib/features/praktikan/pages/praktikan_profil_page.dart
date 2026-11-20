import 'package:flutter/material.dart';

import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';

/// Figma: "Profil-Praktikan".
class PraktikanProfilPage extends StatefulWidget {
  final PraktikanNav nav;
  final VoidCallback onLogout;

  const PraktikanProfilPage({
    super.key,
    required this.nav,
    required this.onLogout,
  });

  @override
  State<PraktikanProfilPage> createState() => _PraktikanProfilPageState();
}

class _PraktikanProfilPageState extends State<PraktikanProfilPage> {
  void _openChangePassword() => widget.nav.ubahKataSandi(context);

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
              // Avatar yang sama dengan di Figma (dipakai juga oleh Laboran).
              Image.asset('assets/avatar_laboran.png', width: 64, height: 65),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nama Praktikan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labText(16, w: kBold, c: Colors.black)),
                    const SizedBox(height: 2),
                    Text('NIM 231402033',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labText(12, c: ItlgColors.textSubtle)),
                    const SizedBox(height: 6),
                    const LabChip.info('Praktikan • Ganjil 2026'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => labToast(context, 'Ubah profil belum tersedia'),
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
        const LabCard(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(icon: 'person', text: 'Data Diri'),
            ),
            _DataRow(
                icon: 'card_account_details_outline',
                label: 'NIM',
                value: '231402033'),
            _DataRow(
                icon: 'school_outline',
                label: 'Program Studi',
                value: 'Teknologi Informasi'),
            _DataRow(icon: 'calendar', label: 'Angkatan', value: '2023'),
            _DataRow(
                icon: 'people_group',
                label: 'Kelas Praktikum',
                value: 'TIF 3001 - Kelas C'),
            _DataRow(
                icon: 'envelope',
                label: 'Email',
                value: 'praktikan@students.usu.ac.id'),
            _DataRow(
                icon: 'phone_outline',
                label: 'No. HP',
                value: '0812-0000-0000'),
          ],
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
                  subtitle: 'Presensi, pengumuman, dan deadline tugas',
                  trailing: _Toggle(
                    value: store.pushOn,
                    onChanged: (v) => setState(() => store.pushOn = v),
                  ),
                  onTap: () => setState(() => store.pushOn = !store.pushOn),
                ),
                _SettingItem(
                  icon: 'lock_on',
                  title: 'Ubah Kata Sandi',
                  subtitle: 'Terakhir diubah 12 Sep 2026',
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
                  onTap: () => labToast(context,
                      'Pusat Bantuan Lab: Senin-Jumat 08:00-16:30 WIB'),
                ),
              ],
            ),
          ],
        ),
        LabOutlineButton(
          icon: 'sign_out',
          label: 'Keluar dari Akun',
          large: true,
          onTap: widget.onLogout,
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
  final double minHeight;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.minHeight = 58,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
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

/// Toggle 40 x 22 dengan knop putih 18 px.
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
