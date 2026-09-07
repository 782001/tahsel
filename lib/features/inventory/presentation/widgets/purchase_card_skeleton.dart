import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class PurchaseCardSkeleton extends StatelessWidget {
  const PurchaseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 12 : 12.h),
      padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 14 : 14.r),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top Row: ID Badge + Payment Method Badge + 3-dots ───
            Row(
              children: [
                ShimmerPlaceholder(
                  width: isDesktop ? 55 : 55.w,
                  height: isDesktop ? 20 : 18.h,
                  borderRadius: 6,
                ),
                const Spacer(),
                ShimmerPlaceholder(
                  width: isDesktop ? 75 : 70.w,
                  height: isDesktop ? 20 : 18.h,
                  borderRadius: 6,
                ),
                SizedBox(width: isDesktop ? 6 : 6.w),
                ShimmerPlaceholder(
                  width: isDesktop ? 14 : 14.w,
                  height: isDesktop ? 20 : 18.h,
                  borderRadius: 4,
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 12 : 10.h),

            // ── Middle Row: Avatar + Supplier & Date + Total Amount ─
            Row(
              children: [
                ShimmerPlaceholder(
                  width: isDesktop ? 36 : 36.w,
                  height: isDesktop ? 36 : 36.w,
                  shape: BoxShape.circle,
                ),
                SizedBox(width: isDesktop ? 8 : 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerPlaceholder(
                        width: isDesktop ? 130 : 110.w,
                        height: 15,
                        borderRadius: 4,
                      ),
                      SizedBox(height: isDesktop ? 5 : 4.h),
                      ShimmerPlaceholder(
                        width: isDesktop ? 80 : 70.w,
                        height: 12,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isDesktop ? 8 : 8.w),
                ShimmerPlaceholder(
                  width: isDesktop ? 90 : 80.w,
                  height: 18,
                  borderRadius: 4,
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 12 : 10.h),

            // ── Bottom Items Simulated Strip ────────────────────────
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 10 : 8.w,
                vertical: isDesktop ? 6 : 6.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.scafoldBackGround.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  ShimmerPlaceholder(
                    width: isDesktop ? 6 : 6.w,
                    height: isDesktop ? 6 : 6.h,
                    shape: BoxShape.circle,
                  ),
                  SizedBox(width: isDesktop ? 8 : 8.w),
                  ShimmerPlaceholder(
                    width: isDesktop ? 100 : 85.w,
                    height: 11,
                    borderRadius: 3,
                  ),
                  const Spacer(),
                  ShimmerPlaceholder(
                    width: isDesktop ? 50 : 45.w,
                    height: 11,
                    borderRadius: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
