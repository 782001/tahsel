import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

class ExpensesBalance extends StatelessWidget {
  const ExpensesBalance();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.totalMonthlyExpenses.tr(),
            style: TextStyles.customStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.disabledColor,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '١٢,٤٥٠',
                style: TextStyles.customStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textColor,
                  height: 1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
                child: Text(
                  '.٠٠ دولار',
                  style: TextStyles.customStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.disabledColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, color: AppColors.errorText, size: 16),
                const SizedBox(width: 4),
                Text(
                  AppStrings.expenseIncreaseHint.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.errorText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
