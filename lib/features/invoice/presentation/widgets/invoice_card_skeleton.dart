import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class InvoiceCardSkeleton extends StatelessWidget {
  const InvoiceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [AppColors.shadow],
      ),
      padding: const EdgeInsets.all(16),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header: Customer Name + #ID & Status Badge ──────────
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerPlaceholder(
                      width: 140,
                      height: 16,
                      borderRadius: 4,
                    ),
                    SizedBox(height: 6),
                    ShimmerPlaceholder(
                      width: 80,
                      height: 12,
                      borderRadius: 4,
                    ),
                  ],
                ),
                ShimmerPlaceholder(
                  width: 65,
                  height: 24,
                  borderRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: AppColors.dividerColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),

            // ── Amount Columns (Total, Paid, Remaining) ─────────────
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerPlaceholder(
                      width: 55,
                      height: 11,
                      borderRadius: 3,
                    ),
                    SizedBox(height: 6),
                    ShimmerPlaceholder(
                      width: 70,
                      height: 16,
                      borderRadius: 4,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerPlaceholder(
                      width: 55,
                      height: 11,
                      borderRadius: 3,
                    ),
                    SizedBox(height: 6),
                    ShimmerPlaceholder(
                      width: 70,
                      height: 16,
                      borderRadius: 4,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerPlaceholder(
                      width: 55,
                      height: 11,
                      borderRadius: 3,
                    ),
                    SizedBox(height: 6),
                    ShimmerPlaceholder(
                      width: 70,
                      height: 16,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Date + Arrow ────────────────────────────────────────
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerPlaceholder(
                  width: 85,
                  height: 12,
                  borderRadius: 3,
                ),
                ShimmerPlaceholder(
                  width: 14,
                  height: 14,
                  borderRadius: 3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
