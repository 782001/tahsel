import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class SupplierCardSkeleton extends StatelessWidget {
  const SupplierCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 12 : 12.h),
      padding: EdgeInsets.all(isDesktop ? 16 : 14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        border: Border.all(
          color: AppColors.dividerColor.withValues(alpha: 0.7),
        ),
        boxShadow: const [AppColors.shadow],
      ),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Avatar + Names + Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerPlaceholder(
                  width: isDesktop ? 44 : 44.r,
                  height: isDesktop ? 44 : 44.r,
                  borderRadius: 12,
                ),
                SizedBox(width: isDesktop ? 12 : 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerPlaceholder(
                        width: isDesktop ? 130 : 110.w,
                        height: 16,
                        borderRadius: 4,
                      ),
                      SizedBox(height: isDesktop ? 6 : 5.h),
                      ShimmerPlaceholder(
                        width: isDesktop ? 90 : 75.w,
                        height: 12,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isDesktop ? 8 : 8.w),
                ShimmerPlaceholder(
                  width: isDesktop ? 20 : 18.w,
                  height: isDesktop ? 20 : 18.h,
                  borderRadius: 4,
                ),
                SizedBox(width: 10.w),
                ShimmerPlaceholder(
                  width: isDesktop ? 20 : 18.w,
                  height: isDesktop ? 20 : 18.h,
                  borderRadius: 4,
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 12 : 10.h),
            // Chips row
            Row(
              children: [
                ShimmerPlaceholder(
                  width: isDesktop ? 85 : 75.w,
                  height: isDesktop ? 24 : 22.h,
                  borderRadius: 8,
                ),
                SizedBox(width: isDesktop ? 8 : 8.w),
                ShimmerPlaceholder(
                  width: isDesktop ? 95 : 85.w,
                  height: isDesktop ? 24 : 22.h,
                  borderRadius: 8,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
