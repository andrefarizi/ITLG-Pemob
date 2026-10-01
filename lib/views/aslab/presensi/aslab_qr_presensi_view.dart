import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AslabQrPresensiView extends StatelessWidget {
  const AslabQrPresensiView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2_rounded,
              size: 64,
              color: AppColors.aslab,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome - Presensi Aslab',
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
