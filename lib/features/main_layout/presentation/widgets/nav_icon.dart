import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';

class NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final MainLayoutCubit cubit;

  const NavIcon({
    required this.icon,
    required this.label,
    required this.index,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = cubit.currentIndex == index;
    final color = isSelected ? AppColors.primaryColor : AppColors.sandText;

    return GestureDetector(
      onTap: () => cubit.changeBottomNav(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.1)
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
