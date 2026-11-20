import 'package:flutter/foundation.dart';

/// Data profil yang bisa diubah dari halaman "Ubah Profil" (tersimpan di
/// memori saja, belum terhubung ke backend). Satu objek per peran sehingga
/// perubahan langsung terlihat di halaman Profil peran tersebut.
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

  void update({
    required String name,
    required String email,
    required String phone,
  }) {
    _name = name;
    _email = email;
    _phone = phone;
    notifyListeners();
  }

  static final ProfilData praktikan = ProfilData(
    name: 'Nama Praktikan',
    email: 'praktikan@students.usu.ac.id',
    phone: '0812-0000-0000',
    idLabel: 'NIM',
    idValue: '231402033',
  );

  static final ProfilData aslab = ProfilData(
    name: 'Andi Pratama',
    email: 'asisten@students.usu.ac.id',
    phone: '0812-0000-0000',
    idLabel: 'NIM',
    idValue: '211402017',
  );

  static final ProfilData laboran = ProfilData(
    name: 'Budi Santoso',
    email: 'laboran@usu.ac.id',
    phone: '0812-0000-0000',
    idLabel: 'NIP',
    idValue: '198703122015041002',
  );

  static final ProfilData dosen = ProfilData(
    name: 'Dr. Sari Lubis',
    email: 'sari.lubis@usu.ac.id',
    phone: '0812-0000-0000',
    idLabel: 'NIP',
    idValue: '198501012010011001',
  );
}
