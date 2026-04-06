import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';

enum QuickAddMode { playStation, shop }

class QuickAddModeSelector extends StatelessWidget {
  final QuickAddMode selectedMode;
  final ValueChanged<QuickAddMode> onModeChanged;

  const QuickAddModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            title: AppStrings.shop.tr(),
            icon: Icons.storefront,
            isSelected: selectedMode == QuickAddMode.shop,
            onTap: () => onModeChanged(QuickAddMode.shop),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ModeCard(
            title: AppStrings.playStation.tr(),
            icon: Icons.sports_esports,
            isSelected: selectedMode == QuickAddMode.playStation,
            onTap: () => onModeChanged(QuickAddMode.playStation),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.whiteColor,
                  size: 20,
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? AppColors.whiteColor
                        : AppColors.stitchBlue,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected
                          ? AppColors.whiteColor
                          : AppColors.black,
                    ),
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
