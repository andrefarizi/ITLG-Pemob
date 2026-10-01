import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../auth_controller.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController _authController = AuthController.instance;
  UserRole _selectedRole = UserRole.praktikan;

  @override
  void initState() {
    super.initState();
    _selectedRole = _authController.currentRole;
  }

  void _handleLogin() {
    _authController.login(
      identifier: _authController.userIdentifier,
      role: _selectedRole,
    );
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.biotech_rounded,
                  size: 64,
                  color: _selectedRole.color,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome - Login',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: UserRole.values.map((role) {
                    final isSelected = _selectedRole == role;
                    return ChoiceChip(
                      label: Text(role.displayName),
                      avatar: Icon(
                        role.icon,
                        size: 16,
                        color: isSelected ? Colors.white : role.color,
                      ),
                      selected: isSelected,
                      selectedColor: role.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedRole = role;
                          _authController.setRole(role);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedRole.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Masuk (${_selectedRole.displayName})'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: const Text('Lupa Kata Sandi?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
