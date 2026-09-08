import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class VaultScreenSkeleton extends StatelessWidget {
  const VaultScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(isDesktop ? 24 : 16.w),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 900 : double.infinity,
          ),
          child: ShimmerLoading(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Balance Card Skeleton
                _buildBalanceCardSkeleton(context, isDesktop),
                SizedBox(height: isDesktop ? 24 : 20.h),

                // 2. Transaction History Header Skeleton
                ShimmerPlaceholder(
                  width: isDesktop ? 160 : 140.w,
                  height: isDesktop ? 22 : 18.h,
                  borderRadius: 6.r,
                ),
                SizedBox(height: isDesktop ? 14 : 12.h),

                // 3. Filter Chips Row Skeleton
                _buildFilterChipsSkeleton(context, isDesktop),
                SizedBox(height: isDesktop ? 20 : 16.h),

                // 4. Transaction Cards List Skeleton
                const VaultTransactionsListSkeleton(
                  count: 5,
                  wrapWithShimmer: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCardSkeleton(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 28 : 22.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppColors.isDark
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Icon placeholder & Title placeholder
          Row(
            children: [
              ShimmerPlaceholder(
                width: isDesktop ? 36 : 32.w,
                height: isDesktop ? 36 : 32.w,
                borderRadius: 10.r,
              ),
              SizedBox(width: isDesktop ? 12 : 10.w),
              ShimmerPlaceholder(
                width: isDesktop ? 140 : 120.w,
                height: isDesktop ? 16 : 14.h,
                borderRadius: 4.r,
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 16 : 14.h),

          // Big Balance Placeholder
          ShimmerPlaceholder(
            width: isDesktop ? 220 : 180.w,
            height: isDesktop ? 40 : 34.h,
            borderRadius: 8.r,
          ),
          SizedBox(height: isDesktop ? 24 : 20.h),

          // Action Buttons: Deposit & Withdrawal
          Row(
            children: [
              Expanded(
                child: ShimmerPlaceholder(
                  height: isDesktop ? 48 : 44.h,
                  borderRadius: 14.r,
                ),
              ),
              SizedBox(width: isDesktop ? 14 : 12.w),
              Expanded(
                child: ShimmerPlaceholder(
                  height: isDesktop ? 48 : 44.h,
                  borderRadius: 14.r,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsSkeleton(BuildContext context, bool isDesktop) {
    final chipWidths = isDesktop
        ? [70.0, 60.0, 65.0, 85.0, 85.0]
        : [65.0.w, 55.0.w, 60.0.w, 75.0.w, 75.0.w];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: chipWidths.map((w) {
          return Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: ShimmerPlaceholder(
              width: w,
              height: isDesktop ? 36 : 32.h,
              borderRadius: 20.r,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class VaultTransactionsListSkeleton extends StatelessWidget {
  final int count;
  final bool wrapWithShimmer;

  const VaultTransactionsListSkeleton({
    super.key,
    this.count = 4,
    this.wrapWithShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final list = ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => const VaultTransactionCardSkeleton(),
    );

    if (wrapWithShimmer) {
      return ShimmerLoading(child: list);
    }
    return list;
  }
}

class VaultTransactionCardSkeleton extends StatelessWidget {
  const VaultTransactionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 12 : 10.h),
      padding: EdgeInsets.all(isDesktop ? 16 : 14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.isDark
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Icon Box
          ShimmerPlaceholder(
            width: isDesktop ? 46 : 42.w,
            height: isDesktop ? 46 : 42.w,
            borderRadius: 12.r,
          ),
          SizedBox(width: isDesktop ? 14 : 12.w),

          // Title & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShimmerPlaceholder(
                  width: isDesktop ? 160 : 130.w,
                  height: isDesktop ? 16 : 14.h,
                  borderRadius: 4.r,
                ),
                SizedBox(height: isDesktop ? 8 : 6.h),
                Row(
                  children: [
                    ShimmerPlaceholder(
                      width: isDesktop ? 60 : 50.w,
                      height: isDesktop ? 14 : 12.h,
                      borderRadius: 4.r,
                    ),
                    SizedBox(width: 8.w),
                    ShimmerPlaceholder(
                      width: isDesktop ? 80 : 70.w,
                      height: isDesktop ? 14 : 12.h,
                      borderRadius: 4.r,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount & balance after
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShimmerPlaceholder(
                width: isDesktop ? 80 : 65.w,
                height: isDesktop ? 18 : 16.h,
                borderRadius: 4.r,
              ),
              SizedBox(height: isDesktop ? 6 : 4.h),
              ShimmerPlaceholder(
                width: isDesktop ? 60 : 45.w,
                height: isDesktop ? 12 : 10.h,
                borderRadius: 4.r,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
