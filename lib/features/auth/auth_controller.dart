import 'package:flutter/material.dart';
import '../../core/utils/constants.dart';

class AuthController extends ChangeNotifier {
  static final AuthController instance = AuthController._internal();
  factory AuthController() => instance;
  AuthController._internal();

  UserRole _currentRole = UserRole.praktikan;
  bool _isLoggedIn = true;
  String _userIdentifier = '241402105'; // default NIM/NIP
  String _userName = 'Andre Al Farizi Sebayang';

  UserRole get currentRole => _currentRole;
  bool get isLoggedIn => _isLoggedIn;
  String get userIdentifier => _userIdentifier;
  String get userName => _userName;

  void setRole(UserRole role) {
    _currentRole = role;
    switch (role) {
      case UserRole.praktikan:
        _userIdentifier = '241402105';
        _userName = 'Andre Al Farizi (Praktikan)';
        break;
      case UserRole.aslab:
        _userIdentifier = 'ASLAB-04';
        _userName = 'Abbil Rizki (Asisten Lab)';
        break;
      case UserRole.laboran:
        _userIdentifier = 'LAB-01';
        _userName = 'Reagan Brian (Laboran/Teknisi)';
        break;
      case UserRole.dosen:
        _userIdentifier = '198705122015041002';
        _userName = 'Dr. Eng. Daniele Christian, M.Kom.';
        break;
    }
    notifyListeners();
  }

  void login({required String identifier, required UserRole role}) {
    _isLoggedIn = true;
    _userIdentifier = identifier;
    setRole(role);
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}
