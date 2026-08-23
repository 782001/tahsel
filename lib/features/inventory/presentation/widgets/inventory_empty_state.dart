import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class InventoryEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const InventoryEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 20 : 20.w),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: isDesktop ? 48 : 48,
                color: AppColors.primaryColor.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 16.h),
            Text(
              title,
              style: TextStyles.customStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.blackReal,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isDesktop ? 6 : 6.h),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                description,
                style: TextStyles.customStyle(
                  fontSize: 13,
                  color: AppColors.sandText,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: isDesktop ? 20 : 20.h),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 24.w,
                    vertical: isDesktop ? 12 : 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                  ),
                ),
                onPressed: onAction,
                // icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: Text(
                  actionLabel!,
                  style: TextStyles.customStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
