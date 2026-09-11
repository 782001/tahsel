import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class InventoryAnalyticsSkeleton extends StatelessWidget {
  const InventoryAnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(isDesktop ? 20 : 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: 2 Top KPI metric cards
          Row(
            children: [
              Expanded(child: _buildMetricCardSkeleton(isDesktop: isDesktop)),
              SizedBox(width: isDesktop ? 12 : 10.w),
              Expanded(child: _buildMetricCardSkeleton(isDesktop: isDesktop)),
            ],
          ),
          SizedBox(height: isDesktop ? 12 : 10.h),

          // Row 2: Tied-up capital metric card
          _buildMetricCardSkeleton(isDesktop: isDesktop, hasSubtitle: true),
          SizedBox(height: isDesktop ? 16 : 14.h),

          // Tab selector skeleton
          ShimmerLoading(
            child: ShimmerPlaceholder(
              width: double.infinity,
              height: isDesktop ? 46 : 42.h,
              borderRadius: 12,
            ),
          ),
          SizedBox(height: isDesktop ? 16 : 14.h),

          // List of analysis item cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            itemBuilder: (_, __) => _buildAnalyticsItemSkeleton(isDesktop: isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCardSkeleton({required bool isDesktop, bool hasSubtitle = false}) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 14 : 12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 14.r),
        boxShadow: const [AppColors.shadow],
      ),
      child: ShimmerLoading(
        child: Row(
          children: [
            ShimmerPlaceholder(
              width: isDesktop ? 36 : 36.r,
              height: isDesktop ? 36 : 36.r,
              shape: BoxShape.circle,
            ),
            SizedBox(width: isDesktop ? 10 : 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerPlaceholder(
                    width: isDesktop ? 80 : 70.w,
                    height: 12,
                    borderRadius: 4,
                  ),
                  SizedBox(height: isDesktop ? 4 : 4.h),
                  ShimmerPlaceholder(
                    width: isDesktop ? 95 : 80.w,
                    height: 16,
                    borderRadius: 4,
                  ),
                  if (hasSubtitle) ...[
                    SizedBox(height: isDesktop ? 4 : 4.h),
                    ShimmerPlaceholder(
                      width: isDesktop ? 60 : 50.w,
                      height: 10,
                      borderRadius: 4,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsItemSkeleton({required bool isDesktop}) {
    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 12 : 10.h),
      padding: EdgeInsets.all(isDesktop ? 16 : 14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 14.r),
        boxShadow: const [AppColors.shadow],
      ),
      child: ShimmerLoading(
        child: Row(
          children: [
            ShimmerPlaceholder(
              width: isDesktop ? 40 : 40.r,
              height: isDesktop ? 40 : 40.r,
              shape: BoxShape.circle,
            ),
            SizedBox(width: isDesktop ? 14 : 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerPlaceholder(
                    width: isDesktop ? 130 : 110.w,
                    height: 16,
                    borderRadius: 4,
                  ),
                  SizedBox(height: isDesktop ? 6 : 5.h),
                  ShimmerPlaceholder(
                    width: isDesktop ? 80 : 70.w,
                    height: 12,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShimmerPlaceholder(
                  width: isDesktop ? 65 : 55.w,
                  height: 16,
                  borderRadius: 4,
                ),
                SizedBox(height: isDesktop ? 6 : 5.h),
                ShimmerPlaceholder(
                  width: isDesktop ? 50 : 45.w,
                  height: 18,
                  borderRadius: 6,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
