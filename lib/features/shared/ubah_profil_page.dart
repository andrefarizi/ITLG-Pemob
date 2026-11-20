import 'package:flutter/material.dart';

import '../../core/widgets/itlg_ui.dart';
import '../laboran/widgets/laboran_ui.dart';
import '../praktikan/widgets/praktikan_ui.dart';
import 'profil_data.dart';

/// Halaman "Ubah Profil" untuk semua peran. Nama, email, dan No. HP bisa
/// diubah; NIM/NIP hanya ditampilkan. Perubahan disimpan ke [ProfilData].
class UbahProfilPage extends StatefulWidget {
  final ProfilData data;
  final String roleLabel;
  final VoidCallback? onLogoTap;

  const UbahProfilPage({
    super.key,
    required this.data,
    required this.roleLabel,
    this.onLogoTap,
  });

  @override
  State<UbahProfilPage> createState() => _UbahProfilPageState();
}

class _UbahProfilPageState extends State<UbahProfilPage> {
  late final TextEditingController _name =
      TextEditingController(text: widget.data.name);
  late final TextEditingController _email =
      TextEditingController(text: widget.data.email);
  late final TextEditingController _phone =
      TextEditingController(text: widget.data.phone);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _validate(String name, String email, String phone) {
    if (name.isEmpty) return 'Nama tidak boleh kosong';
    final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!emailOk) return 'Format email tidak valid';
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 14) {
      return 'No. HP harus 10–14 digit';
    }
    return null;
  }

  void _simpan() {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    final error = _validate(name, email, phone);
    if (error != null) {
      labToast(context, error);
      return;
    }
    widget.data.update(name: name, email: email, phone: phone);
    Navigator.of(context).maybePop();
    labToast(context, 'Profil berhasil diperbarui');
  }

  @override
  Widget build(BuildContext context) {
    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      children: [
        LabCard(
          children: [
            LabOverline(overline: widget.roleLabel, title: 'Ubah Profil'),
            Row(
              children: [
                Image.asset('assets/avatar_laboran.png', width: 64, height: 65),
                const SizedBox(width: 11),
                Expanded(
                  child: LabColumn(
                    gap: 2,
                    children: [
                      Text(widget.data.idLabel,
                          style: labText(11,
                              w: kMedium, c: ItlgColors.textSubtle)),
                      Text(widget.data.idValue,
                          style: labText(14, w: kBold)),
                      Text('${widget.data.idLabel} tidak dapat diubah.',
                          style: labText(11, c: ItlgColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        LabCard(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(icon: 'person', text: 'Data Diri'),
            ),
            PrakField(
              label: 'Nama Lengkap',
              child: PrakInput(controller: _name, leadingIcon: 'person'),
            ),
            PrakField(
              label: 'Email',
              child: PrakInput(controller: _email, leadingIcon: 'envelope'),
            ),
            PrakField(
              label: 'No. HP',
              child:
                  PrakInput(controller: _phone, leadingIcon: 'phone_outline'),
            ),
          ],
        ),
        LabPrimaryButton(
          icon: 'check',
          label: 'Simpan Perubahan',
          large: true,
          onTap: _simpan,
        ),
        LabOutlineButton(
          icon: 'cross',
          label: 'Batal',
          large: true,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
