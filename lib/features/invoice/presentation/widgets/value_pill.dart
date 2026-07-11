import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';

class ValuePill extends StatelessWidget {
  final String label;
  final bool isOld;
  const ValuePill({super.key, required this.label, required this.isOld});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOld
            ? AppColors.error.withValues(alpha: 0.10)
            : AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyles.customStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isOld ? AppColors.error : AppColors.success,
        ),
      ),
    );
  }
}
