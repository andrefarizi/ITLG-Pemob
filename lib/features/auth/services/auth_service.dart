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

  /// Menyimpan kata sandi yang baru diubah via Lupa Password selama runtime aplikasi.
  final Map<String, String> _customPasswords = {};

  /// Peta email baru -> email lama di auth.users.
  static const Map<String, String> _legacyAuthEmails = {
    'andreal@students.usu.ac.id': 'andre@students.usu.ac.id',
    'abbilrizki@students.usu.ac.id': 'abbil@itlg.usu.ac.id',
    'reaganbrian@students.usu.ac.id': 'reagan@itlg.usu.ac.id',
    'danielechristian@students.usu.ac.id': 'daniele@usu.ac.id',
  };

  /// Peta email lama -> email USU resmi terbaru sesuai nama pengguna.
  static const Map<String, String> _canonicalEmails = {
    'andre@students.usu.ac.id': 'andreal@students.usu.ac.id',
    'abbil@itlg.usu.ac.id': 'abbilrizki@students.usu.ac.id',
    'reagan@itlg.usu.ac.id': 'reaganbrian@students.usu.ac.id',
    'daniele@usu.ac.id': 'danielechristian@students.usu.ac.id',
  };

  /// Data dummy lokal untuk 4 peran pengguna (Praktikan, Aslab, Laboran, Dosen).
  final List<_DummyUser> _dummyUsers = const [
    _DummyUser(
      identifiers: [
        '241402105',
        'andreal@students.usu.ac.id',
        'andre@students.usu.ac.id',
      ],
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
      identifiers: [
        '211402001',
        'ASLAB-04',
        'abbilrizki@students.usu.ac.id',
        'abbil@itlg.usu.ac.id',
      ],
      password: 'password123',
      profile: UserProfile(
        id: 'usr-aslab-01',
        identifier: '211402001',
        fullName: 'Abbil Rizki',
        email: 'abbilrizki@students.usu.ac.id',
        role: UserRole.aslab,
        phone: '081298765432',
      ),
    ),
    _DummyUser(
      identifiers: [
        '198501012010011001',
        'LAB-01',
        'reaganbrian@students.usu.ac.id',
        'reagan@itlg.usu.ac.id',
      ],
      password: 'password123',
      profile: UserProfile(
        id: 'usr-laboran-01',
        identifier: '198501012010011001',
        fullName: 'Reagan Brian',
        email: 'reaganbrian@students.usu.ac.id',
        role: UserRole.laboran,
        phone: '081377889900',
      ),
    ),
    _DummyUser(
      identifiers: [
        '198705122015041002',
        'danielechristian@students.usu.ac.id',
        'daniele@usu.ac.id',
      ],
      password: 'password123',
      profile: UserProfile(
        id: 'usr-dosen-01',
        identifier: '198705122015041002',
        fullName: 'Dr. Eng. Daniele Christian, M.Kom.',
        email: 'danielechristian@students.usu.ac.id',
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
  /// Aturan akun resmi ITLG: email kampus berdomain @students.usu.ac.id.
  static final RegExp studentsUsuEmail = RegExp(
    r'^[\w.+-]+@students\.usu\.ac\.id$',
    caseSensitive: false,
  );

  static bool isStudentsUsuEmail(String email) =>
      studentsUsuEmail.hasMatch(email.trim());

  Future<AuthResult> login({
    required String identifier,
    required String password,
    required UserRole selectedRole,
  }) async {
    final client = SupabaseService.instance.client;

    // Bila login memakai email, wajib email @students.usu.ac.id.
    if (identifier.contains('@') && !isStudentsUsuEmail(identifier)) {
      return const AuthResult.failure(
          'Gunakan email @students.usu.ac.id atau Nomor Induk.');
    }

    if (client != null) {
      try {
        debugPrint('[AuthService] Mencoba login melalui Supabase...');
        // 1. Cari profil di PostgreSQL berdasarkan NIM/NIP atau Email
        final normalizedInput = identifier.trim().toLowerCase();
        final legacyAlias = _legacyAuthEmails[normalizedInput];
        final queryFilter = legacyAlias != null
            ? 'identifier.eq.$identifier,email.eq.$normalizedInput,email.eq.$legacyAlias'
            : 'identifier.eq.$identifier,email.eq.$identifier';
        final response = await client
            .from('profiles')
            .select()
            .or(queryFilter)
            .maybeSingle();

        if (response == null) {
          return const AuthResult.failure('Nomor Induk / Email tidak terdaftar dalam database.');
        }

        var profile = UserProfile.fromJson(response);
        final canonicalEmail = _canonicalEmails[profile.email.toLowerCase()];
        if (canonicalEmail != null) {
          profile = profile.copyWith(email: canonicalEmail);
        }

        // Akun wajib memakai email resmi @students.usu.ac.id.
        if (!isStudentsUsuEmail(profile.email)) {
          return const AuthResult.failure(
              'Akun ini belum memakai email @students.usu.ac.id. Hubungi admin ITLG.');
        }

        // 2. Validasi kesesuaian peran yang dipilih di UI
        if (profile.role != selectedRole) {
          return AuthResult.failure(
            'Akun ini terdaftar sebagai ${_roleName(profile.role)}, bukan ${_roleName(selectedRole)}.',
          );
        }

        // 3. Autentikasi
        final normalizedId = identifier.trim().toLowerCase();
        final legacyEmail = _legacyAuthEmails[profile.email.toLowerCase()];
        final customPassword = _customPasswords[normalizedId] ??
            _customPasswords[profile.email.toLowerCase()] ??
            (legacyEmail != null ? _customPasswords[legacyEmail] : null);

        // Jika kata sandi baru disetel via alur Lupa Password
        if (customPassword != null) {
          if (password != customPassword) {
            return const AuthResult.failure('Kata sandi salah. Silakan periksa kembali.');
          }
          debugPrint('[AuthService] Berhasil login via kata sandi baru: ${profile.fullName}');
          return AuthResult.success(profile);
        }

        // Autentikasi standar dengan Supabase Auth
        try {
          await client.auth.signInWithPassword(
            email: profile.email,
            password: password,
          );
        } on AuthException catch (_) {
          if (legacyEmail != null) {
            try {
              await client.auth.signInWithPassword(
                email: legacyEmail,
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

    final customPassword = _customPasswords[normalizedId] ??
        _customPasswords[matchedUser.profile.email.toLowerCase()];
    final effectivePassword = customPassword ?? matchedUser.password;

    if (effectivePassword != password) {
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
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', userId);
        debugPrint('[AuthService] Berhasil update profil di Supabase');
      } catch (e) {
        debugPrint('[AuthService] Error saat update profil Supabase: $e');
        rethrow;
      }
    }
  }

  /// Update avatar URL di Supabase (`public.profiles.avatar_url`).
  Future<void> updateAvatar({
    required String userId,
    String? avatarUrl,
  }) async {
    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('profiles').update({
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', userId);
        debugPrint('[AuthService] Berhasil update avatar_url di Supabase');
      } catch (e) {
        debugPrint('[AuthService] Error saat update avatar_url Supabase: $e');
      }
    }
  }

  /// Verifikasi kata sandi saat ini dan ubah ke kata sandi baru dari halaman Profil.
  Future<AuthResult> changePassword({
    required String email,
    required String identifier,
    required String currentPassword,
    required String newPassword,
  }) async {
    final lowerEmail = email.toLowerCase().trim();
    final lowerId = identifier.toLowerCase().trim();
    final legacyEmail = _legacyAuthEmails[lowerEmail];

    // 1. Cek jika kata sandi sebelumnya diubah dalam sesi runtime
    final customPw = _customPasswords[lowerId] ??
        _customPasswords[lowerEmail] ??
        (legacyEmail != null ? _customPasswords[legacyEmail] : null);

    bool currentValid = false;
    if (customPw != null) {
      currentValid = customPw == currentPassword;
    } else {
      final client = SupabaseService.instance.client;
      if (client != null) {
        bool rpcChecked = false;
        try {
          final rpcRes = await client.rpc('verify_user_password', params: {
            'user_email': lowerEmail,
            'current_password': currentPassword,
          });
          if (rpcRes is bool) {
            currentValid = rpcRes;
            rpcChecked = true;
          }
        } catch (e) {
          debugPrint('[AuthService] RPC verify_user_password belum tersedia: $e');
        }

        if (!rpcChecked) {
          try {
            await client.auth.signInWithPassword(
              email: lowerEmail,
              password: currentPassword,
            );
            currentValid = true;
          } catch (_) {
            if (legacyEmail != null) {
              try {
                await client.auth.signInWithPassword(
                  email: legacyEmail,
                  password: currentPassword,
                );
                currentValid = true;
              } catch (_) {
                currentValid = false;
              }
            } else {
              currentValid = false;
            }
          }
        }
      } else {
        // Fallback offline / dummy
        final matched = _dummyUsers.cast<_DummyUser?>().firstWhere(
              (u) => u!.identifiers.any((id) =>
                  id.toLowerCase() == lowerEmail ||
                  id.toLowerCase() == lowerId),
              orElse: () => null,
            );
        currentValid = matched != null && matched.password == currentPassword;
      }
    }

    if (!currentValid) {
      return const AuthResult.failure(
        'Kata sandi saat ini tidak sesuai. Silakan periksa kembali.',
      );
    }

    await updatePasswordByEmail(lowerEmail, newPassword);
    return const AuthResult.success(null);
  }

  /// Ambil profil default untuk role tertentu
  UserProfile defaultProfile(UserRole role) {
    return _dummyUsers.firstWhere((u) => u.profile.role == role).profile;
  }

  /// Cari email berdasarkan NIM atau email yang dimasukkan user.
  Future<String?> findEmailByNimOrEmail(String input) async {
    final normalized = input.trim().toLowerCase();
    final client = SupabaseService.instance.client;

    if (client != null) {
      try {
        final legacyAlias = _legacyAuthEmails[normalized];
        final queryFilter = legacyAlias != null
            ? 'identifier.eq.$input,email.eq.$normalized,email.eq.$legacyAlias'
            : 'identifier.eq.$input,email.eq.$normalized';
        final response = await client
            .from('profiles')
            .select('email')
            .or(queryFilter)
            .maybeSingle();
        if (response != null) {
          final dbEmail = (response['email'] as String?)?.toLowerCase();
          if (dbEmail != null) {
            return _canonicalEmails[dbEmail] ?? dbEmail;
          }
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
  Future<bool> updatePasswordByEmail(String email, String newPassword) async {
    final lowerEmail = email.toLowerCase().trim();
    _customPasswords[lowerEmail] = newPassword;
    final legacyEmail = _legacyAuthEmails[lowerEmail];
    if (legacyEmail != null) {
      _customPasswords[legacyEmail] = newPassword;
    }
    for (final u in _dummyUsers) {
      if (u.identifiers.any((id) => id.toLowerCase() == lowerEmail)) {
        for (final id in u.identifiers) {
          _customPasswords[id.toLowerCase()] = newPassword;
        }
      }
    }

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.rpc('reset_password_by_email', params: {
          'user_email': lowerEmail,
          'new_password': newPassword,
        });
        debugPrint('[AuthService] Password berhasil diubah via RPC reset_password_by_email di Supabase');
      } catch (e) {
        debugPrint('[AuthService] RPC reset_password_by_email belum aktif: $e');
      }

      // 2. Jika user sedang aktif login, ubah via updateUser
      try {
        if (client.auth.currentSession != null) {
          await client.auth.updateUser(UserAttributes(password: newPassword));
          debugPrint('[AuthService] Password berhasil diubah via Supabase updateUser');
        }
      } catch (e) {
        debugPrint('[AuthService] updateUser error: $e');
      }
    }

    debugPrint('[AuthService] Password baru berhasil disetel untuk $lowerEmail');
    return true;
  }
}
