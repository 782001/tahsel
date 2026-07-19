import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';

class SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isNumber;
  final String? suffix;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    super.key,
    this.isNumber = false,
    this.suffix,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyles.customStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.blackLight,
              ),
            ),
            if (actionLabel != null && onAction != null)
              GestureDetector(
                onTap: onAction,
                child: Text(
                  actionLabel!,
                  style: TextStyles.customStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          cursorColor: AppColors.primaryColor,
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: TextStyles.customStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyles.customStyle(color: AppColors.disabledColor),
            suffixText: suffix,
            suffixStyle: TextStyles.customStyle(
              fontSize: 13,
              color: AppColors.blackLight,
            ),
            filled: true,
            fillColor: AppColors.veryLightGrey,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
