import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AuthInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const AuthInputField({
    super.key,
    this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
