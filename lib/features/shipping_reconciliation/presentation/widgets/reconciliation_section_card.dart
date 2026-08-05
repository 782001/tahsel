import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/styles.dart';
import '../../../../core/widgets/responsive_layout.dart';

class ReconciliationSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const ReconciliationSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 14 : 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 16 : 14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isDesktop ? 8 : 7.r),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          icon,
                          color: AppColors.primaryColor,
                          size: isDesktop ? 18 : 18.r,
                        ),
                      ),
                      SizedBox(width: isDesktop ? 10 : 8.w),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 14 : 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blackReal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: isDesktop ? 8 : 8.w),
                  trailing!,
                ],
              ],
            ),

            SizedBox(height: isDesktop ? 12 : 10.h),

            Divider(
              height: 1,
              color: AppColors.sandText.withValues(alpha: 0.15),
            ),

            SizedBox(height: isDesktop ? 12 : 10.h),

            child,
          ],
        ),
      ),
    );
  }
}
