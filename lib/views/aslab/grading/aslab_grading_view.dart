import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AslabGradingView extends StatelessWidget {
  const AslabGradingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_rounded,
              size: 64,
              color: AppColors.aslab,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome - Grading Aslab',
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
