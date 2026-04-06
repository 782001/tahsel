import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';

class AddExpenseField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final IconData? suffixIcon;
  final String? prefixText;
  final bool isNumber;
  final bool isMultiline;
  final VoidCallback? onTap;
  final bool readOnly;

  const AddExpenseField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.suffixIcon,
    this.prefixText,
    this.isNumber = false,
    this.isMultiline = false,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Text(
            label,
            style: TextStyles.customStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.blackLight,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: TextField(
            controller: controller,
            onTap: onTap,
            readOnly: readOnly,
            maxLines: isMultiline ? 4 : 1,
            keyboardType: isMultiline
                ? TextInputType.multiline
                : isNumber
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
            style: TextStyles.customStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyles.customStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.blackLight.withOpacity(0.4),
              ),
              prefixIcon: prefixText != null
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        prefixText!,
                        style: TextStyles.customStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.stitchOrange,
                        ),
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: suffixIcon != null
                  ? Icon(suffixIcon, color: AppColors.blackLight, size: 22.r)
                  : null,
              filled: true,
              fillColor: AppColors.stitchSurfaceLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
            ),
          ),
        ),
      ],
    );
  }
}
