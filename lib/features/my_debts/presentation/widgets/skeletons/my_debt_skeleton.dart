import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class MyDebtCardSkeleton extends StatelessWidget {
  const MyDebtCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return ShimmerLoading(
      child: Container(
        margin: EdgeInsets.only(
          bottom: isDesktop ? 0 : 12,
          left: isDesktop ? 0 : 24,
          right: isDesktop ? 0 : 24,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.debtCardSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerPlaceholder(width: 150, height: 20),
                    SizedBox(height: 4),
                    ShimmerPlaceholder(width: 100, height: 14),
                  ],
                ),
                ShimmerPlaceholder(width: 60, height: 24, borderRadius: 8),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerPlaceholder(width: 80, height: 14),
                    SizedBox(height: 4),
                    ShimmerPlaceholder(width: 100, height: 18),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerPlaceholder(width: 80, height: 14),
                    SizedBox(height: 4),
                    ShimmerPlaceholder(width: 100, height: 18),
                  ],
                ),
              ],
            ),
            Divider(height: 24),
            Row(
              children: [
                ShimmerPlaceholder(width: 14, height: 14, borderRadius: 2),
                SizedBox(width: 6),
                ShimmerPlaceholder(width: 200, height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
