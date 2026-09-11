import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class StockMovementCardSkeleton extends StatelessWidget {
  const StockMovementCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 12 : 12.h),
      padding: EdgeInsets.all(isDesktop ? 16 : 14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 14 : 14.r),
        boxShadow: const [AppColors.shadow],
      ),
      child: ShimmerLoading(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShimmerPlaceholder(
              width: isDesktop ? 36 : 36.r,
              height: isDesktop ? 36 : 36.r,
              shape: BoxShape.circle,
            ),
            SizedBox(width: isDesktop ? 12 : 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ShimmerPlaceholder(
                          width: isDesktop ? 140 : 120.w,
                          height: 16,
                          borderRadius: 4,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      ShimmerPlaceholder(
                        width: isDesktop ? 50 : 45.w,
                        height: 16,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 8 : 6.h),
                  Row(
                    children: [
                      ShimmerPlaceholder(
                        width: isDesktop ? 65 : 55.w,
                        height: 18,
                        borderRadius: 4,
                      ),
                      SizedBox(width: 6.w),
                      ShimmerPlaceholder(
                        width: isDesktop ? 75 : 65.w,
                        height: 18,
                        borderRadius: 4,
                      ),
                      const Spacer(),
                      ShimmerPlaceholder(
                        width: isDesktop ? 55 : 45.w,
                        height: 12,
                        borderRadius: 4,
                      ),
                    ],
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
