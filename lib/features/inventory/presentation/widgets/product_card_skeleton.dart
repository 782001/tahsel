import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 12 : 12.h),
      padding: EdgeInsets.all(isDesktop ? 16 : 14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        boxShadow: const [AppColors.shadow],
        border: Border.all(color: AppColors.dividerColor.withValues(alpha: 0.5)),
      ),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Status badge + Spacer + Action icons
            Row(
              children: [
                ShimmerPlaceholder(
                  width: isDesktop ? 75 : 68.w,
                  height: isDesktop ? 22 : 20.h,
                  borderRadius: 12,
                ),
                const Spacer(),
                ShimmerPlaceholder(
                  width: isDesktop ? 22 : 20.w,
                  height: isDesktop ? 22 : 20.h,
                  borderRadius: 4,
                ),
                SizedBox(width: 10.w),
                ShimmerPlaceholder(
                  width: isDesktop ? 22 : 20.w,
                  height: isDesktop ? 22 : 20.h,
                  borderRadius: 4,
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 10 : 8.h),

            // Middle Row: Avatar icon + Name + SKU
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerPlaceholder(
                  width: isDesktop ? 44 : 44.r,
                  height: isDesktop ? 44 : 44.r,
                  shape: BoxShape.circle,
                ),
                SizedBox(width: isDesktop ? 14 : 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerPlaceholder(
                        width: isDesktop ? 160 : 135.w,
                        height: 16,
                        borderRadius: 4,
                      ),
                      SizedBox(height: isDesktop ? 6 : 6.h),
                      Row(
                        children: [
                          ShimmerPlaceholder(
                            width: isDesktop ? 60 : 50.w,
                            height: 16,
                            borderRadius: 4,
                          ),
                          SizedBox(width: 6.w),
                          ShimmerPlaceholder(
                            width: isDesktop ? 70 : 60.w,
                            height: 16,
                            borderRadius: 4,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 12 : 10.h),

            // Bottom Row: Price + Stock badge
            Row(
              children: [
                ShimmerPlaceholder(
                  width: isDesktop ? 80 : 70.w,
                  height: 16,
                  borderRadius: 4,
                ),
                const Spacer(),
                ShimmerPlaceholder(
                  width: isDesktop ? 90 : 80.w,
                  height: 24,
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
