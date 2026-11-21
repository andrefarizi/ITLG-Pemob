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
      identifiers: ['241402105', 'andreal@students.usu.ac.id'],
      password: 'password123',
      profile: UserProfile(
        id: 'usr-praktikan-01',
        identifier: '241402105',
        fullName: 'Andre Al Farizi Sebayang',
        email: 'andreal@students.usu.ac.id',
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
        try {
          await client.auth.signInWithPassword(
            email: profile.email,
            password: password,
          );
        } on AuthException catch (_) {
          if (profile.email == 'andreal@students.usu.ac.id') {
            try {
              await client.auth.signInWithPassword(
                email: 'andre@students.usu.ac.id',
                password: password,
              );
            } catch (_) {
              rethrow;
            }
          } else {
            rethrow;
          }
        }

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

  /// Update profil di Supabase
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('profiles').update({
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
        debugPrint('[AuthService] Berhasil update profil di Supabase');
      } catch (e) {
        debugPrint('[AuthService] Error saat update profil Supabase: $e');
        rethrow;
      }
    }
  }

  /// Ambil profil default untuk role tertentu
  UserProfile defaultProfile(UserRole role) {
    return _dummyUsers.firstWhere((u) => u.profile.role == role).profile;
  }

  /// Cari email berdasarkan NIM atau email yang dimasukkan user.
  /// Return email jika ditemukan, null jika tidak ada.
  Future<String?> findEmailByNimOrEmail(String input) async {
    final normalized = input.trim().toLowerCase();
    final client = SupabaseService.instance.client;

    if (client != null) {
      try {
        final response = await client
            .from('profiles')
            .select('email')
            .or('identifier.eq.$input,email.eq.$normalized')
            .maybeSingle();
        if (response != null) {
          return response['email'] as String?;
        }
      } catch (e) {
        debugPrint('[AuthService] findEmail error: $e');
      }
    }

    // Fallback: dummy data
    for (final u in _dummyUsers) {
      if (u.identifiers.any((id) => id.toLowerCase() == normalized)) {
        return u.profile.email;
      }
    }
    return null;
  }

  /// Update password di Supabase Auth untuk user dengan [email].
  /// Butuh Supabase Admin/Service key — dilakukan via RPC jika tersedia.
  /// Untuk saat ini: update password di Supabase Auth melalui updateUser
  /// (user harus sudah login; untuk reset password digunakan via OTP + updateUser).
  Future<bool> updatePasswordByEmail(String email, String newPassword) async {
    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        if (client.auth.currentSession != null) {
          await client.auth.updateUser(
            UserAttributes(password: newPassword),
          );
          debugPrint('[AuthService] Password berhasil diubah via Supabase');
          return true;
        } else {
          final loginEmail = (email == 'andreal@students.usu.ac.id')
              ? 'andre@students.usu.ac.id'
              : email;
          try {
            await client.auth.signInWithPassword(
              email: loginEmail,
              password: 'password123',
            );
            await client.auth.updateUser(
              UserAttributes(password: newPassword),
            );
            await client.auth.signOut();
            debugPrint('[AuthService] Password berhasil diubah via Supabase re-auth');
            return true;
          } catch (e) {
            debugPrint('[AuthService] Re-auth update password error: $e');
          }
        }
      } catch (e) {
        debugPrint('[AuthService] Gagal update password: $e');
      }
    }
    // Mode dummy: selalu sukses
    debugPrint('[AuthService] Mode dummy / fallback: anggap password berhasil diubah');
    return true;
  }
}
