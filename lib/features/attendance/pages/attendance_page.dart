import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../auth/auth_controller.dart';
import '../../auth/widgets/role_badge.dart';
import '../../praktikan/attendance/praktikan_attendance_page.dart';
import '../../aslab/attendance/aslab_attendance_page.dart';
import '../../laboran/attendance/laboran_attendance_page.dart';
import '../../dosen/attendance/dosen_attendance_page.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final AuthController _authController = AuthController.instance;

  @override
  void initState() {
    super.initState();
    _authController.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final role = _authController.currentRole;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Presensi & Kehadiran Lab'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: RoleBadge(role: role),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildAttendanceView(role),
      ),
    );
  }

  Widget _buildAttendanceView(UserRole role) {
    switch (role) {
      case UserRole.praktikan:
        return const PraktikanAttendancePage();
      case UserRole.aslab:
        return const AslabAttendancePage();
      case UserRole.laboran:
        return const LaboranAttendancePage();
      case UserRole.dosen:
        return const DosenAttendancePage();
    }
  }
}
