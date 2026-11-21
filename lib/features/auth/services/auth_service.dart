import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/constants.dart';
import '../models/user_profile.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final UserProfile? profile;

  const AuthResult.success(this.profile)
      : success = true,
        errorMessage = null;

  const AuthResult.failure(this.errorMessage)
      : success = false,
        profile = null;
}

class _DummyUser {
  final List<String> identifiers;
  final String password;
  final UserProfile profile;

  const _DummyUser({
    required this.identifiers,
    required this.password,
    required this.profile,
  });
}

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  /// Data dummy lokal untuk 4 peran pengguna (Praktikan, Aslab, Laboran, Dosen).
  /// Dipakai saat Supabase belum dikonfigurasi atau offline.
  final List<_DummyUser> _dummyUsers = const [
    _DummyUser(
      identifiers: ['231402033', '241402105', 'andre@students.usu.ac.id'],
      password: 'password123',
      profile: UserProfile(
        id: 'usr-praktikan-01',
        identifier: '231402033',
        fullName: 'Andre Al Farizi Sebayang',
        email: 'andre@students.usu.ac.id',
        role: UserRole.praktikan,
        phone: '081234567890',
      ),
    ),
    _DummyUser(
      identifiers: ['211402001', 'ASLAB-04', 'abbil@itlg.usu.ac.id'],
      password: 'password123',
      profile: UserProfile(
        id: 'usr-aslab-01',
        identifier: '211402001',
        fullName: 'Abbil Rizki',
        email: 'abbil@itlg.usu.ac.id',
        role: UserRole.aslab,
        phone: '081298765432',
      ),
    ),
    _DummyUser(
      identifiers: ['198501012010011001', 'LAB-01', 'reagan@itlg.usu.ac.id'],
      password: 'password123',
      profile: UserProfile(
        id: 'usr-laboran-01',
        identifier: '198501012010011001',
        fullName: 'Reagan Brian',
        email: 'reagan@itlg.usu.ac.id',
        role: UserRole.laboran,
        phone: '081377889900',
      ),
    ),
    _DummyUser(
      identifiers: ['198705122015041002', 'daniele@usu.ac.id'],
      password: 'password123',
      profile: UserProfile(
        id: 'usr-dosen-01',
        identifier: '198705122015041002',
        fullName: 'Dr. Eng. Daniele Christian, M.Kom.',
        email: 'daniele@usu.ac.id',
        role: UserRole.dosen,
        phone: '081122334455',
      ),
    ),
  ];

  static String _roleName(UserRole role) {
    switch (role) {
      case UserRole.praktikan:
        return 'Mahasiswa';
      case UserRole.aslab:
        return 'Asisten Lab';
      case UserRole.laboran:
        return 'Laboran';
      case UserRole.dosen:
        return 'Dosen';
    }
  }

  /// Proses masuk (login) dengan dukungan Supabase + PostgreSQL
  /// dan fallback transparan ke data dummy.
  Future<AuthResult> login({
    required String identifier,
    required String password,
    required UserRole selectedRole,
  }) async {
    final client = SupabaseService.instance.client;

    if (client != null) {
      try {
        debugPrint('[AuthService] Mencoba login melalui Supabase...');
        // 1. Cari profil di PostgreSQL berdasarkan NIM/NIP atau Email
        final response = await client
            .from('profiles')
            .select()
            .or('identifier.eq.$identifier,email.eq.$identifier')
            .maybeSingle();

        if (response == null) {
          return const AuthResult.failure('Nomor Induk / Email tidak terdaftar dalam database.');
        }

        final profile = UserProfile.fromJson(response);

        // 2. Validasi kesesuaian peran yang dipilih di UI
        if (profile.role != selectedRole) {
          return AuthResult.failure(
            'Akun ini terdaftar sebagai ${_roleName(profile.role)}, bukan ${_roleName(selectedRole)}.',
          );
        }

        // 3. Autentikasi dengan Supabase Auth
        await client.auth.signInWithPassword(
          email: profile.email,
          password: password,
        );

        debugPrint('[AuthService] Berhasil login via Supabase: ${profile.fullName}');
        return AuthResult.success(profile);
      } on AuthException catch (e) {
        debugPrint('[AuthService] Gagal autentikasi Supabase: ${e.message}');
        if (e.message.toLowerCase().contains('invalid login credentials')) {
          return const AuthResult.failure('Kata sandi salah. Silakan periksa kembali.');
        }
        return AuthResult.failure(e.message);
      } catch (e) {
        debugPrint('[AuthService] Error saat login Supabase: $e');
        return AuthResult.failure('Gagal menghubungi server database: $e');
      }
    }

    // Fallback: Mode Data Dummy Lokal
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final normalizedId = identifier.trim().toLowerCase();
    final matchedUser = _dummyUsers.cast<_DummyUser?>().firstWhere(
          (u) => u!.identifiers.any((i) => i.toLowerCase() == normalizedId),
          orElse: () => null,
        );

    if (matchedUser == null) {
      return const AuthResult.failure('Nomor Induk / Email tidak terdaftar.');
    }

    if (matchedUser.profile.role != selectedRole) {
      return AuthResult.failure(
        'Akun ini terdaftar sebagai ${_roleName(matchedUser.profile.role)}, bukan ${_roleName(selectedRole)}.',
      );
    }

    if (matchedUser.password != password) {
      return const AuthResult.failure('Kata sandi salah. Silakan periksa kembali.');
    }

    debugPrint('[AuthService] Berhasil login via Dummy Data: ${matchedUser.profile.fullName}');
    return AuthResult.success(matchedUser.profile);
  }

  /// Proses keluar (logout)
  Future<void> logout() async {
    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (e) {
        debugPrint('[AuthService] Error saat signOut Supabase: $e');
      }
    }
  }

  /// Ambil profil default untuk role tertentu
  UserProfile defaultProfile(UserRole role) {
    return _dummyUsers.firstWhere((u) => u.profile.role == role).profile;
  }
}
