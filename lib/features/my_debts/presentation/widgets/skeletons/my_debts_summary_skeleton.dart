import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class MyDebtsSummarySkeleton extends StatelessWidget {
  const MyDebtsSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.debtCardSurface,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerPlaceholder(
                  width: 40.r,
                  height: 40.r,
                  borderRadius: 12.r,
                ),
                SizedBox(width: 12.w),
                ShimmerPlaceholder(width: 120.w, height: 20.h),
              ],
            ),
            SizedBox(height: 16.h),
            ShimmerPlaceholder(width: 180.w, height: 32.h),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerPlaceholder(width: 100.w, height: 16.h),
                ShimmerPlaceholder(width: 100.w, height: 16.h),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
