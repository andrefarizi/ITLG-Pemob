import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../auth_controller.dart';
import 'forgot_password_page_1.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = AuthController.instance;

  late TextEditingController _identifierController;
  final TextEditingController _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.praktikan;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = _authController.currentRole;
    _identifierController = TextEditingController(text: _getDefaultIdentifier(_selectedRole));
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getDefaultIdentifier(UserRole role) {
    switch (role) {
      case UserRole.praktikan:
        return '241402105';
      case UserRole.aslab:
        return 'ASLAB-04';
      case UserRole.laboran:
        return 'LAB-01';
      case UserRole.dosen:
        return '198705122015041002';
    }
  }

  String _getIdentifierLabel(UserRole role) {
    switch (role) {
      case UserRole.praktikan:
        return 'Nomor Induk Mahasiswa (NIM)';
      case UserRole.aslab:
        return 'ID / Kode Asisten Lab';
      case UserRole.laboran:
        return 'ID Laboran / Teknisi';
      case UserRole.dosen:
        return 'Nomor Induk Pegawai (NIP)';
    }
  }

  void _handleRoleChange(UserRole role) {
    setState(() {
      _selectedRole = role;
      _authController.setRole(role);
      _identifierController.text = _getDefaultIdentifier(role);
    });
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() => _isLoading = false);

        _authController.login(
          identifier: _identifierController.text.trim(),
          role: _selectedRole,
        );

        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else {
          // Jika dipanggil via Navigator.push biasa
          Navigator.of(context).maybePop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // 1. Logo & Brand Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A1B1A).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.terminal_rounded,
                          size: 36,
                          color: Color(0xFF6A1B1A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ITLG MOBILE',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF6A1B1A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sistem Praktikum & Manajemen Laboratorium',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 2. Role Selector (Pilih Peran)
                const Text(
                  'Pilih Peran Pengguna:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: UserRole.values.map((role) {
                      final isSelected = _selectedRole == role;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          avatar: Icon(
                            role.icon,
                            size: 16,
                            color: isSelected ? Colors.white : role.color,
                          ),
                          label: Text(role.displayName),
                          selected: isSelected,
                          selectedColor: role.color,
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (_) => _handleRoleChange(role),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Input Identifier (NIM / NIP / ID)
                Text(
                  _getIdentifierLabel(_selectedRole),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _identifierController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Masukkan ${_getIdentifierLabel(_selectedRole)}',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: _selectedRole.color),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bidang ini wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // 4. Input Password
                const Text(
                  'Kata Sandi (Password)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Masukkan kata sandi akun Anda',
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: _selectedRole.color),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kata sandi tidak boleh kosong';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // 5. Remember Me & Lupa Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: _selectedRole.color,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) => setState(() => _rememberMe = val ?? true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Ingat saya',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage1(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: const Color(0xFF6A1B1A),
                      ),
                      child: const Text(
                        'Lupa Kata Sandi?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // 6. Tombol Masuk
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedRole.color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Masuk sebagai ${_selectedRole.displayName}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Footer Info
                Center(
                  child: Text(
                    'Laboratorium ITLG © ${DateTime.now().year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
