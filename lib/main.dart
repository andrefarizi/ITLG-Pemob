import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/constants.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/pages/login_page.dart';
import 'features/dashboard/pages/dashboard_page.dart';
import 'features/attendance/pages/attendance_page.dart';
import 'features/reports/pages/reports_page.dart';
import 'features/users/pages/users_page.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/gyro/gyro_page.dart';

void main() {
  runApp(const ITLGApp());
}

class ITLGApp extends StatefulWidget {
  const ITLGApp({super.key});

  @override
  State<ITLGApp> createState() => _ITLGAppState();
}

class _ITLGAppState extends State<ITLGApp> {
  final AuthController _authController = AuthController.instance;
  bool _showSplash = true;
  bool _showOnboarding = true;

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
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: _showSplash
          ? SplashScreen(
              // Peran sudah dipilih di splash, jadi langsung lanjut
              // (melewati onboarding yang juga berisi pilihan peran).
              onRoleSelected: (_) {
                setState(() {
                  _showSplash = false;
                  _showOnboarding = false;
                });
              },
            )
          : _showOnboarding
          ? OnboardingScreen(
              onFinish: () {
                setState(() {
                  _showOnboarding = false;
                });
              },
            )
          : (_authController.isLoggedIn
              ? const MainNavigationShell()
              : LoginPage(
                  onLoginSuccess: () {
                    setState(() {});
                  },
                )),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final AuthController _authController = AuthController.instance;

  @override
  Widget build(BuildContext context) {
    final activeRole = _authController.currentRole;

    final List<Widget> pages = [
      DashboardPage(onTabChange: (index) {
        setState(() {
          _currentIndex = index;
        });
      }),
      const AttendancePage(),
      const ReportsPage(),
      UsersPage(onLogout: () {
        setState(() {});
      }),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      // Pintu masuk ke asisten AI Gyro
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tanya-gyro',
        backgroundColor: const Color(0xFF850909),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.smart_toy_rounded),
        label: const Text(
          'Tanya Gyro',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700),
        ),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GyroPage()),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        indicatorColor: activeRole.color.withValues(alpha: 0.15),
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: activeRole.color),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: const Icon(Icons.how_to_reg_outlined),
            selectedIcon: Icon(Icons.how_to_reg, color: activeRole.color),
            label: 'Presensi',
          ),
          NavigationDestination(
            icon: const Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description, color: activeRole.color),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: const Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group, color: activeRole.color),
            label: 'Pengguna',
          ),
        ],
      ),
    );
  }
}
