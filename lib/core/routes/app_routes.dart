import 'package:flutter/material.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/forgot_password_page_1.dart';
import '../../features/auth/pages/forgot_password_page_2.dart';
import '../../features/auth/pages/forgot_password_page_3.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/splash/splash_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String forgotPasswordStep1 = '/forgot-password/step-1';
  static const String forgotPasswordStep2 = '/forgot-password/step-2';
  static const String forgotPasswordStep3 = '/forgot-password/step-3';
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String mainShell = '/main';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (context) => SplashScreen(
            onRoleSelected: (_) =>
                Navigator.of(context).pushReplacementNamed(login),
          ),
        );
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case forgotPassword:
      case forgotPasswordStep1:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage1());
      case forgotPasswordStep2:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage2());
      case forgotPasswordStep3:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage3());
      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}
