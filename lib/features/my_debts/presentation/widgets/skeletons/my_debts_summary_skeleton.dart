import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class MyDebtsSummarySkeleton extends StatelessWidget {
  const MyDebtsSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return ShimmerLoading(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isDesktop ? 0 : 24,
          vertical: 16,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.debtCardSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerPlaceholder(width: 40, height: 40, borderRadius: 12),
                SizedBox(width: 12),
                ShimmerPlaceholder(width: 120, height: 20),
              ],
            ),
            SizedBox(height: 16),
            ShimmerPlaceholder(width: 180, height: 32),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerPlaceholder(width: 100, height: 16),
                ShimmerPlaceholder(width: 100, height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
