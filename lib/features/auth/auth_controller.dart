import 'package:flutter/material.dart';
import '../../core/utils/constants.dart';
import '../shared/profil_data.dart';
import 'models/user_profile.dart';
import 'services/auth_service.dart';

class AuthController extends ChangeNotifier {
  static final AuthController instance = AuthController._internal();
  factory AuthController() => instance;
  AuthController._internal();

  UserRole _currentRole = UserRole.praktikan;
  bool _isLoggedIn = true;
  String _userIdentifier = '241402105'; // default NIM/NIP
  String _userName = 'Andre Al Farizi Sebayang';
  UserProfile? _currentProfile;

  UserRole get currentRole => _currentRole;
  bool get isLoggedIn => _isLoggedIn;
  String get userIdentifier => _currentProfile?.identifier ?? _userIdentifier;
  String get userName => _currentProfile?.fullName ?? _userName;
  UserProfile? get currentProfile => _currentProfile;

  void setRole(UserRole role) {
    _currentRole = role;
    _currentProfile = AuthService.instance.defaultProfile(role);
    _userIdentifier = _currentProfile!.identifier;
    _userName = _currentProfile!.fullName;
    notifyListeners();
  }

  /// Login resmi dengan backend Supabase / PostgreSQL & fallback Dummy
  Future<AuthResult> loginWithCredentials({
    required String identifier,
    required String password,
    required UserRole role,
  }) async {
    final result = await AuthService.instance.login(
      identifier: identifier,
      password: password,
      selectedRole: role,
    );

    if (result.success && result.profile != null) {
      _isLoggedIn = true;
      _currentProfile = result.profile;
      _currentRole = result.profile!.role;
      _userIdentifier = result.profile!.identifier;
      _userName = result.profile!.fullName;
      notifyListeners();
    }

    return result;
  }

  /// Update profil pengguna (simpan ke Supabase dan memori lokal)
  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String phone,
  }) async {
    if (_currentProfile != null) {
      await AuthService.instance.updateProfile(
        userId: _currentProfile!.id,
        fullName: fullName,
        email: email,
        phone: phone,
      );
      _currentProfile = _currentProfile!.copyWith(
        fullName: fullName,
        email: email,
        phone: phone,
      );
      _userName = fullName;
    }
    notifyListeners();
  }

  /// Sinkron login untuk kompatibilitas
  void login({required String identifier, required UserRole role}) {
    _isLoggedIn = true;
    _userIdentifier = identifier;
    setRole(role);
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    _isLoggedIn = false;
    _currentProfile = null;
    ProfilData.resetAll();
    notifyListeners();
  }
}

