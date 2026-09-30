import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class CustodySummarySkeleton extends StatelessWidget {
  const CustodySummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerPlaceholder(
                  width: isDesktop ? 20 : 20.r,
                  height: isDesktop ? 20 : 20.r,
                  shape: BoxShape.circle,
                ),
                SizedBox(width: isDesktop ? 8 : 8.w),
                ShimmerPlaceholder(
                  width: isDesktop ? 160 : 140.w,
                  height: isDesktop ? 16 : 14,
                  borderRadius: 4,
                ),
                const Spacer(),
                ShimmerPlaceholder(
                  width: isDesktop ? 85 : 75.w,
                  height: isDesktop ? 24 : 22.h,
                  borderRadius: isDesktop ? 20 : 20.r,
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 14 : 14.h),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(isDesktop ? 12 : 12.r),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreyColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerPlaceholder(width: isDesktop ? 60 : 50.w, height: 10, borderRadius: 3),
                        SizedBox(height: isDesktop ? 6 : 6.h),
                        ShimmerPlaceholder(width: isDesktop ? 70 : 60.w, height: 14, borderRadius: 3),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: isDesktop ? 10 : 10.w),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(isDesktop ? 12 : 12.r),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreyColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerPlaceholder(width: isDesktop ? 60 : 50.w, height: 10, borderRadius: 3),
                        SizedBox(height: isDesktop ? 6 : 6.h),
                        ShimmerPlaceholder(width: isDesktop ? 70 : 60.w, height: 14, borderRadius: 3),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: isDesktop ? 10 : 10.w),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(isDesktop ? 12 : 12.r),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreyColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerPlaceholder(width: isDesktop ? 60 : 50.w, height: 10, borderRadius: 3),
                        SizedBox(height: isDesktop ? 6 : 6.h),
                        ShimmerPlaceholder(width: isDesktop ? 70 : 60.w, height: 14, borderRadius: 3),
                      ],
                    ),
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

class CustodyCardSkeleton extends StatelessWidget {
  const CustodyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 12 : 12.h),
      padding: EdgeInsets.all(isDesktop ? 18 : 14.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        border: Border.all(color: AppColors.dividerColor.withValues(alpha: 0.5)),
      ),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Avatar + Name/Date + Status Badge + Menu
            Row(
              children: [
                ShimmerPlaceholder(
                  width: isDesktop ? 40 : 40.r,
                  height: isDesktop ? 40 : 40.r,
                  shape: BoxShape.circle,
                ),
                SizedBox(width: isDesktop ? 12 : 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerPlaceholder(
                        width: isDesktop ? 140 : 120.w,
                        height: isDesktop ? 16 : 15,
                        borderRadius: 4,
                      ),
                      SizedBox(height: isDesktop ? 6 : 5.h),
                      ShimmerPlaceholder(
                        width: isDesktop ? 90 : 80.w,
                        height: isDesktop ? 12 : 11,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ),
                ShimmerPlaceholder(
                  width: isDesktop ? 65 : 60.w,
                  height: isDesktop ? 22 : 20.h,
                  borderRadius: isDesktop ? 12 : 12.r,
                ),
                SizedBox(width: isDesktop ? 8 : 8.w),
                ShimmerPlaceholder(
                  width: isDesktop ? 18 : 18.r,
                  height: isDesktop ? 18 : 18.r,
                  borderRadius: 4,
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 14 : 12.h),

            // Progress Bar Line
            ShimmerPlaceholder(
              width: double.infinity,
              height: isDesktop ? 6 : 6.h,
              borderRadius: 4,
            ),
            SizedBox(height: isDesktop ? 14 : 12.h),

            // Three Metrics Strip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerPlaceholder(
                        width: isDesktop ? 60 : 50.w,
                        height: 10,
                        borderRadius: 3,
                      ),
                      SizedBox(height: isDesktop ? 4 : 4.h),
                      ShimmerPlaceholder(
                        width: isDesktop ? 80 : 70.w,
                        height: 14,
                        borderRadius: 3,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ShimmerPlaceholder(
                        width: isDesktop ? 60 : 50.w,
                        height: 10,
                        borderRadius: 3,
                      ),
                      SizedBox(height: isDesktop ? 4 : 4.h),
                      ShimmerPlaceholder(
                        width: isDesktop ? 80 : 70.w,
                        height: 14,
                        borderRadius: 3,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ShimmerPlaceholder(
                        width: isDesktop ? 60 : 50.w,
                        height: 10,
                        borderRadius: 3,
                      ),
                      SizedBox(height: isDesktop ? 4 : 4.h),
                      ShimmerPlaceholder(
                        width: isDesktop ? 80 : 70.w,
                        height: 14,
                        borderRadius: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 14 : 12.h),

            // Bottom Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerPlaceholder(
                  width: isDesktop ? 90 : 80.w,
                  height: isDesktop ? 32 : 30.h,
                  borderRadius: isDesktop ? 10 : 10.r,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShimmerPlaceholder(
                      width: isDesktop ? 75 : 68.w,
                      height: isDesktop ? 32 : 30.h,
                      borderRadius: isDesktop ? 10 : 10.r,
                    ),
                    SizedBox(width: isDesktop ? 8 : 8.w),
                    ShimmerPlaceholder(
                      width: isDesktop ? 75 : 68.w,
                      height: isDesktop ? 32 : 30.h,
                      borderRadius: isDesktop ? 10 : 10.r,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CustodyListSkeleton extends StatelessWidget {
  const CustodyListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 24 : 16.w,
        isDesktop ? 16 : 16.h,
        isDesktop ? 24 : 16.w,
        isDesktop ? 80 : 80.h,
      ),
      children: [
        const CustodySummarySkeleton(),
        SizedBox(height: isDesktop ? 16 : 16.h),
        // Search bar skeleton
        ShimmerLoading(
          child: ShimmerPlaceholder(
            width: double.infinity,
            height: isDesktop ? 48 : 46.h,
            borderRadius: isDesktop ? 12 : 12.r,
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 16.h),
        ...List.generate(3, (_) => const CustodyCardSkeleton()),
      ],
    );
  }
}
