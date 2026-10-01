import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AslabDashboardPage extends StatelessWidget {
  final VoidCallback? onNavigateToAttendance;
  final VoidCallback? onNavigateToReports;
  final VoidCallback? onOpenTicketing;

  const AslabDashboardPage({
    super.key,
    this.onNavigateToAttendance,
    this.onNavigateToReports,
    this.onOpenTicketing,
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
              Icons.terminal_rounded,
              size: 64,
              color: AppColors.aslab,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome - Dashboard Aslab',
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
