import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class CategoryCardSkeleton extends StatelessWidget {
  const CategoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 12 : 12.h),
      padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 14 : 14.r),
        boxShadow: const [AppColors.shadow],
      ),
      child: ShimmerLoading(
        child: Row(
          children: [
            ShimmerPlaceholder(
              width: isDesktop ? 44 : 44.r,
              height: isDesktop ? 44 : 44.r,
              shape: BoxShape.circle,
            ),
            SizedBox(width: isDesktop ? 16 : 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerPlaceholder(
                    width: isDesktop ? 140 : 120.w,
                    height: 16,
                    borderRadius: 4,
                  ),
                  SizedBox(height: isDesktop ? 6 : 5.h),
                  ShimmerPlaceholder(
                    width: isDesktop ? 90 : 80.w,
                    height: 12,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            SizedBox(width: isDesktop ? 8 : 8.w),
            ShimmerPlaceholder(
              width: isDesktop ? 22 : 20.w,
              height: isDesktop ? 22 : 20.h,
              borderRadius: 4,
            ),
            SizedBox(width: 12.w),
            ShimmerPlaceholder(
              width: isDesktop ? 22 : 20.w,
              height: isDesktop ? 22 : 20.h,
              borderRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
