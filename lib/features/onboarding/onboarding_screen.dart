import 'package:flutter/material.dart';
import '../../core/utils/constants.dart';
import '../auth/auth_controller.dart';
import 'pages/onboarding_page_1.dart';
import 'pages/onboarding_page_2.dart';
import 'pages/onboarding_page_3.dart';
import 'pages/onboarding_page_4.dart';
import 'pages/onboarding_page_5.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onFinish;

  const OnboardingScreen({super.key, this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const Color maroon = Color(0xFF6A1B1A);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _onSkip() {
    _pageController.animateToPage(
      4,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _finishOnboarding([UserRole? role]) {
    if (role != null) {
      AuthController.instance.setRole(role);
    }
    if (widget.onFinish != null) {
      widget.onFinish!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  bool get _isDarkPage => _currentPage <= 2;

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPage == 4;
    final Color activeColor = _isDarkPage ? Colors.white : maroon;
    final Color inactiveColor = _isDarkPage ? Colors.white38 : Colors.grey.shade300;

    final List<Widget> pages = [
      const OnboardingPage1(),
      const OnboardingPage2(),
      const OnboardingPage3(),
      const OnboardingPage4(),
      OnboardingPage5(
        onSelectPraktikan: () => _finishOnboarding(UserRole.praktikan),
        onSelectAslab: () => _finishOnboarding(UserRole.aslab),
      ),
    ];

    return Scaffold(
      backgroundColor: _isDarkPage ? maroon : Colors.white,
      body: Stack(
        children: [
          // 1. PageView (Geser Halaman 1 sampai 5)
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: pages,
          ),

          // 2. Tombol "Lewati" di Kanan Atas
          if (!isLastPage)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, right: 16.0),
                  child: TextButton(
                    onPressed: _onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: activeColor.withValues(alpha: 0.9),
                    ),
                    child: const Text(
                      'Lewati',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 3. Kontrol Bawah (Indikator Titik + Tombol Lanjut)
          // Di Halaman 5 (terakhir), tombol navigasi bawah disembunyikan
          // karena Page 5 sudah memiliki tombol "Sebagai Praktikan" & "Sebagai Asisten Lab"
          if (!isLastPage)
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indikator Titik (Dots)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? activeColor : inactiveColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tombol Lanjut
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDarkPage ? Colors.white : maroon,
                          foregroundColor: _isDarkPage ? maroon : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Lanjut',
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
        ],
      ),
    );
  }
}
