import 'package:flutter/material.dart';

// Halaman onboarding langkah 4
class OnboardingPage4 extends StatelessWidget {
  const OnboardingPage4({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo_icon_blue.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.terminal_rounded,
                  color: Color(0xFF1C2A4F),
                  size: 54,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ITLG',
                    style: TextStyle(
                      color: Color(0xFF1C2A4F),
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Information Technology\nLaboratory Group',
                    style: TextStyle(
                      color: Color(0xFF597BBE),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef ItlgLightSplashScreen = OnboardingPage4;
