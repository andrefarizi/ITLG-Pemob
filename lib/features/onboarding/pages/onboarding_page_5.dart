import 'package:flutter/material.dart';
import '../../../core/utils/constants.dart';
import '../../auth/auth_controller.dart';
import '../../auth/pages/login_page.dart';

class OnboardingPage5 extends StatelessWidget {
  final VoidCallback? onSelectPraktikan;
  final VoidCallback? onSelectAslab;

  const OnboardingPage5({
    super.key,
    this.onSelectPraktikan,
    this.onSelectAslab,
  });

  // Konstanta warna merah gelap (maroon) untuk teks dan tombol
  final Color primaryMaroon = const Color(0xFF6A1B1A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang putih
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Logo ITLG
              Image.asset(
                'assets/logo_itlg_blue.png', 
                height: 50,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.terminal_rounded, size: 36, color: Color(0xFF1C2A4F)),
                    SizedBox(width: 8),
                    Text(
                      'ITLG',
                      style: TextStyle(
                        color: Color(0xFF1C2A4F),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              // 2. Ilustrasi dengan latar belakang abu-abu membulat
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5), // Abu-abu sangat muda
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Image.asset(
                  'assets/illustration_lab.png',
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: Icon(
                        Icons.biotech_rounded,
                        size: 96,
                        color: Color(0xFF6A1B1A),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 3. Teks "Selamat Datang di ITLG MOBILE"
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1.3,
                  ),
                  children: [
                    const TextSpan(text: 'Selamat Datang\n'),
                    const TextSpan(text: 'di '),
                    TextSpan(
                      text: 'ITLG MOBILE',
                      style: TextStyle(color: primaryMaroon),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Teks Subtitle
              const Text(
                'Mulailah Pengalaman Praktikum yang Lebih\nMudah dan Menyenangkan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 48),

              // 5. Tombol "Sebagai Praktikan" (Primary / Filled)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryMaroon,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () {
                    if (onSelectPraktikan != null) {
                      onSelectPraktikan!();
                    } else {
                      AuthController.instance.setRole(UserRole.praktikan);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    }
                  },
                  child: const Text(
                    'Sebagai Praktikan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 6. Tombol "Sebagai Asisten Lab" (Secondary / Outlined)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryMaroon,
                    side: BorderSide(color: primaryMaroon, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () {
                    if (onSelectAslab != null) {
                      onSelectAslab!();
                    } else {
                      AuthController.instance.setRole(UserRole.aslab);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    }
                  },
                  child: const Text(
                    'Sebagai Asisten Lab',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef WelcomeSelectionPage = OnboardingPage5;
