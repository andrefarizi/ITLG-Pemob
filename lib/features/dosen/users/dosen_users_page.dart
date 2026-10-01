import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DosenUsersPage extends StatelessWidget {
  final VoidCallback? onRoleSwitch;

  const DosenUsersPage({super.key, this.onRoleSwitch});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: AppColors.dosen,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome - Pengguna Dosen',
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
