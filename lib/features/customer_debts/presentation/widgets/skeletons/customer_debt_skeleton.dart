import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class CustomerDebtCardSkeleton extends StatelessWidget {
  const CustomerDebtCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return ShimmerLoading(
      child: Container(
        margin: EdgeInsets.only(
          bottom: isDesktop ? 12 : 12.h,
          left: isDesktop ? 0 : 24.w,
          right: isDesktop ? 0 : 24.w,
        ),
        padding: EdgeInsets.all(isDesktop ? 16 : 16.r),
        decoration: BoxDecoration(
          color: AppColors.debtCardSurface,
          borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        ),
        child: Column(
          children: [
            Row(
              children: [
                ShimmerPlaceholder(
                  width: isDesktop ? 48 : 48.r,
                  height: isDesktop ? 48 : 48.r,
                  shape: BoxShape.circle,
                ),
                SizedBox(width: isDesktop ? 12 : 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerPlaceholder(
                        width: isDesktop ? 150 : 150.w,
                        height: isDesktop ? 18 : 18.h,
                      ),
                      SizedBox(height: isDesktop ? 6 : 6.h),
                      ShimmerPlaceholder(
                        width: isDesktop ? 80 : 80.w,
                        height: isDesktop ? 14 : 14.h,
                      ),
                    ],
                  ),
                ),
                ShimmerPlaceholder(
                  width: isDesktop ? 60 : 60.w,
                  height: isDesktop ? 24 : 24.h,
                  borderRadius: isDesktop ? 8 : 8.r,
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 16 : 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: ShimmerPlaceholder(
                    width: isDesktop ? 120 : 120.w,
                    height: isDesktop ? 16 : 16.h,
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 16.w),
                Flexible(
                  child: ShimmerPlaceholder(
                    width: isDesktop ? 100 : 100.w,
                    height: isDesktop ? 20 : 20.h,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
