import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PraktikanDashboardPage extends StatelessWidget {
  final VoidCallback? onNavigateToAttendance;
  final VoidCallback? onNavigateToReports;

  const PraktikanDashboardPage({
    super.key,
    this.onNavigateToAttendance,
    this.onNavigateToReports,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_rounded,
              size: 64,
              color: AppColors.praktikan,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome - Dashboard Praktikan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
