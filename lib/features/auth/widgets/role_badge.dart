import 'package:flutter/material.dart';
import '../../../core/utils/constants.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;

  const RoleBadge({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final color = role.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(role.icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            role.displayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
