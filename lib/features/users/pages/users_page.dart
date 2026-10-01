import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../auth/auth_controller.dart';
import '../../auth/widgets/role_badge.dart';
import '../../praktikan/users/praktikan_users_page.dart';
import '../../aslab/users/aslab_users_page.dart';
import '../../laboran/users/laboran_users_page.dart';
import '../../dosen/users/dosen_users_page.dart';

class UsersPage extends StatefulWidget {
  final VoidCallback? onLogout;

  const UsersPage({super.key, this.onLogout});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final AuthController _authController = AuthController.instance;

  @override
  void initState() {
    super.initState();
    _authController.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _authController.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _showRoleSwitchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ganti Peran Pengguna (Role)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values.map((role) {
              final isCurrent = _authController.currentRole == role;
              return ListTile(
                leading: Icon(role.icon, color: role.color),
                title: Text(role.displayName, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                trailing: isCurrent ? Icon(Icons.check, color: role.color) : null,
                onTap: () {
                  _authController.setRole(role);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = _authController.currentRole;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengguna & Profil Tim'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: RoleBadge(role: role),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoleUsersContent(role),
            const SizedBox(height: 24),
            // Tombol Logout
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  _authController.logout();
                  if (widget.onLogout != null) {
                    widget.onLogout!();
                  }
                },
                icon: const Icon(Icons.logout, color: AppColors.danger),
                label: const Text('Keluar dari Akun (Logout)', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleUsersContent(UserRole role) {
    switch (role) {
      case UserRole.praktikan:
        return PraktikanUsersPage(onRoleSwitch: _showRoleSwitchDialog);
      case UserRole.aslab:
        return AslabUsersPage(onRoleSwitch: _showRoleSwitchDialog);
      case UserRole.laboran:
        return LaboranUsersPage(onRoleSwitch: _showRoleSwitchDialog);
      case UserRole.dosen:
        return DosenUsersPage(onRoleSwitch: _showRoleSwitchDialog);
    }
  }
}
