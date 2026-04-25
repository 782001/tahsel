import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';

class QuickAddTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final IconData? icon;
  final String? prefixText;
  final String? suffixText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool isNumber;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const QuickAddTextField({
    super.key,
    required this.hint,
    this.controller,
    this.icon,
    this.prefixText,
    this.suffixText,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.isNumber = false,
    this.errorText,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorColor: AppColors.primaryColor,
      controller: controller,
      focusNode: focusNode,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.black),
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
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
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon, color: AppColors.primaryColor),
                onPressed: onSuffixIconPressed,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }
}
