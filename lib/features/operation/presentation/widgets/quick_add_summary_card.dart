import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';

class QuickAddSummaryCard extends StatelessWidget {
  final double totalDue;
  final String? label;

  const QuickAddSummaryCard({super.key, required this.totalDue, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border(
          right: BorderSide(color: AppColors.primaryColor, width: 8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label ?? AppStrings.totalDueLabel.tr(),
            style: TextStyle(color: AppColors.blackLight, fontSize: 14),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              '${totalDue.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()}',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
