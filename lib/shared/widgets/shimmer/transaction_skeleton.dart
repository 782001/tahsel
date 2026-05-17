import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class TransactionCardSkeleton extends StatelessWidget {
  const TransactionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return ShimmerLoading(
      child: Container(
        margin: EdgeInsets.only(bottom: isDesktop ? 16 : 16.h),
        padding: EdgeInsets.all(isDesktop ? 16 : 16.r),
        decoration: BoxDecoration(
          color: AppColors.debtCardSurface,
          borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerPlaceholder(
                  width: isDesktop ? 120 : 120.w,
                  height: isDesktop ? 16 : 16.h,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShimmerPlaceholder(
                      width: isDesktop ? 80 : 80.w,
                      height: isDesktop ? 20 : 20.h,
                    ),
                    SizedBox(height: isDesktop ? 4 : 4.h),
                    ShimmerPlaceholder(
                      width: isDesktop ? 100 : 100.w,
                      height: isDesktop ? 12 : 12.h,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 12 : 12.h),
            const Divider(height: 1),
            SizedBox(height: isDesktop ? 12 : 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ShimmerPlaceholder(
                      width: isDesktop ? 14 : 14.r,
                      height: isDesktop ? 14 : 14.r,
                      borderRadius: isDesktop ? 2 : 2.r,
                    ),
                    SizedBox(width: isDesktop ? 6 : 6.w),
                    ShimmerPlaceholder(
                      width: isDesktop ? 150 : 150.w,
                      height: isDesktop ? 12 : 12.h,
                    ),
                  ],
                ),
                ShimmerPlaceholder(
                  width: isDesktop ? 16 : 16.r,
                  height: isDesktop ? 16 : 16.r,
                  borderRadius: isDesktop ? 2 : 2.r,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
