import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AslabRekapView extends StatelessWidget {
  const AslabRekapView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_chart_rounded,
              size: 64,
              color: AppColors.aslab,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome - Rekap Aslab',
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
