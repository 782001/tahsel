import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class CustomerCardSkeleton extends StatelessWidget {
  const CustomerCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Card(
      margin: isDesktop ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.blackLight.withAlpha(20), width: 1),
      ),
      color: AppColors.debtCardSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ShimmerLoading(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShimmerPlaceholder(
                      width: isDesktop ? 160 : 130,
                      height: 18,
                      borderRadius: 6,
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        ShimmerPlaceholder(
                          width: 85,
                          height: 22,
                          borderRadius: 8,
                        ),
                        SizedBox(width: 8),
                        ShimmerPlaceholder(
                          width: 95,
                          height: 14,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const ShimmerPlaceholder(
                width: 14,
                height: 14,
                borderRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
