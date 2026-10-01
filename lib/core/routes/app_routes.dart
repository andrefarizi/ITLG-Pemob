import 'package:flutter/material.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/forgot_password_page.dart';

class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String mainShell = '/main';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}
