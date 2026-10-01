import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class LaboranJadwalView extends StatelessWidget {
  const LaboranJadwalView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.meeting_room_rounded,
              size: 64,
              color: AppColors.laboran,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome - Jadwal Laboran',
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
