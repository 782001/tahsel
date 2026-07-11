import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';

class MetaChip extends StatelessWidget {
  final String label;
  const MetaChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.veryLightGrey,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Text(
        label,
        style: TextStyles.customStyle(
          fontSize: 11,
          color: AppColors.blackLight,
        ),
      ),
    );
  }
}
