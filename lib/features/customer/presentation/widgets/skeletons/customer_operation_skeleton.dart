import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class CustomerSummarySkeleton extends StatelessWidget {
  const CustomerSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withAlpha(180),
            AppColors.primaryColor.withAlpha(140),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withAlpha(40),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.white.withAlpha(80),
        highlightColor: Colors.white.withAlpha(180),
        period: const Duration(milliseconds: 1500),
        child: Column(
          children: [
            _buildRow(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white24),
            ),
            _buildRow(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white24),
            ),
            _buildRow(isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRow({bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ShimmerPlaceholder(
          width: isBold ? 110 : 90,
          height: isBold ? 16 : 14,
          borderRadius: 4,
        ),
        ShimmerPlaceholder(
          width: isBold ? 85 : 70,
          height: isBold ? 18 : 14,
          borderRadius: 4,
        ),
      ],
    );
  }
}

class CustomerOperationTileSkeleton extends StatelessWidget {
  const CustomerOperationTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      margin: isDesktop ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const ShimmerLoading(
        child: Row(
          children: [
            ShimmerPlaceholder(
              width: 40,
              height: 40,
              shape: BoxShape.circle,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerPlaceholder(
                    width: 75,
                    height: 15,
                    borderRadius: 4,
                  ),
                  SizedBox(height: 6),
                  ShimmerPlaceholder(
                    width: 120,
                    height: 11,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            ShimmerPlaceholder(
              width: 70,
              height: 16,
              borderRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}
