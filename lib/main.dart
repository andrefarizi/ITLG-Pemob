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
      home: _authController.isLoggedIn
          ? const MainNavigationShell()
          : LoginPage(
              onLoginSuccess: () {
                setState(() {});
              },
            ),
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
