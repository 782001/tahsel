import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class AppearanceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const AppearanceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isDesktop ? 20 : 20.h,
          horizontal: isDesktop ? 16 : 16.w,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
          border: isSelected
              ? Border.all(color: AppColors.primaryColor, width: 1.5)
              : Border.all(
                  color: AppColors.disabledColor.withValues(alpha: 0.1),
                  width: 1,
                ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryColor : AppColors.sandText,
              size: isDesktop ? 32 : 32,
            ),
            SizedBox(height: isDesktop ? 12 : 12.h),
            Text(
              title,
              style: TextStyles.customStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.textColor2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
