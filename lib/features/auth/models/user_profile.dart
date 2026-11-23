import '../../../core/utils/constants.dart';

class UserProfile {
  final String id;
  final String identifier; // NIM atau NIP
  final String fullName;
  final String email;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.identifier,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      identifier: json['identifier'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: _parseRole(json['role'] as String?),
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'identifier': identifier,
      'full_name': fullName,
      'email': email,
      'role': role.name,
      'phone': phone,
      'avatar_url': avatarUrl,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      id: id,
      identifier: identifier,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role,
      phone: phone ?? this.phone,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
    );
  }

  static UserRole _parseRole(String? roleStr) {
    switch (roleStr?.toLowerCase()) {
      case 'aslab':
      case 'asisten':
        return UserRole.aslab;
      case 'laboran':
      case 'teknisi':
        return UserRole.laboran;
      case 'dosen':
        return UserRole.dosen;
      case 'praktikan':
      case 'mahasiswa':
      default:
        return UserRole.praktikan;
    }
  }
}
