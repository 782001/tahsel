import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';

class QuickAddTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final IconData? icon;
  final String? prefixText;
  final String? suffixText;
  final bool isNumber;
  final ValueChanged<String>? onChanged;

  const QuickAddTextField({
    super.key,
    required this.hint,
    this.controller,
    this.icon,
    this.prefixText,
    this.suffixText,
    this.isNumber = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: onChanged,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.blackLight.withOpacity(0.5),
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: icon != null
            ? Icon(icon, color: AppColors.blackLight)
            : prefixText != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      prefixText!,
                      style: TextStyle(
                        color: AppColors.stitchOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
        suffixText: suffixText,
        suffixStyle: TextStyle(
          color: AppColors.blackLight,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: AppColors.stitchSurfaceHigh.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}
