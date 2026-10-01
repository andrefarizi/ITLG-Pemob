import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum UserRole {
  praktikan,
  aslab,
  laboran,
  dosen,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.praktikan:
        return 'Praktikan';
      case UserRole.aslab:
        return 'Asisten Lab';
      case UserRole.laboran:
        return 'Laboran';
      case UserRole.dosen:
        return 'Dosen Pengampu';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.praktikan:
        return AppColors.praktikan;
      case UserRole.aslab:
        return AppColors.aslab;
      case UserRole.laboran:
        return AppColors.laboran;
      case UserRole.dosen:
        return AppColors.dosen;
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.praktikan:
        return Icons.school_rounded;
      case UserRole.aslab:
        return Icons.terminal_rounded;
      case UserRole.laboran:
        return Icons.inventory_2_rounded;
      case UserRole.dosen:
        return Icons.supervisor_account_rounded;
    }
  }
}

class AppConstants {
  static const String appName = 'ITLG Mobile';
  static const String appTagline = 'Sistem Praktikum & Lab Terpadu';
}

