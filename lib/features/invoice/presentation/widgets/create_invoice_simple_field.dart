import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';

class CreateInvoiceSimpleField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final bool isNumber;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool obscureText;
  final bool enableInteractiveSelection;
  final Widget? suffixIcon;

  const CreateInvoiceSimpleField({
    super.key,
    required this.controller,
    required this.hint,
    required this.label,
    this.isNumber = false,
    this.onChanged,
    this.readOnly = false,
    this.obscureText = false,
    this.enableInteractiveSelection = true,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.customStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          cursorColor: AppColors.primaryColor,
          controller: controller,
          readOnly: readOnly,
          obscureText: obscureText,
          enableInteractiveSelection: enableInteractiveSelection,
          keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
          onChanged: onChanged,
          style: TextStyles.customStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyles.customStyle(color: AppColors.disabledColor),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
