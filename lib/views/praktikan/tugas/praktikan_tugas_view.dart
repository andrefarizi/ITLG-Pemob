import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PraktikanTugasView extends StatelessWidget {
  const PraktikanTugasView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file_rounded,
              size: 64,
              color: AppColors.praktikan,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome - Tugas Praktikan',
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
