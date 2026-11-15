import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'forgot_password_page_2.dart';

class ForgotPasswordPage1 extends StatefulWidget {
  const ForgotPasswordPage1({super.key});

  @override
  State<ForgotPasswordPage1> createState() => _ForgotPasswordPage1State();
}

class _ForgotPasswordPage1State extends State<ForgotPasswordPage1> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      // Simulasi kirim kode verifikasi
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() => _isLoading = false);

        final emailOrNim = _identifierController.text.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kode verifikasi telah dikirim ke $emailOrNim'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ForgotPasswordPage2(
              targetIdentifier: emailOrNim,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lupa Kata Sandi'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Indicator (Langkah 1 dari 3)
                Row(
                  children: [
                    _buildStepDot(isActive: true),
                    _buildStepDivider(isActive: false),
                    _buildStepDot(isActive: false),
                    _buildStepDivider(isActive: false),
                    _buildStepDot(isActive: false),
                    const SizedBox(width: 12),
                    const Text(
                      'Langkah 1 / 3',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Icon & Header
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B1A).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 40,
                      color: Color(0xFF6A1B1A),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Center(
                  child: Text(
                    'Atur Ulang Kata Sandi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Center(
                  child: Text(
                    'Masukkan alamat Email atau NIM terdaftar Anda.\nKami akan mengirimkan kode verifikasi 6-digit.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Input Field
                const Text(
                  'Email atau NIM',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: 241402105 atau nama@mail.com',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email atau NIM tidak boleh kosong';
                    }
                    if (value.trim().length < 4) {
                      return 'Masukkan minimal 4 karakter yang valid';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Tombol Kirim Kode
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B1A),
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
                        : const Text(
                            'Kirim Kode Verifikasi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tombol Kembali ke Login
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text(
                      'Kembali ke Halaman Masuk',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildStepDot({required bool isActive}) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF6A1B1A) : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStepDivider({required bool isActive}) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isActive ? const Color(0xFF6A1B1A) : Colors.grey.shade300,
    );
  }
}

typedef LupaPasswordPage1 = ForgotPasswordPage1;

