import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/customer_debts/data/models/debt_item_model.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/summary_card.dart';

class SummaryRow extends StatelessWidget {
  final CustomerDebtDetail detail;

  const SummaryRow({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            label: AppStrings.totalIncome.tr(),
            amount: detail.totalPaid,
            color: AppColors.primaryColor,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: SummaryCard(
            label: AppStrings.remainingDebt.tr(),
            amount: detail.totalDebt,
            color: AppColors.error,
            icon: Icons.warning_amber_rounded,
          ),
        ),
      ],
    );
  }
}
