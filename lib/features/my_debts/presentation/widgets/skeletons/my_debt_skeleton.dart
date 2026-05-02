import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class MyDebtCardSkeleton extends StatelessWidget {
  const MyDebtCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, left: 24.w, right: 24.w),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.debtCardSurface,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerPlaceholder(width: 150.w, height: 20.h),
                    SizedBox(height: 4.h),
                    ShimmerPlaceholder(width: 100.w, height: 14.h),
                  ],
                ),
                ShimmerPlaceholder(
                  width: 60.w,
                  height: 24.h,
                  borderRadius: 8.r,
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerPlaceholder(width: 80.w, height: 14.h),
                    SizedBox(height: 4.h),
                    ShimmerPlaceholder(width: 100.w, height: 18.h),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerPlaceholder(width: 80.w, height: 14.h),
                    SizedBox(height: 4.h),
                    ShimmerPlaceholder(width: 100.w, height: 18.h),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                ShimmerPlaceholder(
                  width: 14.r,
                  height: 14.r,
                  borderRadius: 2.r,
                ),
                SizedBox(width: 6.w),
                ShimmerPlaceholder(width: 200.w, height: 14.h),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
