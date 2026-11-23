import 'package:flutter/material.dart';

import '../../core/services/file_upload_service.dart';
import '../../core/widgets/itlg_ui.dart';
import '../laboran/widgets/laboran_ui.dart';
import '../praktikan/widgets/praktikan_ui.dart';
import 'profil_data.dart';

/// Figma: "Ubah Profil (Praktikan)" (5822:3228) + "Sheet Ganti Foto Profil" (5822:3396).
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
  late final TextEditingController _phone =
      TextEditingController(text: widget.data.phone);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _validate(String name, String phone) {
    if (name.isEmpty) return 'Nama tidak boleh kosong';
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 14) {
      return 'No. HP harus 10–14 digit';
    }
    return null;
  }

  Future<void> _openPhotoSheet() async {
    final choice = await labShowCustomSheet<int>(
      context,
      title: 'Ganti Foto Profil',
      child: LabColumn(
        gap: 8,
        children: [
          _SheetOption(
            label: 'Ambil Foto dari Kamera',
            onTap: () => Navigator.of(context).pop(0),
          ),
          _SheetOption(
            label: 'Pilih dari Galeri',
            onTap: () => Navigator.of(context).pop(1),
          ),
          _SheetOption(
            label: 'Hapus Foto Profil',
            danger: true,
            onTap: () => Navigator.of(context).pop(2),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 0 || choice == 1) {
      final uploaded = await FileUploadService.instance.pickAndUpload(
        folder: 'avatars',
        imagesOnly: true,
      );
      if (!mounted) return;
      if (uploaded == null) {
        labToast(context, 'Pemilihan foto dibatalkan');
        return;
      }
      final source = uploaded.remoteUrl ?? uploaded.localPath;
      await widget.data.setPhotoSource(source);
      if (!mounted) return;
      setState(() {});
      labToast(
        context,
        uploaded.uploadedToCloud
            ? 'Foto profil diunggah ke server & diperbarui'
            : 'Foto profil diperbarui dari perangkat',
      );
    } else if (choice == 2) {
      await widget.data.setPhotoSource(null);
      if (!mounted) return;
      setState(() {});
      labToast(context, 'Foto profil dihapus, kembali ke avatar inisial');
    }
  }

  Future<void> _simpan() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final error = _validate(name, phone);
    if (error != null) {
      labToast(context, error);
      return;
    }
    try {
      await widget.data.update(
        name: name,
        email: widget.data.email,
        phone: phone,
      );
      if (!mounted) return;
      Navigator.of(context).maybePop();
      labToast(context, 'Profil berhasil diperbarui');
    } catch (e) {
      if (!mounted) return;
      labToast(context, 'Gagal menyimpan profil: $e');
    }
  }

  Widget _lockedField({required String label, required String value}) {
    return LabColumn(
      gap: 6,
      children: [
        Text(label, style: labText(14, c: ItlgColors.text)),
        InnerShadowBox(
          radius: 12,
          height: 48,
          color: ItlgColors.field,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labText(12, w: kSemiBold, c: ItlgColors.text),
                ),
              ),
              const SizedBox(width: 8),
              const LabIcon('lock_on', size: 16, color: ItlgColors.textSubtle),
            ],
          ),
        ),
        Text(
          'Tidak bisa diubah, mengikuti data akademik.',
          style: labText(12, c: ItlgColors.textMuted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.data.photoSource != null;
    return LabSubPage(
      onLogoTap: widget.onLogoTap,
      gap: 24,
      children: [
        Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openPhotoSheet,
              child: SizedBox(
                width: 104,
                height: 104,
                child: Stack(
                  children: [
                    Positioned(
                      left: 4,
                      top: 4,
                      child: LabInitialAvatar(
                        initials: widget.data.initials,
                        size: 96,
                        fontSize: 33,
                        hasPhotoBadge: hasPhoto,
                        photoSource: widget.data.photoSource,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ItlgColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const LabIcon('camera',
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ketuk foto untuk mengganti dari kamera atau galeri',
              textAlign: TextAlign.center,
              style: labText(11, w: kMedium, c: ItlgColors.textSubtle),
            ),
          ],
        ),
        LabCard(
          gap: 14,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: LabSectionTitle(icon: 'person', text: 'Data Diri'),
            ),
            PrakField(
              label: 'Nama Lengkap',
              child: PrakInput(controller: _name),
            ),
            _lockedField(
              label: widget.data.idLabel,
              value: widget.data.idValue,
            ),
            _lockedField(
              label: 'Email USU',
              value: widget.data.email,
            ),
            PrakField(
              label: 'No. HP',
              child: PrakInput(controller: _phone),
            ),
          ],
        ),
        LabPrimaryButton(
          icon: 'check',
          label: 'Simpan Perubahan',
          large: true,
          onTap: _simpan,
        ),
      ],
    );
  }
}

class _SheetOption extends StatelessWidget {
  final String label;
  final bool danger;
  final VoidCallback onTap;

  const _SheetOption({
    required this.label,
    this.danger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ItlgShadows.outline,
        ),
        child: Text(
          label,
          style: labText(12, c: danger ? ItlgColors.primary : ItlgColors.text),
        ),
      ),
    );
  }
}
