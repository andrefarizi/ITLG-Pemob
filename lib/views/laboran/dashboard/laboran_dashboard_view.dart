import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class LaboranDashboardView extends StatelessWidget {
  const LaboranDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_rounded,
              size: 64,
              color: AppColors.laboran,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome - Dashboard Laboran',
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
