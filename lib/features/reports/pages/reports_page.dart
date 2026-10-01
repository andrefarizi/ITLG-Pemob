import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../auth/auth_controller.dart';
import '../../auth/widgets/role_badge.dart';
import '../../praktikan/reports/praktikan_reports_page.dart';
import '../../aslab/reports/aslab_reports_page.dart';
import '../../laboran/reports/laboran_reports_page.dart';
import '../../dosen/reports/dosen_reports_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
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
        title: const Text('Laporan, Grading & Validasi'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: RoleBadge(role: role),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildRoleReportsView(role),
      ),
    );
  }

  Widget _buildRoleReportsView(UserRole role) {
    switch (role) {
      case UserRole.praktikan:
        return const PraktikanReportsPage();
      case UserRole.aslab:
        return const AslabReportsPage();
      case UserRole.laboran:
        return const LaboranReportsPage();
      case UserRole.dosen:
        return const DosenReportsPage();
    }
  }
}
