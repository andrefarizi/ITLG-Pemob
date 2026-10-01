import 'package:flutter/material.dart';
import '../../../core/utils/constants.dart';

/// Widget shared RoleBadge untuk menampilkan badge role aktif pengguna.
/// Digunakan di seluruh views lintas role.
class SharedRoleBadge extends StatelessWidget {
  final UserRole role;
  final bool showLabel;

  const SharedRoleBadge({
    super.key,
    required this.role,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: role.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: role.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(role.icon, color: role.color, size: 14),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              role.displayName,
              style: TextStyle(
                color: role.color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
