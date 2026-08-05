import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class LanguageOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 20 : 20.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
          border: isSelected
              ? Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                  width: 1.5,
                )
              : null,
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isDesktop ? 48 : 48.w,
              height: isDesktop ? 48 : 48.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.veryLightGrey,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.language,
                  color: isSelected ? AppColors.white : AppColors.sandText,
                  size: isDesktop ? 24 : 24,
                ),
              ),
            ),
            SizedBox(width: isDesktop ? 16 : 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.customStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor2,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.sandText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primaryColor,
                size: isDesktop ? 24 : 24,
              ),
          ],
        ),
      ),
    );
  }
}
