import 'package:flutter/foundation.dart';
import '../auth/auth_controller.dart';
import '../../core/utils/constants.dart';

/// Data profil yang bisa diubah dari halaman "Ubah Profil".
/// Terhubung langsung dengan [AuthController.currentProfile] dan Supabase.
class ProfilData extends ChangeNotifier {
  String _name;
  String _email;
  String _phone;

  /// "NIM" atau "NIP".
  final String idLabel;
  final String idValue;

  ProfilData({
    required String name,
    required String email,
    required String phone,
    required this.idLabel,
    required this.idValue,
  })  : _name = name,
        _email = email,
        _phone = phone;

  String get name => _name;
  String get email => _email;
  String get phone => _phone;

  Future<void> update({
    required String name,
    required String email,
    required String phone,
  }) async {
    await AuthController.instance.updateProfile(
      fullName: name,
      email: email,
      phone: phone,
    );
    _name = name;
    _email = email;
    _phone = phone;
    notifyListeners();
  }

  static ProfilData _fromProfile(UserRole role) {
    final p = AuthController.instance.currentProfile;
    final isNim = role == UserRole.praktikan || role == UserRole.aslab;
    final phoneVal = (p?.phone != null && p!.phone!.isNotEmpty)
        ? p.phone!
        : _defaultPhone(role);
    return ProfilData(
      name: (p?.fullName != null && p!.fullName.isNotEmpty)
          ? p.fullName
          : _defaultName(role),
      email: (p?.email != null && p!.email.isNotEmpty)
          ? p.email
          : _defaultEmail(role),
      phone: phoneVal,
      idLabel: isNim ? 'NIM' : 'NIP',
      idValue: (p?.identifier != null && p!.identifier.isNotEmpty)
          ? p.identifier
          : _defaultId(role),
    );
  }

  static ProfilData? _praktikan;
  static ProfilData? _aslab;
  static ProfilData? _laboran;
  static ProfilData? _dosen;

  static ProfilData get praktikan =>
      _praktikan ??= _fromProfile(UserRole.praktikan);
  static ProfilData get aslab => _aslab ??= _fromProfile(UserRole.aslab);
  static ProfilData get laboran =>
      _laboran ??= _fromProfile(UserRole.laboran);
  static ProfilData get dosen => _dosen ??= _fromProfile(UserRole.dosen);

  static void refresh(UserRole role) {
    switch (role) {
      case UserRole.praktikan:
        _praktikan = _fromProfile(role);
        break;
      case UserRole.aslab:
        _aslab = _fromProfile(role);
        break;
      case UserRole.laboran:
        _laboran = _fromProfile(role);
        break;
      case UserRole.dosen:
        _dosen = _fromProfile(role);
        break;
    }
  }

  static void resetAll() {
    _praktikan = null;
    _aslab = null;
    _laboran = null;
    _dosen = null;
  }

  static String _defaultName(UserRole role) => switch (role) {
        UserRole.praktikan => 'Nama Praktikan',
        UserRole.aslab => 'Abbil Rizki',
        UserRole.laboran => 'Reagan Brian',
        UserRole.dosen => 'Dr. Eng. Daniele Christian, M.Kom.',
      };

  static String _defaultEmail(UserRole role) => switch (role) {
        UserRole.praktikan => 'andre@students.usu.ac.id',
        UserRole.aslab => 'abbil@itlg.usu.ac.id',
        UserRole.laboran => 'reagan@itlg.usu.ac.id',
        UserRole.dosen => 'daniele@usu.ac.id',
      };

  static String _defaultPhone(UserRole role) => '0812-0000-0000';

  static String _defaultId(UserRole role) => switch (role) {
        UserRole.praktikan => '231402033',
        UserRole.aslab => '211402001',
        UserRole.laboran => '198501012010011001',
        UserRole.dosen => '198705122015041002',
      };
}
