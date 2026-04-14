import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';

enum PlayStationMode { time, turn }

class QuickAddSubTabHeader extends StatelessWidget {
  final PlayStationMode selectedMode;
  final ValueChanged<PlayStationMode> onModeChanged;

  const QuickAddSubTabHeader({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _SubTab(
              title: AppStrings.byTime.tr(),
              isActive: selectedMode == PlayStationMode.time,
              onTap: () => onModeChanged(PlayStationMode.time),
            ),
          ),
          Expanded(
            child: _SubTab(
              title: AppStrings.byTurn.tr(),
              isActive: selectedMode == PlayStationMode.turn,
              onTap: () => onModeChanged(PlayStationMode.turn),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubTab extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _SubTab({
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.stitchSurfaceHigh.withOpacity(0.5)
              : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.primaryColor : AppColors.blackLight,
            ),
          ),
        ),
      ),
    );
  }
}
