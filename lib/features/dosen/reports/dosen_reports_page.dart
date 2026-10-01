import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DosenReportsPage extends StatelessWidget {
  const DosenReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_rounded,
              size: 64,
              color: AppColors.dosen,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome - Laporan Dosen',
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
