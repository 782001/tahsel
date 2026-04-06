import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/shared/widgets/fields/text_widget.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final double? height;
  final double? width;
  final double? borderRadius;
  final IconData? icon;
  final Color? iconColor;
  final bool isLoading;

  const CustomButton({
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.height,
    this.width,
    this.borderRadius,
    this.icon,
    this.iconColor,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.actionButton,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: textColor ?? Colors.white),
            borderRadius: BorderRadius.circular((borderRadius ?? 12).r),
          ),
          elevation: 1,
          shadowColor: AppColors.actionButton.withOpacity(0.3),
        ),
        child: isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,

                  strokeWidth: 2.w,
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: iconColor ?? Colors.white, size: 20.sp),
                      SizedBox(width: 8.w),
                    ],
                    TextWidget(
                      text,
                      style: TextStyles.font14Weight400RightAligned().copyWith(
                        color: textColor ?? Colors.white,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
