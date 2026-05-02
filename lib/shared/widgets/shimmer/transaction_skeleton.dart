import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class TransactionCardSkeleton extends StatelessWidget {
  const TransactionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.debtCardSurface,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerPlaceholder(width: 120.w, height: 16.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShimmerPlaceholder(width: 80.w, height: 20.h),
                    SizedBox(height: 4.h),
                    ShimmerPlaceholder(width: 100.w, height: 12.h),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            const Divider(height: 1),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ShimmerPlaceholder(
                      width: 14.r,
                      height: 14.r,
                      borderRadius: 2.r,
                    ),
                    SizedBox(width: 6.w),
                    ShimmerPlaceholder(width: 150.w, height: 12.h),
                  ],
                ),
                ShimmerPlaceholder(
                  width: 16.r,
                  height: 16.r,
                  borderRadius: 2.r,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
