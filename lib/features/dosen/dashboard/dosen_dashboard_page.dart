import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DosenDashboardPage extends StatelessWidget {
  final VoidCallback? onNavigateToReports;

  const DosenDashboardPage({
    super.key,
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
              Icons.supervisor_account_rounded,
              size: 64,
              color: AppColors.dosen,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome - Dashboard Dosen',
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
