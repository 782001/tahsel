import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/customer/presentation/widgets/customer_summary_row.dart';

class CustomerSummaryCard extends StatelessWidget {
  final double totalSpent;
  final double totalPaid;
  final double remaining;

  const CustomerSummaryCard({
    super.key,
    required this.totalSpent,
    required this.totalPaid,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withAlpha(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withAlpha(80),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomerSummaryRow(
            label: AppStrings.totalPurchases.tr(),
            value: totalSpent,
            isWhite: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white24),
          ),
          CustomerSummaryRow(
            label: AppStrings.totalPaid.tr(),
            value: totalPaid,
            isWhite: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white24),
          ),
          CustomerSummaryRow(
            label: AppStrings.remainingAmount.tr(),
            value: remaining,
            isWhite: true,
            isBold: true,
          ),
        ],
      ),
    );
  }
}
